# Project Bible — "Classics" (working title)

> A living reader for the great public-domain books — not just to *store* the classics, but to make them
> explorable, connected, and genuinely inviting. Built for iPad first, with iPhone and Mac to follow.

---

## 1. The Vision in One Paragraph

Most reading apps (Kindle, Apple Books) treat every book as an undifferentiated stream of text. That works
for a beach novel and fails completely for *The Iliad*, *The Divine Comedy*, or *The Brothers Karamazov* —
books that are long, culturally dense, written in unfamiliar registers, and surrounded by 2,000 years of
commentary, art, and influence. **Classics** is a reader designed specifically for those books. It treats each
classic not as a flat file but as a *node in a web*: multiple translations, the art it inspired, the works it
descends from and the works that descend from it, the people and places inside it, and modern aids that make a
daunting text feel navigable instead of intimidating. It ships with curated **collections** (starting with the
Harvard Classics) so a reader has a guided path, not just a search box.

---

## 2. Why Now / Why This Is Possible

- **The texts are free and legal.** Everything pre-~1929 in the US is public domain. Project Gutenberg,
  Standard Ebooks, Wikisource, and the Internet Archive provide clean, redistributable text.
- **The art is largely free too.** Museum open-access programs (The Met, Rijksmuseum, Art Institute of
  Chicago, NGA, Getty) and Wikimedia Commons offer high-res public-domain images keyed to classical subjects.
- **AI changes the economics of two hard problems:** (1) fresh translation of public-domain source texts, and
  (2) generating the *connective tissue* — summaries, character maps, "what just happened" recaps, glossaries,
  and cross-work links — that used to require a team of scholars per book.
- **The hardware fits.** iPad is the ideal device for a visual, spatial, exploratory reader.

---

## 3. The Collections (the "shelves")

A collection is a curated, named set of works with editorial framing. Collections give the app authority and a
sense of journey. Launch and near-term candidates:

### The Harvard Classics ("Dr. Eliot's Five-Foot Shelf of Books")
A 51-volume anthology published by **P.F. Collier & Son in 1909–1910**, edited by **Charles W. Eliot**,
president of Harvard for 40 years. Eliot had repeatedly claimed in speeches that a liberal education could be
had by anyone who spent **15 minutes a day** reading from a shelf of books just **five feet** long. A publisher
called his bluff and asked him to actually assemble it. The result was the Harvard Classics: Plato, Marcus
Aurelius, Augustine's *Confessions*, Dante, Shakespeare, Milton, Bacon, Emerson, Darwin, Dana, the foundational
texts of science, religion, philosophy, drama, and history — plus a famous companion volume, *The Harvard
Classics Reading Guide*, with a **daily 15-minute reading plan** for an entire year. It was a publishing
phenomenon and the original "great books" self-improvement product. **It is fully public domain** and is the
perfect flagship collection: prestigious, complete, and it comes with a built-in daily-reading mechanic we can
turn into a feature.

### Other collections worth building toward
- **Britannica's Great Books of the Western World** (1952, Hutchins/Adler) — 54 volumes, organized around the
  *Syntopicon*, an index of 102 "Great Ideas" cross-referencing every work. The Syntopicon is a *blueprint for
  our connection graph*. (Note: the 1952 editorial apparatus is in copyright; the underlying classic texts are
  not. We can reproduce the *idea* of an idea-index without copying their specific text.)
- **Everyman's Library** (J.M. Dent, 1906–) — aimed at 1,000 volumes of the world's literature for the common
  reader; a model for breadth and affordable accessibility.
- **The Modern Library** — canon-defining 20th-c. American series; good model for "essential canon" curation.
- **Loeb Classical Library** — Greek/Latin with **facing-page original + translation**. Inspiration for our
  side-by-side / interlinear reading mode.
- **Penguin Classics / Oxford World's Classics** — the modern gold standard for scholarly intros, notes, and
  curation. (Their *specific* translations/intros are in copyright — use as a *design* reference, source our
  texts from public-domain editions or AI translation.)
- **Oxford English Dictionary / reference layer** — the OED itself is proprietary, **but** the public-domain
  *Webster's 1913* and *Century Dictionary* give us a rich, free, period-appropriate dictionary to power
  tap-to-define, etymology, and "words that have drifted in meaning since this was written."
- **Thematic house collections we curate ourselves:** "The Stoic Path," "Epics of War & Homecoming,"
  "The Founders' Bookshelf," "Gothic & the Uncanny," "Origins of Science." This is where the product develops
  its own editorial voice and isn't just reproducing 1909 taste.

---

## 4. The Big Ideas (what makes this *not* Kindle)

### 4.1 Multiple translations, side by side
For works in translation (Homer, Dante, Tolstoy, the Bible, Confucius), surface **every public-domain
translation** and let the reader compare. The Iliad alone gives us Chapman (1611), Pope (1715), Cowper,
Buckley, Lang/Leaf/Myers, Butler (1898), and more — each with a wildly different feel (Pope's heroic couplets
vs. Butler's plain prose). Each translation is labeled with translator, year, and a one-line "character"
(e.g. *"stately, rhyming, 18th-century grandeur"* vs *"plain modern prose"*). Reading modes:
- **Single** — pick your translation, read normally.
- **Side-by-side** — two translations in parallel columns, scroll-synced by passage.
- **Interlinear / facing-original** — Loeb-style, original language beside translation (for those who want it).

### 4.2 AI translation as a first-class, labeled option
Offer a **fresh AI translation** of the public-domain source text — clearly badged as *AI-translated* and
**always disclosing the model and the source edition used**. Value: (1) a genuinely *modern, readable* register
for daunting texts, free of copyright; (2) optional "tuned" variants — *Plain Modern English*, *Faithful &
Literal*, *Poetic* — so the reader chooses how much the text is smoothed. This is a key differentiator and the
honest way to give people the "easy modern version" they actually want without pirating a living translator.
**Provenance is a feature, not fine print:** every word the reader sees is attributable to a translator (human,
year) or a model (name, date, prompt profile).

### 4.3 The Connection Graph ("Connect Gloss")
The heart of the product. Every work, person, place, idea, and image is a node; everything is linked:
- **Influence edges** — *The Aeneid* → descends from *The Iliad/Odyssey*; *Ulysses* → descends from *The
  Odyssey*; *Paradise Lost* → draws on Genesis. Walk the lineage forward and backward.
- **Idea edges** — passages tagged with "Great Ideas" (justice, fate, love, the soul) so you can jump between
  every author who wrote on a theme (our free-form answer to the *Syntopicon*).
- **Entity edges** — characters, gods, historical figures, and places, each with a hover/tap card and a list of
  every work they appear in.
- **Visual edges** — artworks depicting the scene you're reading (open-access museum images), shown inline or
  in a "gallery for this chapter."
- **Inspired-by edges** — later art, music, film, and literature that the work spawned.
The graph is browsable as a **map** (zoomable node-link view) and surfaced *contextually* while reading
("3 artworks depict this scene," "this line is echoed in 2 later works").

### 4.4 Making long books feel small
Anti-intimidation toolkit, all optional and toggleable:
- **Chunking & pacing** — books presented as a series of short, finishable "sittings" (the Harvard 15-min/day
  model generalized). Visible, satisfying progress.
- **"Previously / what just happened"** AI recaps at chapter boundaries (spoiler-safe to your current position).
- **Character & place tracker** — a persistent, spoiler-aware cast list ("who is this again?").
- **Difficulty dial** — slide from original text → lightly modernized → plain modern → summary, per passage.
- **Tap-to-define & tap-to-explain** — Webster's 1913 for words; AI for allusions, idioms, and context.
- **Visual margin** — relevant art, maps, and timelines alongside the text instead of a wall of grey.

### 4.5 Themes / "skins"
The same book, re-skinned: a **"natural book"** theme (warm paper, serif, deckled edges, period typography that
feels like a real physical edition) ↔ a **clean modern reader** (high-contrast, sans, generous spacing) ↔
**focus mode** (one paragraph at a time). Themes are presentation only; they never alter provenance.

---

## 5. Sourcing & Rights (the thing that will actually make-or-break this)

| Layer | Source | Rights posture |
|---|---|---|
| Public-domain texts | Project Gutenberg, **Standard Ebooks** (beautifully typeset), Wikisource | Free to redistribute; respect Gutenberg's trademark/attribution terms |
| Translations (historical) | Same as above; one work = many editions | Public domain if translator died long enough ago / pre-1929 US pub |
| Translations (modern, e.g. Fagles, Wilson) | **Do NOT include** | In copyright — substitute public-domain editions or AI translation |
| AI translations | Generated from PD source text | Ours, but **must label model + source edition** |
| Artwork | Met / Rijksmuseum / AIC / NGA / Getty open access, Wikimedia Commons | Public domain or CC0; store the rights statement per image |
| Dictionary/reference | Webster's 1913, Century Dictionary | Public domain |

**Guiding rule:** every piece of content carries a *provenance record*. If we can't say where it came from and
that we're allowed to show it, it doesn't ship.

---

## 6. Platform & Tech (initial stance — revisit before building)

- **Apple-native, multiplatform SwiftUI** target → one codebase for iPad / iPhone / Mac. iPad is the design
  driver; iPhone is a responsive adaptation; Mac comes via the same target.
- **Content pipeline (offline, not in-app):** ingest EPUB/Gutenberg → normalize to a structured format
  (chapters → sections → paragraphs with stable IDs) → store text + metadata + graph edges. Stable paragraph
  IDs are what make scroll-syncing, annotations, art-anchoring, and recaps possible.
- **Local-first reading** with a synced library (iCloud/CloudKit for personal data: progress, highlights,
  notes). Big media (art) streamed/cached.
- **AI features** run server-side or via API, generated and **cached** (translations/recaps are produced once
  per work, reviewed, then served as static content — not generated live per reader, for cost and consistency).
- **The graph** can start as a simple relational/JSON dataset and graduate to a real graph store only if needed.

---

## 7. Naming & Ecosystem

Working title **Classics**. Other candidates: **Athenaeum**, **Folio**, **Vellum**, **Lyceum**, **Marginalia**,
**Palimpsest**, **Five-Foot Shelf**.

**This app is one of several.** Classics is part of a small suite that shares a single, account-level **tuned AI**
("the Philosopher") — the same intelligence powers **Gloss** (the connection/annotation layer) and future
sibling apps. Implication for architecture: the AI capability and the user account/subscription live at the
**ecosystem level**, not inside this app. Classics *consumes* the shared AI service and the shared identity; it
does not own them. The content pipeline's output must therefore be portable enough for sibling apps to read.

---

## 8. Roadmap (phases)

**Phase 0 — Foundation (proof the pipeline)**
Ingest 3–5 books cleanly from Standard Ebooks/Gutenberg into the structured format. Prove paragraph IDs,
chaptering, and a basic SwiftUI reader on iPad. No graph, no AI yet.

**Phase 1 — MVP (see §9).**

**Phase 2 — Connection layer**
Add the graph for a small, hand-curated set: artwork-per-chapter for one epic, influence edges among ~20 works,
entity cards. Contextual "gallery for this scene."

**Phase 3 — Translation comparison**
Side-by-side reading mode; ingest multiple PD translations of 2–3 works (Iliad, Odyssey, Dante).

**Phase 4 — AI layer**
Cached AI translations (with provenance + difficulty variants), recaps, tap-to-explain.

**Phase 5 — Collections & curation at scale**
Harvard Classics complete with the 15-min/day reading-plan mechanic; our own themed collections; reading
streaks/journeys.

---

## 9. The MVP (what we actually build first)

**Goal:** a beautiful, genuinely-better-than-Apple-Books reader for the public-domain canon, with *one*
signature "exploratory" feature to prove the concept — not the whole graph.

**In scope:**
1. **The Harvard Classics as the flagship collection** — browse the 51 volumes / works as curated shelves, with
   Eliot's framing and the 15-minutes-a-day reading plan presented as a guided path.
2. **A first-class reader** on iPad: clean chaptering, stable progress, tap-to-define (Webster's 1913),
   highlights & notes, and **at least two themes** ("natural book" + "clean modern").
3. **~10–15 fully ingested works** with real, clean text (a representative slice of the Harvard Classics).
4. **Signature exploratory feature: translation compare for *The Iliad*** *(DECIDED)* — 2–3 public-domain
   translations side-by-side, each labeled with translator/year/character (Pope's couplets vs. Butler's prose).
   Most viscerally impressive, uniquely ours, lowest media/rights overhead. Art-gallery and AI-version are
   later phases.
5. **Provenance UI** — every text shows its source edition; sets the honest-by-design tone from day one.

**Explicitly out of scope for MVP:** *cloud/paid* AI translation, the bundled Gemma offline pack, the full
connection graph, audio, social/sharing, Android, the complete 51-volume ingestion, sync. Those are later.

**First free-tier fast-follow (not paid):** on-device Apple Foundation Models comprehension aids
(tap-to-explain, recaps, simplify) — free to run, so they belong to the free tier, layered on right after the
core reader ships. Scaffold the capability layer (§10) in the MVP even if on-device AI lands just after.

**MVP success test:** a reader opens *The Iliad*, flips Pope's couplets against Butler's prose in side-by-side
mode, taps an archaic word to define it, switches to the "natural book" theme, and *wants to keep going* — and
a non-reader feels like the book got smaller and friendlier, not bigger.

---

## 10. Business Model *(DECIDED — direction set)*

**V1 strategy: do as much as possible in the FREE tier.** Build out paid/cloud-AI tiers afterward. The goal is
a free version that already feels complete and impressive on its own.

Tiered subscription at the **ecosystem level** (shared with Gloss and siblings), with a generous free entry:

- **Free** — the full reader, the Harvard Classics shelf, all public-domain translations, **translation
  compare**, themes, tap-to-define (Webster's 1913), highlights/notes. **Plus opportunistic on-device AI**
  (see §10.1): on Apple-Intelligence-capable hardware, tap-to-explain / recaps / simplify run locally at
  **zero marginal cost**. Includes **login/account** from the start (even before paid tiers exist) so identity
  is in place to build on.
- **"Student"** — paid tier: full exploratory features at scale (art galleries, expanded compare, the
  connection graph, etc.).
- **"Philosopher" / Intellectual** — top tier: the **cloud custom-tuned AI ("the Philosopher")** — higher-
  fidelity full AI *translations*, cross-app intelligence across **Gloss** and the suite, and works on *any*
  device regardless of local hardware.

**Build-order implication:** ship the free reader + account/login now. Wire AI features as gated calls to a
**capability layer** that resolves to (a) on-device model if available [free], else (b) cloud tuned model
[paid], else (c) feature hidden. Cloud service can be stubbed initially.

### 10.1 On-device AI strategy

The split: **on-device = comprehension aids (free); cloud = generation + cross-app intelligence (paid).**

- **Apple Foundation Models framework** (iOS/iPadOS/macOS 26+) exposes the OS's built-in ~3B on-device LLM to
  developers. **No API cost, offline, private, and zero added app storage** (it's part of the OS). Swift API
  with structured generation + tool calling. Limited to Apple-Intelligence-capable devices (iPhone 15 Pro+,
  M-series iPads, M1+ Macs). Strong enough for **tap-to-explain, define-in-context, chapter recaps, simplify-
  this-paragraph, character reminders** — i.e. the "make long books less daunting" toolkit — but **not**
  frontier-quality literary *translation*. → This powers free-tier AI where hardware allows; degrade gracefully
  elsewhere.
- **Bundled open model (Gemma via MLX/llama.cpp)** — a *later* optional **"offline AI pack"** the user
  downloads to get offline AI *translation* without cloud/subscription. The real constraint is **RAM, not
  storage** (~a 4B model needs ~3–4GB live), so it's realistically an M-series iPad / Mac feature. Adds model-
  management overhead; deliberately **post-MVP**.
- **Cloud tuned "Philosopher"** — the paid path; best quality, consistent across all devices, and the only one
  that can be a *custom-tuned* model shared across Gloss and siblings.

## 11. Open Questions (still to decide)
- How much AI generation is pre-baked & human-reviewed vs. live per-reader?
- Do we ship our own curated collections at launch, or lead entirely with Harvard Classics?
- Original-language support depth (just display, or interlinear/lexical for Greek/Latin)?
- Exact tier boundaries (what's Free vs. Student vs. Philosopher) and pricing.
