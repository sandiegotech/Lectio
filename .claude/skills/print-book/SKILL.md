---
name: print-book
description: Set a Lectio edition as a print-ready PDF book. Use when asked to make a PDF, a print edition, a physical/printable book, or a proof of any work in content/ — and when fixing or restyling one that already exists. Trigger on "make a PDF", "print edition", "print-ready", "typeset", "book PDF", "proof <title>".
---

# Set a Lectio edition in print

One generator does the whole book: `tools/print/build_book.py` reads `content/` and writes a
Typst source plus the PDF. It is the template — there is no per-book layout file, and no
prose about a book is typed by hand. Everything on the page (text, book titles, arguments,
provenance, divergences, threads) comes out of the bundle, so the printed page and the reader
cannot drift apart. `tools/print/README.md` describes the design; read it before changing it.

## 1. Build

```
python3 tools/print/build_book.py --work <workId> --edition <editionId> --compare-locus <locus>
```

Defaults are Meditations / the Lectio Edition / `5.16`. Both the PDF and the generated `.typ`
land in `tools/print/out/` (gitignored — the book regenerates from the bundle). Useful flags:
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

## 3. Verify by looking at the pages

Never ship a PDF you have not looked at. Render and read a spread of pages:

```
typst compile --root . --format png --ppi 100 --pages 3,5,7,9,13,45 tools/print/out/<stem>.typ /tmp/p{p}.png
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

Any correction goes into `tools/print/build_book.py`, never into the generated `.typ` (it is
overwritten on every build). Rebuild and re-verify after each change. If a fix changes the
*workflow* — a new flag, a new front/back-matter block, a new gotcha found the hard way — add
it to this skill and to `tools/print/README.md` in the same pass, so the next book is one
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
