"""Wikisource adapter (CONTENT_PIPELINE.md stages 1-2).

Used for original-language source texts not on Gutenberg (e.g. the Greek Meditations).
Fetches a page's raw wikitext via the MediaWiki API and caches it locally.
"""
from __future__ import annotations

import json
import os
import re
import time
import urllib.error
import urllib.parse
import urllib.request

_UA = {"User-Agent": "classics-pipeline/0.1 (public-domain content ingestion; contact: classics app)"}
_CACHE = os.path.join(os.path.dirname(__file__), "..", ".cache")


def fetch_wikitext(page: str, lang: str = "el") -> str:
    """Return the raw wikitext of a Wikisource page, caching it locally.

    Polite to the API: caches aggressively, paces requests, and backs off on 429/503."""
    os.makedirs(_CACHE, exist_ok=True)
    safe = re.sub(r"[^A-Za-z0-9_.-]", "_", f"{lang}-{page}")
    cache_path = os.path.join(_CACHE, f"wikisource-{safe}.txt")
    if os.path.exists(cache_path):
        with open(cache_path, encoding="utf-8") as f:
            return f.read()

    base = f"https://{lang}.wikisource.org/w/api.php"
    query = urllib.parse.urlencode({
        "action": "parse", "page": page, "prop": "wikitext",
        "format": "json", "formatversion": "2",
    })
    req = urllib.request.Request(f"{base}?{query}", headers=_UA)

    last_err = None
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                data = json.loads(r.read().decode("utf-8"))
            wikitext = data["parse"]["wikitext"]
            with open(cache_path, "w", encoding="utf-8") as f:
                f.write(wikitext)
            time.sleep(1.0)  # pace successive fetches
            return wikitext
        except urllib.error.HTTPError as e:
            last_err = e
            if e.code in (429, 503):
                time.sleep(2.0 * (attempt + 1) + 3.0)  # back off
                continue
            raise
    raise RuntimeError(f"Wikisource fetch failed for {page!r}: {last_err}")


def list_items(wikitext: str) -> list[str]:
    """Extract `# ...` wiki list items (one per line) as plain text — Wikisource
    renders numbered source texts (like the Greek Meditations) this way."""
    items = []
    for line in wikitext.splitlines():
        s = line.strip()
        if s.startswith("#") and not s.startswith("#ΑΝΑΚΑΤΕΥΘΥΝΣΗ") and not s.lower().startswith("#redirect"):
            text = s.lstrip("#").strip()
            if text:
                items.append(text)
    return items
