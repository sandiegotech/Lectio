#!/usr/bin/env python3
"""What the review program still owes, in priority order.

    python3 tools/review/queue.py            # table per work
    python3 tools/review/queue.py --json N   # next N jobs as JSON, for a burn run

A section is `unreviewed` until some run has a report for it, `open` while its newest report
is graded B or C and no patch covers it, and `clear` once it is graded A or patched.
Reports live at review/<run>/<slug>/<NN>.md; patches at review/<run>/<slug>/patch.json.
"""
import glob, json, os, re, sys

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
# The order works are read for release. Edit this list to steer the burn.
ORDER = ["meditations", "iliad", "odyssey", "republic", "aeneid", "the-prince", "analects",
         "tao-te-ching", "dhammapada", "bhagavad-gita", "gilgamesh", "nicomachean-ethics",
         "confessions", "divine-comedy", "hamlet", "bible-mark", "bible-genesis"]

def slug_of(edition_id):
    return edition_id.split(".")[1]

def works():
    out = {}
    for f in glob.glob(os.path.join(ROOT, "content/works/*/editions/lectio-*.json")):
        ed = json.load(open(f))
        slug = os.path.basename(os.path.dirname(os.path.dirname(f))).split(".", 2)[-1]
        slug = {"marcus-aurelius.meditations": "meditations"}.get(slug, slug.split(".")[-1])
        if slug in ("genesis", "mark"):
            slug = "bible-" + slug
        out[slug] = {"work_id": ed["workId"], "edition": os.path.basename(f)[:-5],
                     "orders": [s["order"] for s in ed["sections"]]}
    return out

def reports(slug):
    """order -> (run, grade) for the newest report covering each section."""
    seen = {}
    for f in sorted(glob.glob(os.path.join(ROOT, "review/*/%s/*.md" % slug))):
        name = os.path.basename(f)[:-3]
        if not re.fullmatch(r"\d+(-\d+)?", name):
            continue
        run = f.split(os.sep)[-3]
        text = open(f).read()
        lo, _, hi = name.partition("-")
        grades = re.findall(r"^Grade:\s*([ABC])", text, re.M)
        for i, order in enumerate(range(int(lo), int(hi or lo) + 1)):
            g = grades[i] if i < len(grades) else (grades[-1] if grades else "?")
            seen[order] = (run, g)
    return seen

def patched(slug):
    done = set()
    for f in glob.glob(os.path.join(ROOT, "review/*/%s/patch*.json" % slug)):
        for p in json.load(open(f)):
            done.add(int(p["section"]))
    return done

def main():
    ws, jobs, rows = works(), [], []
    for slug in ORDER + sorted(set(ws) - set(ORDER)):
        if slug not in ws:
            continue
        w, rep, pat = ws[slug], reports(slug), patched(slug)
        unrev = [o for o in w["orders"] if o not in rep]
        opened = [o for o in w["orders"] if o in rep and rep[o][1] != "A" and o not in pat]
        clear = len(w["orders"]) - len(unrev) - len(opened)
        rows.append((slug, len(w["orders"]), clear, len(opened), len(unrev)))
        for o in opened:
            jobs.append({"job": "verify", "slug": slug, **{k: w[k] for k in ("work_id", "edition")}, "order": o})
        for o in unrev:
            jobs.append({"job": "review", "slug": slug, **{k: w[k] for k in ("work_id", "edition")}, "order": o})
    if "--json" in sys.argv:
        n = int(sys.argv[sys.argv.index("--json") + 1])
        jobs.sort(key=lambda j: j["job"] != "verify")   # close what is open before reading more
        print(json.dumps(jobs[:n]))
        return
    print("%-20s %8s %6s %5s %10s" % ("work", "sections", "clear", "open", "unreviewed"))
    for r in rows:
        print("%-20s %8d %6d %5d %10d" % r)

if __name__ == "__main__":
    main()
