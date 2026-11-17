# drafts

New Lectio editions, drafted but not yet in the pipeline. One folder per book:

    drafts/<slug>/SOURCES.md     the public-domain base, the original, where each came from
    drafts/<slug>/STYLE.md       the style sheet, written before the first section
    drafts/<slug>/book-NN.json   one section: {"order", "label", "title", "paragraphs", "divergences"}

A draft moves into `pipeline/modern/` when the book is ingested (`/ingest-book`) and the
sections are integrated (`tools/overnight/integrate.py`). Then it is reviewed like any other
edition (`review/METHOD.md`). Nothing here ships.

## How a draft is made

1. **Sources.** Fetch the public-domain base translation and the original-language text into
   `pipeline/.cache/` and record both in SOURCES.md, with URLs and rights. Divide the work into
   sections along the base text's own divisions, and write the list of sections down.
2. **Style sheet.** Before any section: names and their spellings; the dozen terms the work
   turns on and the one English word for each; oaths and forms of address; quote and verse
   style; what stays in the original language; the register (plain, current, never fashionable,
   readable from fifteen to ninety). Read the style sheets of related Lectio editions first
   (the "Policies" at the top of `review/*/<slug>/rejected*.md`) and agree with them.
3. **Draft from the original.** The base translation is a control on meaning, not the text
   to modernize. Where the base softens, skips or explains, follow the original.
4. **Never print apparatus.** No footnote, bracketed gloss, translator's note, summary or
   moral goes into a paragraph. What a reader needs to know goes in `divergences` or is left
   for the glossary.
5. **Passes**, per section: literal control, original and tradition, the draft, a fidelity
   pass clause by clause, a read-aloud pass. Then two or three `divergences` objects
   `{locus, phrase, older, lectio, note}` for the section's real cruxes.
6. **Whole sections, in order**, each written to its file before the next is begun. Repeated
   lines and formulas are rendered the same way every time.
