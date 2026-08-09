# print — the printed edition

Sets any Lectio edition as a print-ready book, straight from `content/`. The bundle is the
only source: text, book titles, the book "arguments" (from `enrichment.json`), provenance,
divergences and the companion editions all come out of the JSON the app reads, so the page
and the reader can never drift apart.

```
brew install typst
python3 print/build_book.py                    # Meditations, Lectio Edition
python3 print/build_book.py --paper parchment  # warm-paper variant, for screens
python3 print/build_book.py --no-cover         # interior block only, no cover leaf
```

Output (PDF + the generated `.typ` beside it) lands in `print/out/`, which is not
committed — the book is regenerable from the bundle.

## The book

5.5 × 8.5 in, asymmetric margins (inside 0.86 in), New York at 10.6/0.78 — the app's serif.
Roman prelims with the half title, title, provenance and contents each falling on the leaf a
printed book gives it; the text in arabic from Book I, every book opening on a recto with its
running head suppressed. Section figures and rubrics carry the one rubrication red of "The
Margin"; nothing else is coloured.

Back matter is the translation apparatus: *A Note on This Edition* (character, method,
sources, provenance table, and how the numbering relates to the traditional divisions),
*Where This Edition Differs* (the `divergences` record), *The Same Passage, Four Ways* (one
locus in every edition, matched through the alignment spine — the Compare panel, in print),
*The Other Editions in Lectio*, *Where This Book Leads* (the `explore.json` threads and the
who's-who), and a colophon.

## The cover

`covers/<work-slug>.svg` is used if it exists, else the bundle's `cover.jpg`; `--cover`
(or an overlay's `cover` key) overrides both. The SVG is a real vector cover — frame, type,
disc, ornaments and laurel are drawn geometry, the title is live text, and the engraved
portrait is traced line work — so it stays sharp at any size and can be edited in any vector
tool or a text editor.

```
brew install potrace
python3 print/covers/build_covers.py                 # every recipe
python3 print/covers/build_covers.py iliad           # one
```

**Every cover is the same cover.** `LAYOUT` in `covers/build_covers.py` holds the whole
design — board, double rule frame, author over a rubricated star, title, one motif in a
medallion at the centre, two rails with fleurons down the sides, `A NEW TRANSLATION`, a
laurel, the imprint line — and it is not per-book. A recipe in `BOOKS` carries only what is
genuinely this book's: which motif, how it separates from its ground, how big it sits, and
which of the two series palettes (`WEST`, `EAST`) it belongs to. Titles set on one line, or
two when they are long (`("NICOMACHEAN", "ETHICS")`). `variant()` re-skins a recipe with
different wording — that is how the Spanish sample gets its cover.

**The planned shelves are derived, not authored.** The ten published works get hand-tuned
recipes; the ~200 works you can browse but not yet read cannot — nobody maintains 200
recipes. `covers/build_planned.py` derives one from the master artwork instead: the seam as
the darkest column, the board as the tone of the plain margins, the medallion as the longest
run of rows whose *coverage* is not board colour (edge energy can't tell a line of type from
a picture — both are dense; coverage can), the inks from whether the board is dark. Title and
author come from the collection JSON. Implausible detections fall back to the band the family
always draws the medallion in, and the art is clipped to the medallion, so a generous crop
never shows. Their SVGs are gitignored — 180 MB of intermediate; the committed artifact is
the JPEG the app reads.

**Boards vary, ink does not.** `board(family, sample)` pulls the family paper part of the
way toward the tone of that book's own artwork and derives the vignette and edge from it.
One ink, one rubrication red-brown, one gold across the whole library; only the board
shifts. That is what keeps a shelf of them from looking generated without breaking the set.

The artwork is traced from the existing raster cover. Each recipe lists its **inks**, and
each ink is a mask over the crop:

| kind | what it separates | used by |
| --- | --- | --- |
| `dark` | line work on light paper | Meditations |
| `light` | gold stamped on dark cloth | Gilgamesh |
| `band` | a second ink whose luminance sits between the black and the ground — hue will not separate it, the paper is warm too | the Iliad's terracotta, Confessions' mid-tone hatch |

Inks are drawn in list order, so the mid-tone or second colour goes first and the black line
work lands on top. Each mask is hysteresis-thresholded (a blob survives only if it reaches
the strict threshold, which kills the paper-texture speckle), upsampled 3×, then traced.
`simplify=(turdsize, opttolerance)` trades detail for file size on dense art;
`clip="medallion"` clips the artwork to the disc, which is how a vignette is drawn.

The app still reads `content/works/<id>/cover.jpg` — SwiftUI has no runtime SVG decoder — so
these covers are the print pipeline's, not the library grid's. If the vector cover should
become the app's too, raster it and replace the JPEG (and drop the SVG in the masters folder
as the new master); the bundle keeps shipping JPEG either way.

## Editions that aren't in the bundle

`--overlay <json>` prints an edition the bundle does not carry — a translation experiment, a
draft, a sample. The overlay is merged over the bundle data (dicts deep-merge, lists replace),
so it supplies only what differs:

| key | what it overrides |
| --- | --- |
| `lang` | the chrome language (`STRINGS` in `build_book.py`) and Typst's hyphenation |
| `work` | title, author, era, and an optional `subtitle` printed under the edition line |
| `edition` | the printed edition itself — `sections`, `character`, `overview`, `introduction`, `divergences`, `provenance` |
| `otherEditions` | patches to the companion editions, so their descriptions read in the book's language |
| `enrichment` / `explore` | book arguments, who's-who, epigraph, threads |
| `strings` | any single chrome string |
| `out` / `compareLocus` | output stem and the four-ways passage |

```
python3 print/build_book.py --overlay print/experiments/meditations-es.json
```

`experiments/meditations-es.json` is the worked example: a Spanish sample of Meditations,
Books I–II. Its segments carry the ids and spine coordinates of the English edition, so the
four-ways page resolves the same passage across it and the bundle's editions. Overlays are
not content — nothing here is published to the app, and provenance must say plainly what the
edition is and is not.

## Other works

`--work` / `--edition` take any ids in the bundle; `--compare-locus` picks the passage for
the four-ways page (a `referenceScheme` locus, e.g. `5.16` for Meditations, `9.410` for the
Iliad). Verse works are not specially handled yet — segments set as prose paragraphs — so a
poem would want a `kind == "line"` branch in `sec()` first.
