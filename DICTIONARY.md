# The Lectio Dictionary — Entry Schema Spec

> A dictionary of *senses across time and language*, not a list of headwords. The
> problem it answers is the project's own thesis: meanings drift. A word rarely
> carries today what it carried when it was written, or even what its Victorian
> translator heard. Webster's 1913 cannot answer that question — it can only
> testify to what a word meant in 1913. So Webster's demotes from **authority**
> to **witness**, and the Lectio Dictionary takes the chair.

Relationship to the rest of the system, in one line each:

- **Lectio (the reader):** the dictionary replaces Webster's as the second step of
  the lookup chain — work-scoped glossary first, Lectio Dictionary second,
  on-device model last.
- **Gloss (project 2):** the dictionary is the data layer; Gloss is the
  instrument that points it at any text, anywhere, in any language.
- **The graph layer:** entries link to Concept nodes via `conceptId`
  (CONTENT_PIPELINE.md §5) — the dictionary is the graph's vocabulary.

The production discipline is unchanged from everything else in this repo:
generated from the full record, human-reviewed before final, provenance on every
entry, served static. Dynamic in coverage, never in generation.

---

## 1. The Entry

Stored under `content/dictionary/`, one JSON array per source language
(`grc.json`, `la.json`, `en.json`, `lzh.json`, `sa.json`, `pli.json`…) — split
further only if size demands, same judgment call as the graph's edge-lists.
JSON is camelCase; `pipeline/model.py` dataclasses are the source of truth and
`app/Lectio/Models.swift` mirrors them, as with every other shape.

```
DictEntry
  id: str                # frozen once published: dict.<lang>.<lemma-slug>
                         #   e.g. dict.grc.hegemonikon · dict.en.wine-dark
  headword: str          # display form: "hēgemonikon"
  script: str?           # native script where non-Latin: "τὸ ἡγεμονικόν"
  transliteration: str?  # reader-friendly: "to hēgemonikon"
  language: str          # ISO 639-3 of the SOURCE term (grc, la, lzh, sa, pli, hbo, en)
  kind: str              # word | phrase | concept | person | place | epithet | custom
  conceptId: str?        # link into content/graph/concepts.json (shared with Gloss)
  senses: [Sense]        # THE CORE — the term's journey through time, ordered
  renderings: [Rendering]# how real editions handled it — evidence, tied to editionIds
  citations: [Citation]  # where it lives in the corpus — stable segment anchors
  related: [str]         # other entry ids
  status: str            # seeded | drafted | reviewed   (the gate applies here too)
  provenance: Provenance # the same record as every edition; nothing ships without one
```

### Sense — one era's meaning

```
Sense
  era: str               # original | historical | modern
  circa: str             # "c. 170 CE" · "1862" · "2026"
  meaning: str           # the sense, in plain modern English
  note: str?             # what shifted since the previous sense, and why it matters
  witnesses: [str]       # named evidence for THIS era's reading — the scholia,
                         # a translator's own usage, Webster's 1913 as the
                         # testimony of its decade, the OED's dated citations
```

The `witnesses` field is where Webster's 1913 lives from now on: not the answer,
but a dated exhibit. Every sense says how we know, not just what we claim.

### Rendering — how translators actually handled it

```
Rendering
  editionId: str         # a real edition in the bundle: edition.meditations.long-1862
  rendering: str         # "the ruling faculty"
  note: str?             # optional: what this choice preserved or lost
```

Renderings are the divergence record generalized: same evidence, keyed to the
term instead of the passage.

### Citation — where the term lives in the corpus

```
Citation
  workId: str
  segmentId: str         # frozen segment id — citations never break
  spine: SpineRange?     # canonical coordinates ("Meditations 2.1"), so the
                         # citation reads the same in every edition, on the
                         # printed page, and later in the recording
```

---

## 2. A complete example

```json
{
  "id": "dict.grc.hegemonikon",
  "headword": "hēgemonikon",
  "script": "τὸ ἡγεμονικόν",
  "transliteration": "to hēgemonikon",
  "language": "grc",
  "kind": "concept",
  "conceptId": "concept.stoic-mind",
  "senses": [
    {
      "era": "original",
      "circa": "c. 170 CE",
      "meaning": "In Stoic psychology, the commanding centre of the self — the rational faculty that judges impressions and directs assent and action.",
      "witnesses": ["Epictetus, Discourses (usage)", "the ancient scholia", "LSJ s.v. ἡγεμονικός"]
    },
    {
      "era": "historical",
      "circa": "1862",
      "meaning": "Rendered literally into faculty-psychology vocabulary: 'the ruling faculty,' 'the governing part.' Accurate, but opaque once faculty psychology itself faded.",
      "note": "Long's readers knew 'faculty' as live scientific vocabulary; today it survives mainly in idiom.",
      "witnesses": ["George Long (1862), tr. Meditations", "Webster's 1913 s.v. faculty"]
    },
    {
      "era": "modern",
      "circa": "2026",
      "meaning": "The mind that governs you; your directing mind.",
      "note": "Lectio renders the function plainly rather than transliterating the philosophy.",
      "witnesses": ["Lectio Edition divergence record, Meditations (2026 vintage)"]
    }
  ],
  "renderings": [
    { "editionId": "edition.meditations.long-1862", "rendering": "the ruling faculty" },
    { "editionId": "edition.meditations.casaubon-1634", "rendering": "that part which is predominant" },
    { "editionId": "edition.meditations.lectio-modern", "rendering": "the mind that governs you" }
  ],
  "citations": [
    { "workId": "work.marcus-aurelius.meditations",
      "segmentId": "edition.meditations.lectio-modern.book-02.seg-0002",
      "spine": { "fromRef": "2.2", "toRef": "2.2" } }
  ],
  "related": ["dict.grc.prohairesis", "dict.grc.logos"],
  "status": "drafted",
  "provenance": {
    "source": "ai",
    "rightsStatus": "cc-by-nc",
    "aiModel": "claude-fable-5",
    "sourcesCited": ["LSJ", "the ancient scholia", "Long 1862", "Casaubon 1634"],
    "vintage": 2026
  }
}
```

---

## 3. Emission — the corpus writes its own dictionary

A new pipeline stage, after enrichment, emits **seed entries** from data the
build already produces. Nobody sits down to write a dictionary; it condenses out
of the work:

1. **From divergences** — every divergence is one term, two-plus renderings, and
   a reasoning note: a seed entry with `renderings` and a modern sense already
   filled in. ~1,100 seeds exist today.
2. **From glossary entries** — every enrichment glossary entry with a
   `conceptId` becomes a seed keyed to the same concept. ~5,800 candidates.
3. **Promotion** — `seeded → drafted` runs the deep-research pass (senses,
   witnesses, related terms, from the full record); `drafted → reviewed` is a
   human read, same gate as an edition. Only `reviewed` entries are final;
   the app may show `drafted` entries with their status visible, exactly like
   the beta editions.

Dedup rule: one entry per (language, lemma). The seed pass merges collisions
across works — *hēgemonikon* in Meditations and Epictetus is one entry with two
citation sets, which is precisely what makes it a dictionary and not a glossary.

## 4. The lookup chain, after

```
tap a word →
  1. work glossary (enrichment.json — curated, work-scoped)
  2. Lectio Dictionary (corpus-scoped, sense-by-era)
  3. on-device model (the Docent) — labeled, never the authority
```

Webster's 1913 leaves the chain and enters the evidence: its definitions become
dated witnesses inside senses. Nothing is discarded; it is re-shelved.

## 5. First concrete tasks

1. `DictEntry`/`Sense`/`Rendering`/`Citation` dataclasses in `pipeline/model.py`,
   mirrored in `Models.swift`.
2. `pipeline/dictionary.py`: the seed emitter over divergences + glossary
   (deterministic ids, dedup by (language, lemma), `status: seeded`).
3. `content/dictionary/` in the publish step, with counts in the manifest.
4. Reader: lookup chain inserts the dictionary between glossary and Docent; the
   entry card shows the sense timeline — original → translator → now.
5. Later, Gloss consumes the same files by `conceptId` — no new format.
