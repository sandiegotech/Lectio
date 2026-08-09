# The Vernacular Bible — Charter

The standing decisions for every session that touches this corpus — the overnight loop,
a manual session, a reviewer. Read this whole file before translating a verse. The register
standard is the pilot: `print/experiments/the-bible-vernacular-pilot.md` (Genesis 1–3,
Psalm 23, Mark 1). When in doubt, sound like the pilot.

The premise, stated once: this book has always moved by translation — Aramaic teacher,
Koine Gospels, the *Vulgata* ("common version"), Tyndale's plain English, a KJV that was
itself a vernacular project before three centuries made it sound like heaven. The
Vernacular continues the pattern from inside the tradition. That confidence, and nothing
louder than it, is the voice.

## The two commitments

1. **Synthesis, not paraphrase.** Work from the public-domain line (KJV 1611, ASV 1901,
   Young's Literal, JPS 1917) against the original Hebrew (Leningrad) and Greek
   (Westcott-Hort lineage), consulting the modern tradition (Alter, Fox, Hart, Ruden,
   NRSV, REB) as *scholarship on disputed choices, never copied*. The rendering is
   Lectio's own.
2. **The weight stays, and so does the texture.** Genesis is spare and repetitive; Mark is
   rough and breathless; the Psalms are compressed poetry; Paul argues. Do not pour these
   into one continuous churchly voice — that is the KJV-tradition error the Vernacular
   exists to undo. And do not slide into paraphrase: **Eugene Peterson's *The Message* is
   the boundary.** If a rendering starts sounding like Peterson, it has stopped being a
   translation.

## Resolved global decisions (do not re-litigate per book)

| Issue | Ruling | Why |
| --- | --- | --- |
| Divine name (YHWH) | **"the LORD"**, capitals | Honest substitution marker; no invented pronunciation. Small caps in print/app rendering. |
| *euangelion* | **"good news"**, never "gospel" | A herald's word before it became church furniture; what a first hearer heard. |
| *metanoia* | **"turn back" / "turn your lives around"**, never "repent" | The Greek is a turning of mind and life; "repent" carries sawdust-trail baggage. |
| "Son of Man" | **stays "Son of Man"** | A title; titles are load-bearing like proper names. (CEB's "the Human One" is the cautionary tale.) |
| Proper nouns | **Traditional English forms** (Jesus, Moses, Jerusalem, Pharaoh) | Architecture of the text; recognizable names are the reader's handholds. |
| *hesed* | **"kindness"** (in pairs: "goodness and kindness"), noted where load-bearing | The untranslatable covenant-loyalty word; pick the living English and say so in a note. |
| Gen 1:1 | **"When God began to create…"** (dependent clause) | The Hebrew syntax; Rashi's reading; modern consensus. |
| Gen 1:3 | **"Let there be light." untouched** | Exact plain rendering of the Hebrew — knowing what *not* to touch is most of the job. |
| *tsela* (Gen 2) | **"side"**, not "rib", with note | The word means "side" everywhere else; "rib" entered via the Greek. |
| *ezer kenegdo* | **"a partner who matches him"** | *ezer* is used of God; no subordination in the Hebrew. |
| Mark 1:10 | **"torn open"**, never "opened" | Mark's violent verb; Matthew and Luke flinched. Keep Mark rough generally. |
| *euthys* (Mark) | **"right away", every time** | 40+ occurrences; structural, like Homer's epithets. Never vary for elegance. |
| Second person | **"you"**, register held by rhythm not archaism | No thee/thou; formal ≠ archaic. |
| Measurements, coins, hours | Keep biblical units (cubits, denarii, "the third hour") | Modernizing units breaks the world; the reader can carry them. |

## Per-register rules

- **Hebrew narrative** (Genesis, Exodus, Samuel, Kings…): paratactic "And" chains are the
  style — keep more of them than modern prose taste wants. Keep refrains verbatim ("And
  there was evening, and there was morning"; "And God saw that it was good"). Wordplay
  that cannot cross (adam/adamah, arum/arummim) gets one bracketed trans. note, two
  sentences maximum.
- **Hebrew poetry** (Psalms, Job, Proverbs, prophets' oracles, Song): set as verse lines.
  The engine of Hebrew poetry is **parallelism** — the second line answering the first —
  and it survives translation perfectly; protect it above all. No rhyme, no meter
  imposed. Concrete stays concrete (rod, staff, oil, cup — never "comfort" abstractions).
- **Gospel narrative**: Mark rough and fast; Luke smoother (he wrote better Greek — let
  him); John slow, plain, and strange (short words, deep water — do not decorate). Jesus'
  sayings must pass the read-aloud test above all other text: he taught in spoken
  language, and the Vernacular's whole premise stands on those lines sounding speakable.
- **Epistles**: Paul argues — surface the argument's spine with American sentence breaks,
  but never flatten his run-on urgency into bullet-point calm (Romans 8 and 1 Cor 13 are
  rhetoric; keep the build).
- **Apocalyptic** (Daniel, Revelation): the strangeness is the content. Render the images
  exactly; explain nothing.

## Textual honesty (apparatus is provenance)

Manuscripts differ; a Lectio Bible says so. Every affected book carries `divergences`
entries for its famous variants — minimum set:

- **Mark 1:1** "Son of God" absent in some earliest witnesses.
- **Mark 1:41** "moved with compassion" vs "moved with anger."
- **Mark 16:9–20** the longer ending — print it, marked as an early addition the earliest
  manuscripts lack.
- **John 7:53–8:11** the woman caught in adultery — same treatment; it is beloved and it
  is a floater, and honesty can hold both facts.
- **Isaiah 7:14** *almah*: "young woman" (Hebrew) vs "virgin" (Greek Septuagint, quoted by
  Matthew) — render the Hebrew in Isaiah, the Greek in Matthew, and note the seam. This is
  the most consequential translation decision in the book's history; the note earns its place.
- **1 John 5:7–8** the Trinitarian gloss (Comma Johanneum) — omit, note.

Never silently harmonize parallel passages (Matthew's and Luke's Lord's Prayers differ;
so do the Beatitudes; so do the resurrection accounts). The differences are data.

## App-facing storage (same as every Lectio edition)

- **`divergences`** in the edition JSON — global rulings that show in the work (the LORD,
  good news, turn back…) plus that book's textual variants and famous cruxes. This is what
  the reader sees in "Where This Edition Differs."
- **`provenance`** — the Method & Rights formula from the pilot, model recorded, sources
  cited, `aiProfile: "vernacular_bible"`.
- **`character` / `overview` / `introduction`** — per book, in SDIT voice, plain about what
  this edition is and is not.
- **`enrichment.json`** — chapter notes (the "arguments") and the who's-who; the Bible is
  the who's-who feature's best case.

## QA gates, in order

1. `integrate.py` validation (existing loop gate).
2. **Verse coverage**: every verse of the base edition must fall inside some segment's
   spine range — no dropped verses, ever. (Bible-specific check; see PLAN.)
3. **Read-aloud pass** on all direct speech.
4. **Peterson boundary** temperature check on a sample.
5. **Human review** — Brandon reads the whole book before `defaultEditionId` flips to the
   Vernacular. Until then KJV stays default. Drafts are drafts; honesty is the product.
