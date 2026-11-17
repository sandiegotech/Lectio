#!/usr/bin/env python3
"""Apply an editor-approved patch to an edition's source text.

    python3 tools/review/apply.py <slug> [--run RUN] [--dry]

Reads review/<run>/<slug>/patch*.json (newest run unless --run), and for each entry replaces
`old` with `new` in the edition source under pipeline/modern/ (<slug>.json, or the per-book
files in <slug>-books/). Text only: no paragraph is added, removed or reordered, so segment
ids hold. Entries the editor does not want are deleted from patch.json before running this.

An entry is applied only if `old` occurs exactly once in the source of its section. Anything
else is reported and left alone. Afterwards: `python3 -m pipeline.build`, read the diff, commit.
"""
import glob, json, os, sys

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")

def section_files(slug):
    """order -> (path, loader/saver kind). Sections live in <slug>.json or <slug>-books/."""
    out = {}
    main = os.path.join(ROOT, "pipeline/modern", slug + ".json")
    doc = json.load(open(main))
    for key in ("books", "chapters"):
        for b in doc.get(key, []):
            out[b["order"]] = (main, key)
    for f in glob.glob(os.path.join(ROOT, "pipeline/modern", slug + "-books", "book-*.json")):
        out[int(os.path.basename(f)[5:-5])] = (f, None)
    return out

def replace_in(node, old, new, hits):
    if isinstance(node, str):
        if old in node:
            hits.append(node.count(old))
            return node.replace(old, new)
        return node
    if isinstance(node, list):
        return [replace_in(x, old, new, hits) for x in node]
    if isinstance(node, dict):
        return {k: replace_in(v, old, new, hits) for k, v in node.items()}
    return node

def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not args:
        sys.exit(__doc__)
    slug, dry = args[0], "--dry" in sys.argv
    runs = sorted(glob.glob(os.path.join(ROOT, "review/*/%s/patch*.json" % slug)))
    if "--run" in sys.argv:
        run = sys.argv[sys.argv.index("--run") + 1]
        runs = [r for r in runs if r.split(os.sep)[-3] == run]
    if not runs:
        sys.exit("no patch.json for " + slug)
    newest = runs[-1].split(os.sep)[-3]                       # one run, all its patch files
    runs = [r for r in runs if r.split(os.sep)[-3] == newest]
    patch = [p for r in runs for p in json.load(open(r)) if p.get("seg")]
    files, docs, applied, skipped = section_files(slug), {}, 0, []
    for p in patch:
        where = files.get(int(p["section"]))
        if not where:
            skipped.append((p, "no such section")); continue
        path, key = where
        doc = docs.setdefault(path, json.load(open(path)))
        hits = []
        if key:
            idx = next(i for i, b in enumerate(doc[key]) if b["order"] == int(p["section"]))
            fixed = replace_in(doc[key][idx], p["old"], p["new"], hits)
        else:
            fixed = replace_in(doc, p["old"], p["new"], hits)
        if sum(hits) != 1:
            skipped.append((p, "old text found %d times" % sum(hits))); continue
        if key:
            doc[key][idx] = fixed
        else:
            docs[path] = fixed
        applied += 1
    if not dry:
        for path, doc in docs.items():
            before = open(path).read()                     # keep each file's own formatting
            indent = None if "\n" not in before.strip() else 2
            text = json.dumps(doc, ensure_ascii=False, indent=indent)
            with open(path, "w") as f:
                f.write(text + ("\n" if before.endswith("\n") else ""))
    print("%s: %d applied%s, %d skipped (%s)" % (slug, applied, " (dry run)" if dry else "",
                                               len(skipped), os.path.relpath(runs[-1], ROOT)))
    for p, why in skipped:
        print("  skipped s%s %s: %s — %r" % (p["section"], p["seg"], why, p["old"][:60]))

if __name__ == "__main__":
    main()
