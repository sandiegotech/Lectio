---
name: print-book
description: Set a Lectio edition as a print-ready PDF book. Use when asked to make a PDF, a print edition, a physical/printable book, or a proof of any work in content/ — and when fixing or restyling one that already exists. Trigger on "make a PDF", "print edition", "print-ready", "typeset", "book PDF", "proof <title>".
---

# Set a Lectio edition in print

One generator does the whole book: `print/build_book.py` reads `content/` and writes a
Typst source plus the PDF. It is the template — there is no per-book layout file, and no
prose about a book is typed by hand. Everything on the page (text, book titles, arguments,
provenance, divergences, threads) comes out of the bundle, so the printed page and the reader
cannot drift apart. `print/README.md` describes the design; read it before changing it.

## 1. Build

```
python3 print/build_book.py --work <workId> --edition <editionId> --compare-locus <locus>
```

Defaults are Meditations / the Lectio Edition / `5.16`. Both the PDF and the generated `.typ`
land in `print/out/` (gitignored — the book regenerates from the bundle). Useful flags:
`--paper parchment` (warm-paper screen variant), `--no-cover` (interior block only, for a
printer), `--width/--height/--inside/--size/--leading` (trim and type), `--font`.

Requires `typst` (`brew install typst`). If a font is missing, `typst fonts | grep -i <name>`.

## 2. Pick the per-book inputs first

- **`--compare-locus`** must be a real locus in the work's `referenceScheme` (Meditations
  `book.section` → `5.16`; Homer `book.line` → `9.410`). It drives the *Same Passage, Four
  Ways* page, which resolves the passage in every edition through the alignment spine. Check
  it lands on something worth quoting before shipping.
- **Section numbering.** The generator numbers sections sequentially per section-of-the-work,
  *not* by `spine.from` — the spine's proportional allocation clamps, so the last several
  segments of most books share one number and would print as repeated figures. The back
  matter says so plainly. Do not "fix" this by switching to spine values.
- **Verse works are not handled yet.** `sec()` sets every segment as a prose paragraph. Before
  printing the Iliad, Dante or Shakespeare, add a `kind == "line"` branch that sets lines
  ragged with hanging indents and prints the line number in the margin.
- A missing `enrichment.json` chapter note or `explore.json` record just drops that block;
  nothing errors.

## 2b. Translations and other editions the bundle doesn't have

Never write an experimental edition into `content/` — the bundle is published, id-ledgered
and read by the app. Use `--overlay <json>` instead (see `print/README.md` for the key
table); `print/experiments/meditations-es.json` is the worked example.

- Give the overlay's segments the **ids and spine coordinates of the edition it renders from**,
  so the four-ways page still resolves the same passage across every edition.
- Set `lang`, and check `STRINGS` in `build_book.py` has that language — every word of chrome
  (Book, Contents, running heads, the whole back matter) comes from there. Adding a language
  means adding a block to `STRINGS`, not sprinkling strings through the code.
- Patch `otherEditions` so the companion editions describe themselves in the book's language;
  their body text stays in their own, which is the honest thing.
- **Provenance is not optional here and it is not decorative.** Say what the edition was made
  from, by what model, how much of the work it covers, that it has not been through editorial
  review, and that it is not part of the app's published corpus. A sample that hides its
  status is worse than no sample.
- A partial edition (Books I–II of XII) belongs in the `work.subtitle`, the introduction and
  the colophon — all three, so no page of it can be mistaken for the whole book.

## 2c. The cover

Resolution order: `--cover` (or an overlay's `cover`) → `print/covers/<work-slug>.svg`
→ the bundle's `cover.jpg`. Prefer vector: a raster cover on the first page of an otherwise
vector book is the one thing that goes soft when someone zooms or prints large.

`covers/build_covers.py` makes them, and **a cover is a recipe** in its `COVERS` table —
palette, frame, type positions, ornaments, where the motif sits — never new drawing code.
Needs `brew install potrace`. Read `print/README.md` for the ink kinds before adding
one; the short version:

- **Do not invent a layout.** `LAYOUT` is the whole design and every book shares it; a recipe
  says which motif, how it separates, how big, and which series palette. If a cover needs a
  different layout, the answer is almost always that its artwork is placed wrong.
- Match the book to a series palette (`WEST` or `EAST`), then give it its own board with
  `board(family, sample)` — the family paper pulled toward the tone of that book's artwork.
  Ink, rubrication and gold stay constant across the library; only the board shifts.
- Pick ink masks by what actually separates the artwork from its ground — `dark`, `light`
  (gold on cloth), or `band` (a second ink between the black and warm paper; hue will *not*
  separate it). List the mid-tone or second colour first so black line work prints on top.
- **Crop to the motif only.** The raster covers have their own type baked in; a loose crop
  traces it and you get a ghost of the title under your live text.
- **Do not clip the motif to the medallion, and do not use a mid-tone ink on a light board.**
  Both make a cover read as a circle-cropped photo rather than an engraving. The motif sits
  *over* the disc and is free to break its edge, the way the Meditations bust does. A dense
  tonal scene still reduces to one ink — tighten it (`dark(core≈50, ext≈85)`) so only the
  lines print and the board shows through the tone.
- Check placement against the original: the raster covers include the spine, so the front
  board is a different aspect than the 5.5 × 8.5 page. `place` is in cover units, by eye.
- **Trace `print/covers/source/<workId>.jpg`, never `content/.../cover.jpg`.** The bundle's
  cover is generated *from* these SVGs (`export_app_covers.py`); tracing it feeds the
  pipeline its own output and the artwork quietly degrades each pass.

The app reads `cover.jpg` from the bundle and has no runtime SVG decoder, so after changing a
cover run `print/covers/export_app_covers.py` to refresh the app copy.

## 3. Verify by looking at the pages

Never ship a PDF you have not looked at. Render and read a spread of pages:

```
typst compile --root . --format png --ppi 100 --pages 3,5,7,9,13,45 print/out/<stem>.typ /tmp/p{p}.png
```

Then Read the PNGs (or tile them into a contact sheet with PIL). Check, in order:

1. **Prelims fall on the right leaves** — half title, title, contents, introduction and the
   epigraph each on a recto; blanks between them are correct, not accidents.
2. **Every book opens on a recto**, with the running head suppressed on that page.
3. **Running heads** — verso the work, recto the book (or the back-matter section, never a
   stale book title once the back matter starts).
4. **Contents** fits one page and its folios match the pages they point at (roman for the
   introduction, arabic for the books).
5. **No orphan pages** — a lone caption or one line stranded on an otherwise empty page.
6. **Text pages** — even color, no rivers, hyphenation sane, section figures in red.
7. **Back matter** reads as apparatus: note, divergences, four-ways, other editions, threads,
   colophon.

## 4. Fold fixes back into the template

Any correction goes into `print/build_book.py`, never into the generated `.typ` (it is
overwritten on every build). Rebuild and re-verify after each change. If a fix changes the
*workflow* — a new flag, a new front/back-matter block, a new gotcha found the hard way — add
it to this skill and to `print/README.md` in the same pass, so the next book is one
command.

## Traps already paid for

- **Bundle text is data, not markup.** Body segments go through `tqs()` (Typst string
  literals); anything interpolated into markup goes through `mk()`, which escapes Typst
  specials, turns a leading `16.` into a literal rather than a list item, and converts the
  Gutenberg `_italics_` that survive in the historical translations into real italics.
- **Labels inside a heading body get re-emitted by the running head** (`label occurs multiple
  times`). Use `= I <book-1>` on the heading line and `#metadata(none) <tag>` for matter
  anchors.
- **Blank leaves inherit the running head.** `#rh.update(none)` before every
  `pagebreak(to: "odd")`.
- **Page-counter parity is print parity.** Typst reads an odd counter as a recto, so the
  prelim counter must start on the half title (physical leaf 3, after the cover and its
  verso) or every inside margin in the front matter lands on the wrong side.
- **No Greek inside letterspaced small caps** — the accents come apart. Greek goes in body
  text or italic, never in a rubric.
- **What an edition is called comes from `edition_head()`, one function.** An edition with no
  `translator` is not therefore the original: check `kind`/`language` first, or the English
  Lectio edition gets labelled "the Greek original" on the four-ways page.
