"""Verse-marked scripture adapter (CONTENT_PIPELINE.md stages 1-2).

The public-domain English Bibles on Project Gutenberg — KJV (#10) and ASV (#8) — are laid
out one book after another under a running-title heading, with every verse tagged `C:V`
and the prose hard-wrapped underneath. That tagging is the reason the Bible is the easiest
corpus in the library to align: every sentence already carries an exact canonical
coordinate, so a work's spine needs no proportional allocation — it is simply the verse
range each segment covers.

This adapter does two jobs and nothing else:

    book(raw, "The Gospel According to Saint Mark", next_heading=...)  -> that book's text
    chapters(text)                                                      -> {chapter: {verse: text}}

Sixty-six books x four editions run through the same two functions; the per-book editorial
decisions stay in recipes, as always.
"""
from __future__ import annotations

import re

_VERSE = re.compile(r"(?:^|\s)(\d{1,3}):(\d{1,3})\s")


def book(raw: str, heading: str, next_heading: str | None = None) -> str:
    """The body of one book, taken from the running text of a whole Bible.

    Every book title also appears in the front-matter table of contents, so the BODY is
    the LAST occurrence of the heading, never the first.
    """
    text = raw.replace("\r\n", "\n")
    starts = [m.end() for m in re.finditer(re.escape(heading), text)]
    if not starts:
        raise ValueError(f"bible: heading not found: {heading!r}")
    start = starts[-1]
    if next_heading:
        ends = [m.start() for m in re.finditer(re.escape(next_heading), text)
                if m.start() > start]
        if not ends:
            raise ValueError(f"bible: next heading not found after {heading!r}")
        return text[start:ends[-1]].strip()
    return text[start:].strip()


def chapters(text: str) -> dict[int, dict[int, str]]:
    """Parse `C:V` verse-marked text into {chapter: {verse: text}}.

    Verse text is unwrapped (the source hard-wraps at ~72 columns, which is typography,
    not structure) and whitespace-collapsed.
    """
    marks = list(_VERSE.finditer(text))
    if not marks:
        raise ValueError("bible: no C:V verse markers found")
    out: dict[int, dict[int, str]] = {}
    for i, m in enumerate(marks):
        c, v = int(m.group(1)), int(m.group(2))
        body = text[m.end():marks[i + 1].start() if i + 1 < len(marks) else len(text)]
        out.setdefault(c, {})[v] = " ".join(body.split())
    return out


def verse_count(chs: dict[int, dict[int, str]]) -> int:
    return sum(len(v) for v in chs.values())


def chapter_body(verses: dict[int, str], numbered: bool = True) -> str:
    """One chapter as a section body: one verse per paragraph.

    Source editions keep a segment per verse — that is what makes them the control the
    Vernacular is checked against, and what lets Compare land on an exact verse. The
    Vernacular itself uses paragraph segments carrying verse-RANGE spines instead.
    """
    lines = []
    for n in sorted(verses):
        lines.append(f"{n}. {verses[n]}" if numbered else verses[n])
    return "\n\n".join(lines)
