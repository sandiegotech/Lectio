# Lectio content pipeline

Offline build tool: public-domain books → the portable JSON bundle in `../content/`
that the app consumes. No AI in v1 (see [BIBLE.md](../BIBLE.md) §10.1); the AI seam is
stubbed in `ai/` for later. Full design in [CONTENT_PIPELINE.md](../CONTENT_PIPELINE.md).

## Run

```bash
python3 -m pipeline.build      # builds every recipe, publishes to ../content/
```

No third-party dependencies (stdlib only). Sources are cached under `pipeline/.cache/`
so re-runs are offline and fast.

## Layout

| File | Role |
|---|---|
| `model.py` | The data contract (Work / Edition / Section / Segment / Collection / Provenance). |
| `normalize.py` | Typography + whitespace cleanup; paragraph/verse splitting. |
| `segment.py` | Builds sections of segments with stable, frozen IDs. |
| `adapters/` | Fetch + boilerplate-strip per source (`gutenberg.py`). |
| `recipes.py` | Per-book editorial recipes (heading patterns, metadata). **Add books here.** |
| `collections.py` | Curated shelves (the Harvard Classics). |
| `idledger.py` | Records frozen segment IDs; flags drift that would break annotations. |
| `publish.py` | Writes the versioned JSON bundle + manifest. |
| `ai/` | Swappable AI-backend seam (NoOp only today). |
| `build.py` | Entrypoint: run recipes → validate → ledger → publish. |

## Add a book

1. Find a clean public-domain source (prefer Standard Ebooks, then Gutenberg).
2. Add a recipe function in `recipes.py` returning `(Work, [Edition], spine_or_None)`,
   and append it to `RECIPES`.
3. Declare collection membership via `Work.collections`.
4. `python3 -m pipeline.build` and eyeball the output.

## Invariants

- **Stable IDs are frozen.** `seg-NNNN` order must not change once published; the ledger
  guards this. Reordering content breaks user highlights/notes.
- **Every edition carries provenance.** No source → it doesn't publish.
- **Output is app-agnostic JSON** — readable by Lectio and sibling apps (Gloss).
