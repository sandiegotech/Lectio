#!/usr/bin/env python3
"""Print one section of one edition, segment by segment, for review.

    python3 tools/review/section.py <work_id> <edition_short> <order>
    python3 tools/review/section.py <work_id>            # list editions and section counts

Read-only. Each segment prints as `[seg-id-tail] text`.
"""
import glob, json, os, sys

def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    root = os.path.join(os.path.dirname(__file__), "..", "..", "content", "works", sys.argv[1], "editions")
    if len(sys.argv) < 4:
        for f in sorted(glob.glob(os.path.join(root, "*.json"))):
            ed = json.load(open(f))
            print(os.path.basename(f)[:-5], ed.get("kind"), ed.get("language"), len(ed["sections"]), "sections")
        return
    ed = json.load(open(os.path.join(root, sys.argv[2] + ".json")))
    order = int(sys.argv[3])
    sec = next(s for s in ed["sections"] if s["order"] == order)
    print(f"# {ed['id']} · {sec['label']} · {sec.get('title', '')}")
    for seg in sec["segments"]:
        tail = seg["id"].split(".")[-1]
        print(f"[{tail}] {seg['text']}\n")

if __name__ == "__main__":
    main()
