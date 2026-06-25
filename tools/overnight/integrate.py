#!/usr/bin/env python3
"""Validate subagent output and merge it into the Lectio Modern editions.

Reads every <slug>-book-<NN>.json the subagents wrote to the scratch dir
($OVERNIGHT_SCRATCH, default /tmp/overnight), validates it, appends the section to
pipeline/modern/<slug>.json (sorted by order), merges well-formed divergences, and
deletes the temp file. Idempotent: a section already present is skipped, so re-running
after an interruption is safe.

    python3 tools/overnight/integrate.py
"""
import json, os, glob, re

SCRATCH = os.environ.get("OVERNIGHT_SCRATCH", "/tmp/overnight")
# Drop stray apparatus a subagent may have appended into the body (e.g. "Sources Cited").
STRAY = re.compile(r'^\s*(\*\*)?\s*(sources?\s+cited|sources?:|trans(lation|lator)\s+note|\[?sources)', re.I)

out = []
for f in sorted(glob.glob(os.path.join(SCRATCH, "*-book-*.json"))):
    slug = os.path.basename(f).split("-book-")[0]
    sec = json.load(open(f))
    paras = [p for p in sec.get("paragraphs", []) if isinstance(p, str) and p.strip() and not STRAY.match(p)]
    assert paras, f"{f}: no paragraphs after cleaning"
    assert sec.get("order") and sec.get("label"), f"{f}: missing order/label"
    mj = f"pipeline/modern/{slug}.json"; data = json.load(open(mj))
    if sec["order"] in {b["order"] for b in data["books"]}:
        os.remove(f); continue
    book = {"order": sec["order"], "label": sec["label"], "paragraphs": paras}
    if sec.get("title"): book["title"] = sec["title"]
    data["books"].append(book); data["books"].sort(key=lambda b: b["order"])
    for d in sec.get("divergences", []) or []:
        # Swift's decoder requires non-optional older/lectio/note — skip malformed entries.
        if isinstance(d, dict) and all(isinstance(d.get(k), str) and d.get(k) for k in ("older", "lectio", "note")):
            data.setdefault("divergences", []).append(d)
    json.dump(data, open(mj, "w"), ensure_ascii=False, indent=2)
    out.append(f'{slug} {sec["label"]} ({len(paras)}p)'); os.remove(f)
print("integrated: " + ("; ".join(out) if out else "nothing"))
