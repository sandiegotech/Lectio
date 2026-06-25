# Overnight Vernacular Loop — Runbook

Produces **Lectio Modern ("The Vernacular")** editions — fresh plain-modern-English
renderings of public-domain works — one batch of sections per iteration, committing each
batch to git. Designed to run unattended, locally or in the cloud (see `CLOUD-RUN.md`).

- **Branch:** a dedicated working branch (e.g. `overnight-vernacular`). **NEVER commit to `main`.**
- **Output:** these are **first-pass DRAFTS** for human review before any print/publish. Honesty is a product principle.
- **Resumability:** progress is derived from committed state (`pipeline/modern/<slug>.json`), so a
  crash, wifi drop, or API hiccup can only *pause* the loop — never lose a section. Just re-run; the
  queue recomputes itself.

## Per iteration

1. `cd` to the repo root; `git switch <work-branch>`.
2. **Guard (optional wall-clock stop):** `bash tools/overnight/guard.sh` — if it prints
   `DEADLINE_REACHED`, STOP (no reschedule) and report. Arm it once at the start with
   `bash tools/overnight/guard.sh set 4.5`.
3. `python3 tools/overnight/next.py 3` → JSON `[{work_id,slug,order,label,pds}]`.
   If `[]` → **DONE**: do not reschedule; tell the user the queue is complete; STOP.
4. Spawn one subagent **per target, in parallel** (single message). Each subagent must:
   - Follow the translation method below (all passes; deep, quality over speed; web search allowed).
   - Match the voice/naming of the work's existing edition: read `pipeline/modern/<slug>.json`.
   - Read the literal base text from `content/works/<work_id>/editions/<pds[0]>.json` — the section at
     index `(order-1)` — and consult the original language + other public-domain translations; synthesize fresh.
   - Translate the *whole* section as a passage — never sentence-by-sentence, never fabricate; bridge
     lacunae minimally. **Preserve all proper nouns.**
   - Write ONLY JSON to `$OVERNIGHT_SCRATCH/<slug>-book-<NN>.json` (NN zero-padded; scratch dir defaults
     to `/tmp/overnight`):
     `{"order":N,"label":"<copy source label exactly>","title":"<prose only>","paragraphs":[...],"divergences":[...]}`.
5. `python3 tools/overnight/integrate.py` (validates, appends to `pipeline/modern/<slug>.json`, merges
   divergences, deletes temp files).
6. `python3 -m pipeline.build`.
   - FAIL → `git checkout -- pipeline/modern content`; count a failure. Two failures in a row → STOP. Else skip commit and continue.
   - OK → commit: `git add -A && git commit -m "Vernacular: <labels>" && git push`.
7. Schedule the next iteration (locally: `/loop`; in the cloud: just continue — see `CLOUD-RUN.md`).

**STOP when:** queue empty, OR 2 consecutive build failures, OR the guard deadline is hit.

## Per-format output rules

- **Prose** (e.g. Nicomachean Ethics, source `chase-1911`): clear modern-English paragraphs; include a short `title`.
- **Verse play** (e.g. Hamlet, source `original`) — **LIGHT TOUCH**: keep the verse lines and the author's
  own words; clear only genuine friction (archaic grammar, dead vocabulary, inverted syntax). Each paragraph =
  one speech (SPEAKER on its own first line, then lines separated by `\n`) OR a scene heading / stage direction.
  The original stays the default edition; the Vernacular is the companion.
- **Verse** (e.g. Divine Comedy, source `longfellow-1867`): one tercet per paragraph, lines separated by `\n`;
  modern verse, line-for-line in feel.

`divergences` MUST be an array of OBJECTS `{locus, phrase, older, lectio, note}` — never a bare string
(integrate.py skips entries missing `older`/`lectio`/`note`, because Swift's decoder requires them).

Once a work is fully translated, flip its `defaultEditionId` to the modern edition in
`pipeline/recipes.py` (except where the original should stay default by editorial choice, e.g. Shakespeare).

## Translation method (inlined so cloud agents need no local skill)

Work the section in passes, not one shot:
1. **Literal control** — read the assigned public-domain base section closely; that is the floor of meaning.
2. **Original + tradition** — consult the original language and 1–2 other public-domain translations for
   load-bearing cruxes; never reproduce in-copyright translations.
3. **Vernacular draft** — render the whole passage into clear, living modern English in the work's
   established voice. Keep what is load-bearing strange (famous lines, key images, theology) intact; clear
   only what genuinely blocks a modern reader.
4. **Fidelity pass** — check clause-by-clause against the original/base: nothing added, dropped, or softened
   into paraphrase; veiled names stay veiled where the original withholds them (note them in `divergences`).
5. **Music pass** — read aloud; match rhythm and register to the shipped sections.
6. **Divergences** — 1–3 objects flagging the section's real cruxes (a term, a famous line, an editorial choice).
