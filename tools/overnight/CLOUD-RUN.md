# Running the overnight loop in the cloud (wifi-proof)

The loop did its work tonight from a **local** Claude Code session: the `/loop` wakeups
lived on your laptop, so if its wifi or power dropped, the loop paused (it never *lost*
anything — every batch is committed and pushed, and the queue recomputes from git — but it
stopped advancing until you came back).

To run it where your laptop staying awake/online doesn't matter, run it from
**Claude Code on the web (claude.ai/code)**, which executes in Anthropic's cloud.

## Why this works now

Everything the loop needs is in the repo and dependency-free:

- The pipeline is **stdlib-only Python** (`python3 -m pipeline.build`).
- Progress is **git-native** — `tools/overnight/next.py` derives the queue by diffing
  `pipeline/modern/*.json` against the source editions, so any fresh clone resumes exactly
  where the last one left off.
- The loop scripts now live in the repo (`tools/overnight/`), and the translation method is
  inlined in `RUNBOOK.md`, so a cloud agent needs nothing from your local machine.

## Steps

1. Push your working branch to GitHub (already done for `overnight-vernacular`).
2. Go to **claude.ai/code**, open this repository, and select the working branch.
3. Give it this prompt:

   > Follow `tools/overnight/RUNBOOK.md`. First run `bash tools/overnight/guard.sh set 4.5`
   > to arm a wall-clock stop. Then loop: run `python3 tools/overnight/next.py 3`; if it
   > returns `[]`, stop and tell me the queue is complete; otherwise translate that batch
   > (one subagent per section), `python3 tools/overnight/integrate.py`,
   > `python3 -m pipeline.build`, then commit and push. Re-check the guard before each batch
   > and stop if it says `DEADLINE_REACHED`. Never commit to `main`.

4. It runs server-side until the queue empties or the guard fires. Close your laptop freely;
   check progress anytime via the branch's commit history.

## Adding more works later

Append `(work_id, slug, source_edition_short)` rows to `PRIORITY` in
`tools/overnight/next.py` and commit. The queue picks them up automatically on the next run —
local or cloud.

## Notes / caveats

- **Scratch dir:** subagents write temp JSON to `$OVERNIGHT_SCRATCH` (default `/tmp/overnight`).
  It's ephemeral by design; integrate.py consumes and deletes the files each batch.
- **Recurring cloud cron (`/schedule`)** is a worse fit here: its sandbox would have to clone
  the repo and re-establish tooling each run. Prefer the claude.ai/code approach above for a
  single long run, and `/schedule` only for genuinely periodic "every morning" jobs.
- **Drafts, not final.** Whatever the loop produces still needs human review before print/publish.
