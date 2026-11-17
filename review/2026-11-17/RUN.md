# Review run 2026-11-17

First full review of every drafted Lectio edition, then a second pass that re-checked each
finding and wrote the confirmed fixes as patches. Nothing has been applied.

- Started 1:05 AM Pacific at 42% of the all-models week and 82% of the Fable week.
- Readers: Opus, up to twenty at once. 24 review assignments, 19 verify assignments.
- Method: `review/METHOD.md`. Every patch dry-runs clean (`tools/review/apply.py <slug> --dry`).

| Work | Sections | A | B | Fixes: high | medium | low | Needs the editor |
|---|---|---|---|---|---|---|---|
| meditations | 12 | 0 | 12 | 8 | 45 | 102 |  |
| iliad | 24 | 4 | 20 | 5 | 44 | 114 | yes |
| odyssey | 24 | 5 | 19 | 2 | 31 | 250 | yes |
| republic | 10 | 1 | 9 | 28 | 75 | 76 |  |
| aeneid | 12 | 0 | 12 | 8 | 62 | 74 |  |
| the-prince | 26 | 20 | 6 | 0 | 15 | 28 |  |
| analects | 20 | 14 | 6 | 0 | 15 | 150 |  |
| tao-te-ching | 81 | 65 | 16 | 4 | 26 | 30 | yes |
| dhammapada | 26 | 6 | 20 | 3 | 31 | 49 | yes |
| bhagavad-gita | 18 | 8 | 10 | 3 | 24 | 49 |  |
| gilgamesh | 11 | 0 | 11 | 2 | 23 | 48 | yes |
| nicomachean-ethics | 10 | 0 | 10 | 38 | 112 | 56 | yes |
| confessions | 13 | 2 | 11 | 1 | 18 | 55 |  |
| divine-comedy | 100 | 55 | 45 | 2 | 134 | 171 | yes |
| hamlet | 5 | 0 | 5 | 9 | 67 | 71 |  |
| bible-mark | 16 | 3 | 13 | 0 | 27 | 8 |  |
| bible-genesis | 34 | 29 | 5 | 0 | 3 | 12 | yes |
| **Total** | **442** | **212** | **230** | **113** | **752** | **1343** | |

High in the fixes column counts patch entries, which is more than the errors found: one decision
(a single English word for a key term) becomes many entries.

For each work, read `rejected*.md` first: it states the policies the patch follows and lists
what could not be patched and needs the editor. Then `patch*.json`.

## What could not be patched

- Segments that are wholly editorial or invented (Iliad V, X, XXIII; Odyssey V, XIV; Gilgamesh VIII;
  Purgatorio XXVI). Ids are frozen, so they need a segment kind the reader, print and audio skip.
- Cantos where the closing line needs its own segment (Inferno XI, XXXIII; Paradiso XVII) and
  Purgatorio XXII, where realigning means renumbering 41 tercets.
- Passages to restore at length (Iliad I, Achilles' retelling; several in Gilgamesh).
- Divergence notes that quote wording a patch changes. `apply.py` edits section text only.
- Mechanical normalizations stated as policy: quote style, dash spacing, contractions, a few spellings.
- Line breaks inside prose paragraphs (quoted verse; the poems in Genesis) are flattened by the build.
- Müller's Dhammapada in the bundle merges verses 127 and 128; fix the recipe.

## Later the same night

- The editor said "apply all". Every patch was applied (2,208 entries), each work had a
  finishing pass (mechanical policies, edition notes brought into line), nine editorial
  segments were marked `omit`, and every Lectio edition was stamped revised 2026-11-17.
  Bundle rebuilt; every segment id unchanged; no public-domain edition altered.
- Genesis 35–50 drafted, reviewed (15 A, 1 B fixed) and integrated: Genesis is complete.
- Three new books drafted from the original with a style sheet first, then read and corrected
  by a second reader, in `drafts/`: The Art of War (0 high, 3 medium, 8 low), Apology, Crito
  & Phaedo (1 high, 10 medium, 45 low), The Golden Sayings (0 high, 11 medium, 18 low).
  They still need ingest. Each `drafts/<slug>/review/APPLIED*.md` lists the editor's rulings.
- Usage: 42% → about 57% of the all-models week; the Fable week 82% → about 96%.
