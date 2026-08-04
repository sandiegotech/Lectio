# tools/print — the printed edition

Sets any Lectio edition as a print-ready book, straight from `content/`. The bundle is the
only source: text, book titles, the book "arguments" (from `enrichment.json`), provenance,
divergences and the companion editions all come out of the JSON the app reads, so the page
and the reader can never drift apart.

```
brew install typst
python3 tools/print/build_book.py                    # Meditations, Lectio Edition
python3 tools/print/build_book.py --paper parchment  # warm-paper variant, for screens
python3 tools/print/build_book.py --no-cover         # interior block only, no cover leaf
```

Output (PDF + the generated `.typ` beside it) lands in `tools/print/out/`, which is not
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

## Other works

`--work` / `--edition` take any ids in the bundle; `--compare-locus` picks the passage for
the four-ways page (a `referenceScheme` locus, e.g. `5.16` for Meditations, `9.410` for the
Iliad). Verse works are not specially handled yet — segments set as prose paragraphs — so a
poem would want a `kind == "line"` branch in `sec()` first.
