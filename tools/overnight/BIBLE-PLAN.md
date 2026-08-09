# The Vernacular Bible — Plan

Companion to `BIBLE-CHARTER.md` (the decisions). This file is the shape of the work: how
the corpus maps onto Lectio's model, what gets built in what order, and how each phase is
judged done. The register standard is the pilot in
`print/experiments/the-bible-vernacular-pilot.md`.

## 1. Structure — how the Bible fits the bundle

**One Lectio work per biblical book, not one giant work.** The Bible is a library of 66
books (~783,000 words — forty Meditations); a single work with 1,189 chapters would be
unreadable in the UI and unshippable incrementally. Per-book works publish one at a time,
flip their default edition one at a time, and appear on multiple shelves — which the
collections system already supports.

- **IDs / titles / authorship** (honesty rule — traditional attributions are labels, not
  claims): `work.bible.mark` "The Gospel of Mark", author "Anonymous · attributed to
  Mark"; `work.bible.genesis` "Genesis", author "Anonymous · Ancient Israel";
  `work.bible.psalms` "The Psalms", author "Traditional · David and others". Same pattern
  as Gilgamesh ("Anonymous · Sumer & Akkad").
- **Reference scheme: `chapter.verse`** — the one corpus on earth with exact canonical
  coordinates already attached to every sentence. The spine needs **no proportional
  allocation**: segments are prose paragraphs (or poetry strophes) carrying exact verse
  ranges (`{"from":"1.9","to":"1.11"}`). This makes Compare across KJV / ASV / Vernacular
  / original the best-aligned in the whole library, and it is the anchor audio marks will
  use later.
- **Editions per work** (the Meditations pattern — modern + two historical + original):
  1. `lectio-vernacular` — the edition this plan exists to produce (default after review)
  2. `kjv-1611` — the monument (default until then)
  3. `asv-1901` — the literal scholarly control
  4. `original` — Hebrew (Westminster Leningrad Codex) or Greek (Westcott-Hort)
- **Collections**: NT books → `collection.christianity`; Hebrew Bible books → **both**
  `collection.judaism` (the Tanakh shelf) and `collection.christianity` — the same work on
  two shelves is a feature, and the Religious Texts group already exists. Genre feed:
  `Religion`. Shells already waiting: Genesis, The Tanakh, The Holy Bible placeholders.
- **Sections** = chapters (Psalms: one psalm = one section, 150 sections).

## 2. Sources (all public domain, machine-readable)

| Text | Source | Notes |
| --- | --- | --- |
| KJV 1611 | Project Gutenberg #10 | verse-per-line with `Book C:V` markers |
| ASV 1901 | Project Gutenberg #8 | same shape |
| Hebrew (WLC) | tanach.us / Sefaria export | Leningrad Codex, public domain |
| Greek (Westcott-Hort) | Gutenberg / CCEL | public domain; SBLGNT (CC-BY) as cross-check |

**New pipeline piece: a `bible` adapter** (`pipeline/adapters/`) that parses verse-marked
text into sections=chapters, segments=verses (source editions keep verse-per-segment;
only the Vernacular uses paragraph segments with verse-range spines). One adapter serves
all 66 books × all source editions. Recipes stay thin, one per work, appended to
`RECIPES` as books enter the queue.

## 3. Phases

**Phase 0 — Plumbing (one session).** The `bible` adapter; recipes for Mark's four
editions; `chapter.verse` spine support verified (should be free — the scheme is exact);
the verse-coverage QA check (`tools/overnight/bible_check.py`: every base verse falls in
some Vernacular spine range); charter + plan committed.

**Phase 1 — Register standard. DONE.** The pilot (Genesis 1–3, Psalm 23, Mark 1) is the
voice every later session matches, exactly as `pipeline/modern/<slug>.json` sections are
the voice-match source for other works.

**Phase 2 — Mark, end to end (~15k words, 16 chapters; ≈1–2 loop nights).** The proving
run for the whole machine: ingest → overnight loop with charter rules → apparatus entries
(1:1, 1:41, 16:9–20) → enrichment (chapter notes, who's-who) → Brandon reads the book →
default flips → print edition builds → real cover recipe replaces nothing (Mark is new).
**Nothing else starts until Mark ships**, because every lesson is cheapest here.

**Phase 3 — The Hebrew registers (≈5–7 loop nights).** Genesis (38k, 50 ch) proves long
Hebrew narrative at scale; The Psalms (43k, 150 psalms) proves poetry — and forces the
known print-pipeline gap (verse works need the `kind=="line"` branch in `sec()`), which
Psalms is the right occasion to close.

**Phase 4 — The corpus, in reading-value order (months of loop nights, ~30–45 total).**
Gospels + Acts (John → Matthew → Luke → Acts, ~91k); then Exodus + the rest of Torah
(~119k); wisdom (Job, Proverbs, Ecclesiastes, Song, ~46k); the prophets (Isaiah first,
~146k); epistles + Revelation (~90k); histories last (~183k). Queue order lives in
`next.py` `PRIORITY` and can be re-cut at any phase boundary; the loop's resumability
means the ordering is cheap to change and nothing is ever lost.

## 4. Loop mechanics (deltas from RUNBOOK.md — everything else unchanged)

1. `next.py` PRIORITY gains `("work.bible.mark", "bible-mark", "kjv-1611")` at Phase 2 —
   one book at a time, never the whole canon queued at once.
2. Each subagent reads **BIBLE-CHARTER.md** in addition to the standard method — the
   resolved-decisions table is not re-arguable per session.
3. Output paragraphs carry verse-range spines; `bible_check.py` runs before
   `pipeline.build` in the iteration loop (QA gate 2).
4. Branch discipline as ever: a dedicated branch (`overnight-bible`), never main; drafts
   are drafts until human review.

## 5. What Brandon decides / reviews

- **Approve this plan** (structure, order, editions) — the begin signal.
- **Read each finished book** before its default flips — the only gate that matters.
- **Phase-boundary re-cuts** of the Phase 4 order, if reading value suggests it.
- Cover art per published book, when it graduates from placeholder to recipe.

## 6. Downstream (already paid for)

- **Print**: `print/build_book.py` works for prose books immediately; Psalms waits on the
  verse branch (Phase 3). The four-ways compare page will be the best in the catalog —
  exact verse alignment.
- **Audio**: the manifests anchor timestamps to segment ids; verse-range spines mean a
  listener's place cites chapter-and-verse. The Bible is the corpus this design was for.
- **Covers**: placeholder shells exist now; each published book gets a recipe in
  `covers/build_covers.py` like every other work.

## 7. Estimates, honestly

| Unit | Size | Loop cost |
| --- | --- | --- |
| Mark | 15k words, 16 ch | 1–2 nights |
| Genesis | 38k, 50 ch | 2–3 nights |
| Psalms | 43k, 150 psalms | 3–4 nights |
| New Testament | ~181k, 260 ch | ~8–10 nights |
| Full canon | ~783k, 1,189 ch | ~30–45 nights, spread over months |

These are loop-nights, not calendar promises; the queue recomputes from committed state,
so pauses cost nothing. The honest framing for the product: **books ship one at a time**,
each complete, reviewed, and provenance-stamped — the corpus grows the way the library
already grows.
