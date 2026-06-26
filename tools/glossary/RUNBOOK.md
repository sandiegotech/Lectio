# Per-book glossary generation — Runbook

Produces the curated **in-context glossary** that tap-and-hold-to-define reads first
(`content/works/<id>/enrichment.json` → `glossary`). The goal: a modern reader can hold
almost any word they'd pause on and get a short, plain definition *in the book's sense* —
offline, inline, no API. This is depth on the words that matter, not a full dictionary
(ordinary words still fall through to Apple's on-device dictionary, then Gloss).

## Per work

1. Pick the work + its default reading edition (the Lectio/modern edition if present, else
   the public-domain one): `content/works/<work_id>/editions/<short>.json`.
2. Process it in chunks (e.g. a few books/sections per subagent so coverage stays thorough).
   Each subagent:
   - Reads its assigned sections of that edition.
   - Emits a glossary entry for **every word a general modern reader is likely to stop on**:
     less-common or elevated vocabulary, archaic/formal words, proper nouns (people, places,
     gods), and the work's key concepts. Be generous — aim to cover what a reader actually
     pauses on, not just the rare cases.
   - Each entry:
     - `term`  — the base form as it appears in the text.
     - `gloss` — 1–2 plain-modern-English sentences, the sense **as used in this work**.
     - `kind`  — `person | god | place | people | concept | word | thing` (optional).
     - `aliases` — other surface forms/inflections that appear (e.g. "virtue" → ["virtues"]),
       so a tap on any of them resolves. The app matches normalized surface forms, not lemmas,
       so inflections must be listed to resolve.
   - Writes ONLY JSON to `$GLOSSARY_SCRATCH/<slug>-<lo>-<hi>.json` (default scratch /tmp/glossary):
     `{"workId": "<work_id>", "entries": [ {term, gloss, kind?, aliases?}, ... ]}`
3. `python3 tools/glossary/integrate.py` — upserts into the work's enrichment.json, de-duped
   by the app's normalization (never clobbers existing/curated entries).
4. Rebuild the app (the bundle includes content/ by folder reference) and spot-check that
   holding a word shows an inline definition.

## Notes

- enrichment.json is hand-authored editorial seed; the content build does **not** overwrite it,
  so generated glossaries persist across `python3 -m pipeline.build`.
- These are first-pass **drafts** — same human-review-before-print principle as the editions.
- Don't duplicate the cross-work concept layer; if a term maps to a `concept.*` node, the
  curated entry may carry `conceptId` (optional), but plain glosses are fine.
