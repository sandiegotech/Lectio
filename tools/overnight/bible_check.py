#!/usr/bin/env python3
"""QA gate 2 for the Vernacular Bible: no verse may be silently dropped.

The Vernacular renders paragraphs, not verses, so a paragraph that quietly skips a verse
would never show up as a build error — the section would simply be a little shorter. This
check reads the source edition's verse coordinates and confirms every one of them falls
inside some Vernacular segment's spine range.

    python3 tools/overnight/bible_check.py [slug ...]     # default: every bible work

Exit 1 on any gap. Run before pipeline.build in the loop iteration.
"""
from __future__ import annotations

import glob
import json
import os
import sys


def ranges(edition):
    out = []
    for sec in edition["sections"]:
        for seg in sec["segments"]:
            sp = seg.get("spine")
            if sp:
                out.append((_key(sp["from"]), _key(sp["to"])))
    return out


def _key(ref):
    c, _, v = ref.partition(".")
    return (int(c), int(v or 0))


def check(work_dir: str) -> list[str]:
    wid = os.path.basename(work_dir)
    src = os.path.join(work_dir, "editions", "kjv-1611.json")
    vern = os.path.join(work_dir, "editions", "lectio-vernacular.json")
    if not (os.path.exists(src) and os.path.exists(vern)):
        return []
    source = json.load(open(src))
    modern = json.load(open(vern))

    covered = ranges(modern)
    # Only chapters the Vernacular has actually reached are in scope; the loop fills the
    # rest later, and a partial book is a normal mid-translation state.
    done = {sec["order"] for sec in modern["sections"]}
    problems = []
    for sec in source["sections"]:
        if sec["order"] not in done:
            continue
        for seg in sec["segments"]:
            sp = seg.get("spine")
            if not sp:
                continue
            v = _key(sp["from"])
            if not any(lo <= v <= hi for lo, hi in covered):
                problems.append(f"{wid} {sp['from']}: verse not covered by any Vernacular segment")
    return problems


def main() -> int:
    wanted = sys.argv[1:]
    dirs = sorted(glob.glob("content/works/work.bible.*"))
    if wanted:
        dirs = [d for d in dirs if os.path.basename(d).split(".")[-1] in wanted]
    if not dirs:
        print("bible_check: no bible works built yet")
        return 0
    bad = []
    for d in dirs:
        found = check(d)
        bad += found
        name = os.path.basename(d)
        print(f"  {name}: {'OK' if not found else str(len(found)) + ' GAPS'}")
    for b in bad[:20]:
        print("  !", b, file=sys.stderr)
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
