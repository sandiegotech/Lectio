#!/usr/bin/env python3
"""Self-check for the Genesis 35-50 draft. Read-only.

    python3 drafts/bible-genesis/selfcheck.py

For every chapter-NN.json: valid JSON in the chapter shape, as many spines as
paragraphs, spine ranges contiguous and in order, and verse coverage equal to the
bundled KJV 1611 (every KJV verse covered exactly once, nothing extra). Also flags
printed apparatus (brackets), straight double quotes, and unbalanced curly quotes.
"""
import json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
KJV = os.path.join(HERE, "..", "..", "content", "works", "work.bible.genesis", "editions", "kjv-1611.json")
CHAPTERS = range(35, 51)


def kjv_verses():
    ed = json.load(open(KJV, encoding="utf-8"))
    out = {}
    for sec in ed["sections"]:
        nums = []
        for seg in sec["segments"]:
            m = re.match(r"\s*(\d+)\.\s", seg["text"])
            if not m:
                sys.exit(f"KJV segment without a verse number in section {sec['order']}: {seg['text'][:40]!r}")
            nums.append(int(m.group(1)))
        out[sec["order"]] = nums
    return out


def main():
    kjv = kjv_verses()
    failures, words = [], 0
    for ch in CHAPTERS:
        problems = []
        path = os.path.join(HERE, f"chapter-{ch}.json")
        try:
            d = json.load(open(path, encoding="utf-8"))
        except Exception as e:  # missing or invalid JSON
            failures.append(f"{ch}: {e}")
            print(f"chapter {ch}: FAIL ({e})")
            continue
        if sorted(d.keys()) != ["label", "order", "paragraphs", "spines", "title"]:
            problems.append(f"keys {sorted(d.keys())}")
        if d.get("order") != ch or d.get("label") != f"Chapter {ch}" or not d.get("title"):
            problems.append("order/label/title")
        sp, pa = d.get("spines", []), d.get("paragraphs", [])
        if len(sp) != len(pa):
            problems.append(f"{len(sp)} spines vs {len(pa)} paragraphs")
        covered = []
        for s in sp:
            c1, v1 = map(int, s["from"].split("."))
            c2, v2 = map(int, s["to"].split("."))
            if c1 != ch or c2 != ch or v2 < v1:
                problems.append(f"bad range {s}")
            covered.extend(range(v1, v2 + 1))
        if covered != kjv[ch]:
            missing = sorted(set(kjv[ch]) - set(covered))
            extra = sorted(set(covered) - set(kjv[ch]))
            dup = sorted({v for v in covered if covered.count(v) > 1})
            problems.append(f"coverage: missing {missing} extra {extra} duplicated {dup} (or out of order)")
        text = "\n".join(pa)
        for p in pa:
            if not isinstance(p, str) or not p.strip() or "\n" in p:
                problems.append("empty paragraph or line break inside a paragraph")
        if '"' in text:
            problems.append("straight double quote")
        if re.search(r"[\[\]{}*]", text):
            problems.append("bracket or asterisk (apparatus?)")
        # A speech that runs over a paragraph break reopens with “ and no close before it
        # (the convention chapter 31 uses), so that reopening mark is not counted.
        depth = 0
        for p in pa:
            body = p[1:] if (depth > 0 and p.startswith("“")) else p
            depth += body.count("“") - body.count("”")
            if depth not in (0, 1):
                problems.append("curly double quotes unbalanced")
                break
        if depth != 0:
            problems.append("speech left open at the end of the chapter")
        if text.count("‘") != text.count("’"):
            problems.append(f"curly single quotes unbalanced ({text.count('‘')} open, {text.count('’')} close)")
        n = len(text.split())
        words += n
        status = "ok" if not problems else "FAIL " + "; ".join(problems)
        print(f"chapter {ch}: {len(pa)} paragraphs, verses 1-{max(covered) if covered else 0} of {len(kjv[ch])}, {n} words: {status}")
        failures.extend(f"{ch}: {p}" for p in problems)
    print(f"total words: {words}")
    print("SELF-CHECK PASSED" if not failures else f"SELF-CHECK FAILED ({len(failures)} problems)")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
