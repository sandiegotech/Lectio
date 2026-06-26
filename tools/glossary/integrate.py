#!/usr/bin/env python3
"""Merge generated glossary entries into each work's content/works/<id>/enrichment.json.

Subagents write chunk files to $GLOSSARY_SCRATCH (default /tmp/glossary), each:
    {"workId": "work.x.y", "entries": [{term, gloss, kind?, aliases?}, ...]}

This upserts them into the work's enrichment.json `glossary` array, de-duped by the
SAME normalization the app uses (lowercase; trim edge punctuation except - and '), so a
term already present (incl. the Iliad's curated names) is never clobbered. Other
enrichment fields (passages, chapters, …) are preserved. Run from the repo root:

    python3 tools/glossary/integrate.py
"""
from __future__ import annotations

import glob
import json
import os
import re

SCRATCH = os.environ.get("GLOSSARY_SCRATCH", "/tmp/glossary")
KEEP = re.compile(r"^[^0-9a-z\-']+|[^0-9a-z\-']+$")


def norm(w: str) -> str:
    return KEEP.sub("", w.lower())


def main():
    out = []
    for f in sorted(glob.glob(os.path.join(SCRATCH, "*.json"))):
        d = json.load(open(f))
        wid = d["workId"]
        entries = d.get("entries", [])
        ej = f"content/works/{wid}/enrichment.json"
        en = json.load(open(ej)) if os.path.exists(ej) else {"workId": wid}
        gl = en.get("glossary") or []
        seen = {norm(e["term"]) for e in gl if e.get("term")}
        added = 0
        for e in entries:
            term = (e.get("term") or "").strip()
            gloss = (e.get("gloss") or "").strip()
            t = norm(term)
            if not t or not gloss or t in seen:
                continue
            ne = {"term": term, "gloss": gloss}
            if e.get("kind"):
                ne["kind"] = e["kind"]
            al = [a.strip() for a in (e.get("aliases") or []) if a and a.strip()]
            if al:
                ne["aliases"] = al
            gl.append(ne)
            seen.add(t)
            added += 1
        en["glossary"] = gl
        json.dump(en, open(ej, "w"), ensure_ascii=False, indent=2)
        out.append(f"{wid}: +{added} (total {len(gl)})")
        os.remove(f)
    print("glossary integrated:\n  " + ("\n  ".join(out) if out else "nothing"))


if __name__ == "__main__":
    main()
