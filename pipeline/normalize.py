"""Text normalization helpers (CONTENT_PIPELINE.md stage 3).

Unify typography and whitespace so downstream segmentation and rendering are
consistent regardless of source. Source-specific boilerplate stripping lives in
the source adapters; this module is about clean text.
"""
from __future__ import annotations

import re
import unicodedata

# Smart-quote / dash unification (we normalize TO typographic forms for display).
_REPLACEMENTS = {
    "''": "”",
    "``": "“",
    "--": "—",   # em dash
}


def normalize_text(s: str) -> str:
    s = unicodedata.normalize("NFC", s)
    for a, b in _REPLACEMENTS.items():
        s = s.replace(a, b)
    # Collapse runs of spaces/tabs but preserve newlines (verse line breaks matter).
    s = re.sub(r"[ \t]+", " ", s)
    # Trim trailing spaces on each line.
    s = "\n".join(line.rstrip() for line in s.split("\n"))
    return s.strip()


def split_paragraphs(prose: str) -> list[str]:
    """Blank-line-delimited paragraphs for prose editions."""
    text = normalize_text(prose)
    parts = re.split(r"\n\s*\n", text)
    return [re.sub(r"\s*\n\s*", " ", p).strip() for p in parts if p.strip()]


def split_verse_blocks(verse: str) -> list[str]:
    """Blank-line-delimited stanzas; internal line breaks are preserved."""
    text = normalize_text(verse)
    blocks = re.split(r"\n\s*\n", text)
    return [b.strip("\n") for b in blocks if b.strip()]
