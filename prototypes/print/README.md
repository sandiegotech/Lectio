# Print prototype — Lectio Editions

A first look at a **printed Lectio Edition** (BIBLE §7b): print as another render of the
content bundle. `build_sample.py` reads the Iliad Modern Edition + provenance from
`content/` and emits a typeset sample (HTML → PDF via Chrome).

Demonstrates the page **footer gloss** ("Where we are —", orient-don't-spoil), **opt-in
depth** (the `°` markers → "Notes — for the curious"), and the **provenance colophon**
with the non-negotiable *read-and-approved-before-printing* line.

- `Lectio-Iliad-BookI-sample.pdf` — the rendered sample (6×9in, 3 pages)
- `preview-opener.png` — the chapter opener
- `build_sample.py` — generator (uses EB Garamond from the SDIT repo; renders with
  `/Applications/Google Chrome.app` headless `--print-to-pdf`)

Footer glosses here are hand-authored for the opening pages to show the concept; in the
real pipeline they'd be composed from the per-passage "understand" layer at typeset time.
