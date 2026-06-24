# Content Pipeline Spec — Lectio

> How raw public-domain books become structured, provenance-tracked, multi-translation content that the iPad
> reader (and sibling apps like Gloss) can consume. This is the foundation everything else depends on.

Status: **design**. Companion to [BIBLE.md](BIBLE.md). Scoped to deliver the MVP (§9 of the bible): a clean
reader + **translation-compare for *The Iliad***.

---

## 0. Principles

1. **The pipeline is offline, not in-app.** Books are ingested, cleaned, structured, and reviewed *ahead of
   time* by a build tool. The app ships (or downloads) finished, static content bundles. Nothing parses raw
   EPUB on-device.
2. **Stable IDs are sacred.** Every paragraph/segment gets an ID that never changes once published. Highlights,
   notes, art anchors, recaps, and cross-translation alignment all reference these IDs. If IDs churn, user data
   breaks.
3. **Provenance travels with content.** Every text segment knows its source edition; every AI-or-art asset
   knows its origin and rights. No orphan content.
4. **Output is portable.** The published format is plain, versioned JSON (+ media), readable by Lectio *and*
   Gloss *and* future siblings. It is not coupled to SwiftUI or any single app.
5. **Human-in-the-loop gate.** Auto-cleaning gets us 90%; a review step catches the rest before publish. A book
   is not "published" until it passes review.

---

## 1. Sources (in priority order)

| Priority | Source | Why | Notes |
|---|---|---|---|
| 1 | **Standard Ebooks** | Hand-typeset, semantic HTML, consistent structure, CC0/PD | Best signal-to-noise; use whenever the title exists there |
| 2 | **Project Gutenberg** | Vast catalog | Messier formatting; respect trademark/attribution; prefer the HTML edition over plain text |
| 3 | **Wikisource** | Good for specific translations & versioned texts | Structured but uneven; great for finding *particular* translations |
| 4 | **Internet Archive** | Scans/OCR when nothing else has it | Last resort; OCR needs heavy cleanup |

**For the Iliad MVP specifically**, target these public-domain translations (verify availability per source):
- **Pope** (1715–20) — heroic couplets, grand. *(verse)*
- **Butler** (1898) — plain modern prose. *(prose)*
- **Lang, Leaf & Myers** (1883) — archaic "biblical" prose. *(prose)* — optional 3rd.

These three give a strong stylistic spread for the compare feature (couplet ↔ plain prose ↔ archaic prose).

---

## 2. The Canonical Data Model

Five core entity types. (Graph nodes in §5 layer on top later; the reader needs only these for MVP.)

### 2.1 `Work` — the abstract work, independent of any edition
```
Work {
  id:            "work.homer.iliad"          // stable, human-readable slug
  title:         "The Iliad"
  author:        "Homer"                      // or authorId -> Person node later
  originalLang:  "grc"                         // ISO 639; ancient Greek
  composed:      "c. 8th century BCE"
  type:          "epic_poem"
  referenceScheme: "book.line"                // see §4 — the alignment spine
  collections:   ["collection.harvard-classics", "collection.epics-of-war"]
  defaultEditionId: "edition.iliad.butler-1898"
  blurb:         "..."                         // editorial framing
}
```

### 2.2 `Edition` — one concrete version (a specific translation OR original-language text)
```
Edition {
  id:            "edition.iliad.pope-1720"
  workId:        "work.homer.iliad"
  kind:          "translation" | "original" | "ai_translation"
  language:      "en"
  translator:    "Alexander Pope"             // null for original-language editions
  translatorYears: "1688–1744"
  publishedYear: 1720
  form:          "verse" | "prose"
  character:     "Stately heroic couplets; 18th-c. grandeur."   // the one-line "feel"
  provenance:    Provenance                    // §3 — REQUIRED
  structure:     [SectionId, ...]              // ordered chapters/books
}
```

### 2.3 `Section` — a chapter / book / canto
```
Section {
  id:        "edition.iliad.pope-1720.book-01"
  editionId: "edition.iliad.pope-1720"
  order:     1
  label:     "Book I"
  title:     "The Contention of Achilles and Agamemnon"   // if the edition gives one
  segments:  [SegmentId, ...]                  // ordered
}
```

### 2.4 `Segment` — the atomic readable unit (a paragraph, or a stanza/line-group)
**This is the unit everything anchors to.**
```
Segment {
  id:        "edition.iliad.pope-1720.book-01.seg-0007"   // stable forever once published
  sectionId: "edition.iliad.pope-1720.book-01"
  order:     7
  kind:      "paragraph" | "verse_block" | "heading" | "epigraph"
  text:      "Achilles' wrath, to Greece the direful spring\nOf woes unnumber'd..."  // may contain line breaks for verse
  spine:     { from: "1.1", to: "1.7" }        // §4 — maps this segment onto the work's reference scheme
}
```

### 2.5 `Collection` — a curated shelf
```
Collection {
  id:        "collection.harvard-classics"
  title:     "The Harvard Classics"
  curator:   "Charles W. Eliot (1909)"
  blurb:     "Dr. Eliot's Five-Foot Shelf..."
  items:     [ { workId, volume, note }, ... ]
  readingPlan: [ { day: 73, workId, sectionId, minutes: 15 }, ... ]   // optional; Harvard's 15-min/day path
}
```

---

## 3. Provenance Record (required on every Edition and every media asset)

```
Provenance {
  source:        "standard_ebooks" | "gutenberg" | "wikisource" | "archive_org" | "ai" | "museum"
  sourceUrl:     "https://..."
  sourceId:      "gutenberg/6130"
  rightsStatus:  "public_domain" | "cc0" | "cc-by" | ...
  rightsNote:    "US public domain; pre-1929 publication."
  retrievedDate: "2026-06-15"
  // AI editions add:
  aiModel:       "claude-opus-4-8"
  aiSourceEditionId: "edition.iliad.butler-1898"   // what it was translated FROM
  aiProfile:     "plain_modern" | "faithful" | "poetic"
  // Museum images add:
  creator:, dateCreated:, holdingInstitution:, accessionNumber:
}
```

If a piece of content can't produce a valid Provenance record, **it does not publish**.

---

## 4. The Alignment Spine (how side-by-side scroll-sync works)

The MVP signature feature — reading Pope next to Butler, scroll-synced — requires a shared coordinate system,
because a verse translation and a prose translation have *no* paragraph-to-paragraph correspondence.

**Solution: every Work has a canonical `referenceScheme`, and every Segment declares the `spine` range it
covers.** For Homer the scholarly-standard scheme is **`book.line`** (e.g., `1.1` = Book 1, line 1 of the
canonical Greek). Then:

- Each translation's segments are tagged with the spine range they cover (`{from:"1.1", to:"1.7"}`).
- Many PD editions print **marginal line numbers** keyed to the Greek — the cleanest anchor source; capture
  them during ingestion.
- Where margins are absent (e.g., Butler's prose), align at the **Book** level automatically, then refine to
  passage level with an assisted pass (heuristics + AI-suggested alignment, human-confirmed).
- The reader scroll-syncs by **finding the other edition's segment(s) whose spine range overlaps** the one
  currently centered. Imperfect alignment degrades gracefully to Book-level sync — never breaks.

The spine is also what later lets **art, recaps, and Gloss annotations** attach to "Iliad 1.1–1.7" *regardless
of translation* — anchor once, surface in every edition.

---

## 5. The Graph Layer (Phase 2+, but reserve the schema now)

Nodes: `Work`, `Person` (author/character/historical figure), `Place`, `Idea`, `Artwork`, `Event`.
Edges (typed, directional): `influenced_by`, `depicts`, `appears_in`, `about_idea`, `descends_from`,
`translated_by`, `inspired`. Each edge can carry a `spine` anchor so it attaches to a *passage*, not just a
whole work. Store as JSON edge-lists now; graduate to a real graph DB only if query needs demand it.

---

## 6. Pipeline Stages

```
[1 FETCH] → [2 PARSE] → [3 NORMALIZE] → [4 SEGMENT+ID] → [5 ALIGN] → [6 ENRICH] → [7 REVIEW] → [8 PUBLISH]
```

1. **Fetch** — pull source (Standard Ebooks repo / Gutenberg HTML / Wikisource API). Record source metadata.
2. **Parse** — source-specific adapter → a common intermediate DOM. (One adapter per source type.)
3. **Normalize** — strip boilerplate (Gutenberg license headers, nav), unify quotes/dashes/whitespace, detect
   chapter/book boundaries, preserve verse line breaks. Output: clean intermediate tree.
4. **Segment + assign IDs** — split into Segments, assign stable IDs (`work.edition.section.seg-NNNN`).
   **IDs are content-addressed at first publish and then frozen** in an ID-ledger file so re-running the
   pipeline never renumbers an already-published book.
5. **Align** — attach `spine` ranges (capture marginal line numbers; AI-assisted alignment where absent).
   Only for works that will be compared; skippable otherwise.
6. **Enrich** *(later phases)* — tap-to-define index (Webster's 1913), AI recaps, art anchoring, graph edges.
   All cached, all provenance-stamped.
7. **Review** — human gate. A small internal review UI shows the structured result; reviewer approves or flags.
   Nothing publishes unapproved.
8. **Publish** — emit the portable bundle (§7), bump the content version, sign the manifest.

The pipeline is **idempotent and incremental**: re-running on an unchanged source is a no-op; IDs are stable
across runs via the ledger.

---

## 7. Published Output Format (what the app actually consumes)

Portable, versioned, plain files — no app coupling. One directory per work:

```
/content
  manifest.json                     // catalog: works, editions, versions, checksums
  /collections
    harvard-classics.json
  /works
    /homer.iliad
      work.json                     // the Work record
      /editions
        pope-1720.json              // Edition + all Sections + Segments, inline
        butler-1898.json
        lang-leaf-myers-1883.json
      spine.json                    // canonical reference scheme + cross-edition alignment map
      /media                        // (later) art, with per-asset provenance
  /graph                            // (later) the cross-work concept layer / connection graph
    nodes.json                      // shared concept nodes (people, ideas, terms) w/ original-lang lemma + sense history
    edges.json
```

> **Tap-to-define has no bundled dictionary.** Tier 1 is the curated, in-context glossary in each work's
> `enrichment.json` (→ promoted to the shared concept `/graph` nodes above). Tier 2 is **Apple's on-device
> reference dictionary** (`SystemDictionary`) — free, modern, zero bundle weight — for arbitrary words.
> Tier 3 hands off to the sibling app **Gloss**. Webster's 1913 is no longer shipped; it survives only as an
> offline *authoring source* for the concept layer's sense-history field.

- **Format:** JSON now (human-diffable, simple). Can compile to a binary/SQLite read-store later for perf
  without changing the schema.
- **Delivery:** bundled with the app for the MVP's ~10–15 works; later, downloadable per-work/per-collection
  with the manifest driving updates.
- **Versioning:** `manifest.json` carries a content schema version + per-work content versions + checksums so
  the app can detect and fetch updates, and so sibling apps pin to a known schema.

---

## 8. Tooling (the build tool itself)

- A standalone CLI (language TBD — **Python** is the pragmatic pick for HTML parsing + scripting + AI calls;
  it does not need to match the app's Swift). Lives in `/pipeline`.
- Commands (sketch): `fetch <source> <id>`, `build <work>`, `align <work>`, `review <work>`, `publish`.
- Deterministic and re-runnable; the ID-ledger and content-version live in the repo so builds are reproducible.
- AI-assisted steps (alignment refinement, later recaps/translation) call the **shared ecosystem AI service**,
  not a bespoke integration — same service the Philosopher tier uses at runtime.

---

## 9. MVP Cut of This Pipeline (what to actually build first)

To ship the bible's MVP, build only:
1. **Standard Ebooks + Gutenberg adapters** (stages 1–4) — enough to ingest ~10–15 works cleanly with stable
   IDs and two themes' worth of clean structure.
2. **The Iliad alignment** (stage 5) for **2–3 translations** with `spine` ranges — the data behind
   translation-compare.
3. **The curated glossary** per work (in `enrichment.json`) for tap-to-define — generic words fall through to
   Apple's on-device dictionary, so no dictionary is bundled.
4. **A minimal review step** (even just a generated HTML preview a human eyeballs before publish).
5. **The published JSON bundle format** (§7) finalized — because the app is built against it.

Defer: graph, art, AI enrichment, downloadable delivery, binary read-store. Those are Phases 2–5.

---

## 10. First Concrete Tasks
1. Lock the JSON schemas in §2–§3 as actual files (`/schema/*.schema.json`) — the contract the app builds on.
2. Write the **Standard Ebooks adapter** and ingest one work end-to-end (suggest *Meditations* or *The
   Odyssey* — single-edition, simple) to prove stages 1–4 and the output format.
3. Ingest **Iliad ×2 translations** and hand-build the `spine.json` for **Book I** only, to prove alignment +
   side-by-side before scaling.
4. Ingest **Webster's 1913** into the dictionary file.
5. Then start the SwiftUI reader against the published bundle.
