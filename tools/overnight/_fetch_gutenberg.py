#!/usr/bin/env python3
"""Fetch a Project Gutenberg plain-text ebook into pipeline/.cache via the GITenberg
GitHub mirror — used when gutenberg.org egress is blocked (cloud). Writes the same
cache file gutenberg.fetch() expects: pipeline/.cache/gutenberg-<id>.txt

    python3 tools/overnight/_fetch_gutenberg.py <id> [<id> ...]
"""
import json, os, subprocess, sys

CACHE = os.path.join(os.path.dirname(__file__), "..", "..", "pipeline", ".cache")

def curl(url):
    return subprocess.run(["curl", "-sS", "--max-time", "40", url],
                          capture_output=True, text=True).stdout

def fetch(i):
    os.makedirs(CACHE, exist_ok=True)
    cache = os.path.join(CACHE, f"gutenberg-{i}.txt")
    if os.path.exists(cache) and os.path.getsize(cache) > 2000:
        return f"{i}: cached"
    j = curl(f"https://api.github.com/search/repositories?q=_{i}+user:GITenberg")
    try:
        d = json.loads(j)
    except Exception:
        return f"{i}: search parse fail"
    if d.get("total_count", 0) < 1:
        return f"{i}: NOT FOUND ({d.get('message','')[:50]})"
    repo = next((r["name"] for r in d["items"] if r["name"].endswith(f"_{i}")), d["items"][0]["name"])
    for fname in (f"{i}.txt", f"{i}-0.txt", f"{i}-8.txt"):
        for br in ("master", "main"):
            raw = curl(f"https://raw.githubusercontent.com/GITenberg/{repo}/{br}/{fname}")
            if "PROJECT GUTENBERG" in raw.upper() and len(raw) > 2000:
                # normalize to utf-8 text on disk
                open(cache, "w", encoding="utf-8").write(raw)
                return f"{i}: OK {repo}/{fname}@{br} ({len(raw)}b)"
    return f"{i}: FETCH FAIL (repo {repo})"

if __name__ == "__main__":
    for i in sys.argv[1:]:
        print(fetch(int(i)))
