"""Project Gutenberg plain-text adapter (CONTENT_PIPELINE.md stages 1-2).

Gutenberg plain-text editions are wrapped in *** START/END *** boilerplate. We fetch,
strip that, and provide a heading-based splitter. The recipe supplies the heading
pattern (and an optional end marker to drop trailing apparatus like APPENDIX/NOTES).
"""
from __future__ import annotations

import os
import re
import urllib.request

_UA = {"User-Agent": "codex-pipeline/0.1 (public-domain content ingestion)"}

# Local cache so re-runs are offline + fast and we don't re-hit Gutenberg.
_CACHE = os.path.join(os.path.dirname(__file__), "..", ".cache")


def fetch(gutenberg_id: int) -> str:
    """Return the raw UTF-8 text of a Gutenberg ebook, caching it locally."""
    os.makedirs(_CACHE, exist_ok=True)
    cache_path = os.path.join(_CACHE, f"gutenberg-{gutenberg_id}.txt")
    if os.path.exists(cache_path):
        with open(cache_path, encoding="utf-8") as f:
            return f.read()
    url = f"https://www.gutenberg.org/cache/epub/{gutenberg_id}/pg{gutenberg_id}.txt"
    req = urllib.request.Request(url, headers=_UA)
    with urllib.request.urlopen(req, timeout=30) as r:
        raw = r.read().decode("utf-8")
    with open(cache_path, "w", encoding="utf-8") as f:
        f.write(raw)
    return raw


_START = re.compile(r"\*\*\* *START OF TH(?:E|IS) PROJECT GUTENBERG EBOOK.*?\*\*\*", re.I)
_END = re.compile(r"\*\*\* *END OF TH(?:E|IS) PROJECT GUTENBERG EBOOK.*?\*\*\*", re.I)


def strip_boilerplate(raw: str) -> str:
    """Drop everything outside the START/END markers."""
    raw = raw.replace("\r\n", "\n").replace("\r", "\n")  # Gutenberg ships CRLF
    s = _START.search(raw)
    e = _END.search(raw)
    start = s.end() if s else 0
    end = e.start() if e else len(raw)
    return raw[start:end].strip("\n")


def split_sections(body: str, heading_re: str, end_re: str | None = None):
    """Split `body` at lines matching `heading_re` (multiline).

    Returns a list of (heading_text, section_body). Text before the first heading
    (front matter / table of contents) is dropped. If `end_re` is given, each
    section body is truncated at the first match — used to cut trailing apparatus
    (APPENDIX, NOTES, GLOSSARY) off the final book.
    """
    pat = re.compile(heading_re, re.M)
    end_pat = re.compile(end_re, re.M) if end_re else None
    matches = list(pat.finditer(body))

    out = []
    for i, m in enumerate(matches):
        start = m.end()
        stop = matches[i + 1].start() if i + 1 < len(matches) else len(body)
        chunk = body[start:stop]
        if end_pat:
            em = end_pat.search(chunk)
            if em:
                chunk = chunk[: em.start()]
        out.append((m.group(0).strip(), chunk.strip("\n")))
    return out
