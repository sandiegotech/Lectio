# Edition review — method

A review pass reads one section of a Lectio edition against its sources and writes a report.
It never edits `content/` or `pipeline/modern/`. Fixes are applied later, by a person or under
one, from the reports. Reports are the punch list for the human review gate (BIBLE §2).

## Inputs

    python3 tools/review/section.py <work_id>                      # editions on hand
    python3 tools/review/section.py <work_id> <edition> <order>    # one section, with segment ids

Read the Lectio edition (`lectio-modern` or `lectio-vernacular`) and every other edition of the
same section: the public-domain translations and the original language where bundled. Sections
do not always split into the same segments across editions; match by content.

## What to check, in this order

1. **Fidelity.** Clause by clause against the base and the original: anything added, dropped,
   softened, sharpened, or explained into the text. A gloss smuggled into the sentence is an
   error even when it is correct. Proper nouns preserved. Famous lines still recognizable.
2. **Register.** The edition must read for anyone from fifteen to ninety (BIBLE §7c): plain and
   current, never fashionable. Flag slang, corporate or therapeutic vocabulary, anachronism,
   and words used in a sense a reader no longer carries. Flag leftover archaism too.
3. **Voice.** Does it sound like one writer, the same as the rest of the work? Flag flat
   paraphrase, filler, mechanical rhythm, repeated sentence shapes, stock phrases.
4. **Read-aloud.** Sentences that trip, run too long, or lose their stress.
5. **Form.** Verse stays verse (line breaks intact); speeches keep their speaker; no stray
   markup, headings inside text, or truncated segments.

## Report: `review/<run>/<slug>/<NN>.md`

    # <Work> · <Section label>
    Grade: A | B | C        (A ship as is · B small fixes · C redo the section)
    One-line verdict.

    ## Issues
    - `seg-0007` · fidelity · high
      > the quoted phrase from the Lectio text
      Problem in one sentence, with the source reading.
      Fix: the proposed replacement wording.

    ## Best lines
    One or two lines worth keeping exactly, so a later pass does not flatten them.

Severity: high = meaning wrong or missing · medium = reader stumbles · low = polish.
Report only real issues. A clean section gets grade A and an empty Issues list; do not pad.
Do not quote more than a phrase from any in-copyright translation.

When every assigned section is done, write or update `review/<run>/<slug>/SUMMARY.md`: a table of
section → grade → count of high/medium/low, then the three patterns that recur most across the
work, then a one-paragraph verdict on whether the edition is ready to ship.

## Running an assignment

An assignment is: work id, slug, Lectio edition, a range of section orders, the editions to
compare against, and a run name (the date). Work from the repo root.

- Create report files only. Never edit `content/`, `pipeline/`, `app/` or any existing file,
  and run no git command that changes state.
- One section at a time: print the Lectio section and the same section of every comparison
  edition, review it, write `review/<run>/<slug>/<NN>.md` (NN = zero-padded section order, three
  digits for works with 100 or more sections), then move on. Write each report before starting
  the next, so an interruption loses nothing. Skip a section whose report already exists.
- Be exacting. The reader should get a truly great modern read.
- When the range is done, write or update `SUMMARY.md` (if another reviewer has the other half
  of the work, merge into the existing table rather than replacing it).
- Final reply: at most four lines — sections done, grade counts, the top recurring pattern.

## Verify: from report to patch

A report is one reader's opinion. Before any fix touches the edition, a second pass checks it.

For a section whose report is graded B or C, take each issue in turn and try to prove it wrong:
reread the Lectio segment, the base, and the original. Keep an issue only if it holds. Then
write the fix as it should print: faithful, in the work's voice, in the plain register, and
changing as little of the sentence as the fix needs. Never split, merge, add or remove a
segment; segment ids are frozen.

Append the confirmed fixes to `review/<run>/<slug>/patch.json`, a JSON array of:

    {"section": 1, "seg": "seg-0017", "severity": "high",
     "old": "not raised too long by my father's mistress",
     "new": "not raised any longer by my grandfather's mistress",
     "why": "Greek τῇ παλλακῇ τοῦ πάππου; Long: grandfather's concubine."}

`old` must be an exact substring of the current segment text, long enough to be unique in it.
A section with no confirmed issue still gets one entry, `{"section": N, "seg": null}`, so the
queue knows it was checked. Rejected issues go in `review/<run>/<slug>/rejected.md`, one line each
with the reason, so the same false alarm is not raised twice.

A patch is a proposal. It is applied only after the editor has read it
(`python3 tools/review/apply.py <slug>`), and the edition's provenance records the revision.

### Running a verify assignment

An assignment names a work (slug, work id, Lectio edition, comparison editions, run) and any
work-wide patterns the reviewers raised. Work from the repo root.

- Read every `review/<run>/<slug>/NN.md`. For each section with issues, re-check each issue
  against the texts (`tools/review/section.py`); where the original is not bundled, judge from
  your own knowledge of it and say so in `why`. High and medium first, then low.
- For each work-wide pattern, choose one policy, state it at the top of `rejected.md` under
  "Policies", and include the patch entries it needs. Purely mechanical normalizations (quote
  style, a spelling) are described as a policy, not patched entry by entry.
- Create only `patch.json` and `rejected.md` in `review/<run>/<slug>/`. Never edit `content/`,
  `pipeline/`, `app/` or an existing file, and change no git state.
- Before finishing, check with a short script that the file is valid JSON and that every `old`
  occurs exactly once in its segment's current text; fix or drop any that do not.
- Final reply: at most six lines — entries by severity, issues rejected, policies chosen.

## Finish: after a patch is applied

A patch changes section text only. Two things are left for each work, both in the edition's
source file, `pipeline/modern/<slug>.json` (and `<slug>-books/` where a work has one):

1. **The mechanical policies.** `rejected*.md` states them under "Policies": one quote style,
   dash spacing, a spelling, contractions in narration, and the like. Apply each across the
   whole work with a script you write and then read the result of; show the count of changes
   per policy. Only what the policy names. Where a policy needs judgment case by case, do the
   clear cases and list the rest.
2. **The divergence notes.** The `divergences` array quotes the edition's own wording and
   argues for it. Where a patch changed that wording or reversed the choice, rewrite the note
   so it quotes the text as it now stands and gives the reason now in force (the patch entry's
   `why` has it). Keep every note an object with `locus`, `phrase`, `older`, `lectio`, `note`.
   Remove a note only if the thing it discusses is gone. Do the same for the `overview` and
   `introduction` if they describe a choice the edition no longer makes.

Rules: never add, remove, merge, split, empty or reorder a paragraph (run a check before and
after: the number of paragraphs in every section must be identical). Keep the file's JSON
formatting exactly (indent 2, non-ASCII kept, same trailing newline or lack of one). Touch no
other file except to append a "Finish" section to `review/<run>/<slug>/rejected.md` (or
`rejected-*.md`) saying what was done and what is still left for the editor. No git commands
that change state. Do not run the pipeline build; it is run once for all works afterwards.
Final reply: at most six lines — changes per policy, notes rewritten, what is left.
