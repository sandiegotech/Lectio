---
name: ingest-book
description: Ingest a public-domain book into the Lectio content bundle. Use when adding a new work/translation to the reader — fetching from Project Gutenberg (or Standard Ebooks), writing a recipe in pipeline/recipes.py, building, and verifying the output is clean. Trigger on "ingest", "add a book", "add a translation", "add <title> to the library".
---

# Ingest a book into Lectio

Goal: add a new work (or another translation of an existing work) to `content/` cleanly,
with stable IDs and full provenance. The pipeline is documented in `CONTENT_PIPELINE.md`;
recipes live in `pipeline/recipes.py`. Work through these steps.

## 1. Identify the source and confirm rights
- Prefer **Standard Ebooks** (clean), else **Project Gutenberg** (use the plain-text
  `https://www.gutenberg.org/cache/epub/<id>/pg<id>.txt`).
- Confirm it's public domain. For **translations**, the *translator's* death/publication
  date governs PD status, not the original author's — verify the specific translator/year.
  Modern translations (Fagles, Lattimore, Wilson, etc.) are in copyright — do not ingest.

## 2. Inspect the raw structure BEFORE writing the recipe
Fetch the text and look at how it's actually laid out — heading conventions vary per book:
```
curl -sS "https://www.gutenberg.org/cache/epub/<id>/pg<id>.txt" -o /tmp/raw.txt
grep -nE "^(BOOK|CHAPTER|THE .* BOOK|CANTO)" /tmp/raw.txt | head
grep -n "START OF\|END OF" /tmp/raw.txt
```
Note: the exact heading regex, the translator/year (search the front matter), and any
trailing apparatus (APPENDIX/NOTES/GLOSSARY) that must be cut off the last section.

## 3. Add a recipe in `pipeline/recipes.py`
Copy the `meditations()` function as a template. A recipe returns `(Work, [Edition], spine_or_None)`:
- Use `gutenberg.fetch(id)` → `strip_boilerplate` → `split_sections(body, heading_re=..., end_re=...)`.
- Build each section with `segment.build_section(...)` (`form="verse"` for poetry, else `"prose"`).
- Set stable, human-readable IDs: `work.<author-slug>.<work-slug>`,
  `edition.<work-slug>.<translator>-<year>`, section slugs like `book-01` / `chapter-03`.
- Fill a complete `Provenance` (source, sourceUrl, sourceId, rightsStatus, retrievedDate).
- Set `Work.collections` to the shelves it belongs to (collection metadata is in `pipeline/collections.py`).
- Append the function to `RECIPES`.
- Add a sanity assertion (e.g. expected section count) like the meditations recipe does.

## 4. Build and verify
```
python3 -m pipeline.build
```
Then eyeball the output — this is the human review gate:
- Correct number of sections; first section starts with real text (no Gutenberg boilerplate).
- Last section ends on real text (trailing apparatus was cut).
- No id-drift warnings.
Spot-check with:
```
python3 -c "import json; e=json.load(open('content/works/<workId>/editions/<short>.json')); print(len(e['sections']), [s['label'] for s in e['sections']])"
```

## 5. (Optional) Editorial enrichment
If you want the margin rail populated, add/extend `content/works/<workId>/enrichment.json`
(people, Webster definitions, connections) — hand-authored editorial seed, keyed by sectionId.
The pipeline does not overwrite it.

## Notes
- CRLF: the Gutenberg adapter normalizes `\r\n`; make heading regexes tolerant of trailing
  whitespace (`[ \t]*$`).
- If a book isn't on Gutenberg/Standard Ebooks in clean text, write a new adapter in
  `pipeline/adapters/` rather than hacking the recipe.
- Keep the pipeline AI-free. Any AI assistance for alignment/enrichment goes through the
  `pipeline/ai` seam, which is a no-op today.
