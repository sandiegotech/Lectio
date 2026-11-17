"""Stage 5 — ALIGN (CONTENT_PIPELINE.md §4): attach spine ranges to segments.

Every multi-edition work gets a shared coordinate system so the app can put the
same moment of the poem side by side across a verse translation, a prose one,
and the Lectio edition — and so bookmarks, highlights, art, and annotations can
anchor to "Iliad 1.194" regardless of which edition the reader is in.

Three strategies, chosen by the work's reference scheme:

- **Line schemes** (book.line): the scholarly-standard per-book line counts of
  the original (the tables below). Each edition's body segments split the book's
  lines proportionally by weight — verse lines for verse editions, characters
  for prose. Front-matter apparatus (Pope's "ARGUMENT.", Butler's chapter
  summaries) gets no spine.
- **Unit schemes** (book.section, book.chapter): the canonical unit count per
  book. For book.section works the canonical counts come from the bundled
  original-language edition (Meditations' Greek); segments are allocated by
  index, so near-1:1 editions align near-exactly. book.chapter works allocate
  by character weight (their segments are paragraphs, not chapters).
- **Section schemes** (cantica.canto, act.scene): the section itself is the
  coordinate (Canto = section); every segment carries its section's ref.
  Hamlet's acts subdivide into canonical scene counts by weight.

Exactness varies by strategy; *consistency* is what makes sync work — every
edition of a work draws from the same tables. Proportional allocation is the
documented v1 ("AI-suggested alignment, human-confirmed" refines later).
"""
from __future__ import annotations

from .model import Edition, SpineRange, Work

# ---------------------------------------------------------------------------
# Canonical unit tables (scholarly-standard counts; the shared coordinates)
# ---------------------------------------------------------------------------

# Lines per book of the Greek/Latin originals (standard modern texts).
LINE_COUNTS = {
    "work.homer.iliad": [
        611, 877, 461, 544, 909, 529, 482, 565, 713, 579, 848, 471,
        837, 522, 746, 867, 761, 617, 424, 503, 611, 515, 897, 804,
    ],
    "work.homer.odyssey": [
        444, 434, 497, 847, 493, 331, 347, 586, 566, 574, 640, 453,
        440, 533, 557, 481, 606, 428, 604, 394, 434, 501, 372, 548,
    ],
    "work.virgil.aeneid": [
        756, 804, 718, 705, 871, 901, 817, 731, 818, 908, 915, 952,
    ],
}

# Chapters per book (Nicomachean Ethics, Bekker-standard chaptering).
CHAPTER_COUNTS = {
    "work.aristotle.nicomachean-ethics": [13, 9, 12, 9, 11, 13, 14, 14, 12, 9],
}

# Scenes per act (Hamlet, Folger-standard).
SCENE_COUNTS = {
    "work.shakespeare.hamlet": [5, 2, 4, 7, 2],
}


def apply(work: Work, editions: list[Edition]) -> dict | None:
    """Attach spine ranges in place. Returns the spine.json payload, or None
    when the work isn't aligned (single edition, or no strategy for it)."""
    if len(editions) < 2:
        return None

    scheme = work.referenceScheme
    if work.id in LINE_COUNTS:
        counts = LINE_COUNTS[work.id]
        for e in editions:
            _allocate(e, counts, by_index=False)
    elif scheme == "book.section":
        canonical = _canonical_edition(editions)
        counts = [len(s.segments) for s in canonical.sections]
        for e in editions:
            _allocate(e, counts, by_index=True)
    elif work.id in CHAPTER_COUNTS:
        counts = CHAPTER_COUNTS[work.id]
        for e in editions:
            _allocate(e, counts, by_index=False)
    elif scheme == "cantica.canto":
        counts = _align_cantos(editions)
    elif work.id in SCENE_COUNTS:
        counts = SCENE_COUNTS[work.id]
        for e in editions:
            _allocate(e, counts, by_index=False)
    else:
        # No canonical table for this work: place each segment by its position in the
        # section, a fraction from 0 to 1. Coarse, but it keeps Compare and cross-edition
        # bookmarks working, and a real table can replace it without changing the contract.
        # A recipe that set its own ranges (the Bible, by verse) is left alone.
        if any(seg.spine for e in editions for sec in e.sections for seg in sec.segments):
            return None
        for e in editions:
            for sec in e.sections:
                body = _body_segments(sec.segments)
                for i, seg in enumerate(body):
                    seg.spine = SpineRange(fromRef=f"{i / len(body):.4f}", toRef=f"{(i + 1) / len(body):.4f}")
        counts = []

    return {
        "referenceScheme": scheme,
        "unitsPerSection": counts,
        "method": "pipeline.align v1 — canonical counts, proportional allocation",
    }


# ---------------------------------------------------------------------------
# Allocation
# ---------------------------------------------------------------------------

def _allocate(edition: Edition, counts: list[int], by_index: bool) -> None:
    """Split each section's canonical units across its body segments,
    monotonically and exhaustively (first segment starts at unit 1, last ends
    at unit N). Weight is 1/segment for unit schemes, verse lines or characters
    for line schemes."""
    verse = edition.form == "verse"
    for bi, sec in enumerate(edition.sections):
        if bi >= len(counts):
            break
        n = counts[bi]
        body = _body_segments(sec.segments)
        if not body or n <= 0:
            continue
        if by_index:
            weights = [1.0] * len(body)
        elif verse:
            weights = [float(seg.text.count("\n") + 1) for seg in body]
        else:
            weights = [float(max(len(seg.text), 1)) for seg in body]
        total = sum(weights)
        book = str(sec.order)

        acc = 0.0
        prev_end = 0
        for i, (seg, w) in enumerate(zip(body, weights)):
            acc += w
            if i == len(body) - 1:
                end = n
            else:
                end = min(n, max(prev_end + 1, round(acc / total * n)))
            start = min(n, prev_end + 1)
            seg.spine = SpineRange(fromRef=f"{book}.{start}", toRef=f"{book}.{max(start, end)}")
            prev_end = max(prev_end, end)


def _align_cantos(editions: list[Edition]) -> list[int]:
    """cantica.canto: each section is one canto; every segment carries its
    canto's ref (e.g. "Inferno.5"). Returns cantos per cantica."""
    per_cantica: dict[str, int] = {}
    for e in editions:
        counting: dict[str, int] = {}
        for sec in e.sections:
            cantica = sec.label.split(":")[0].strip() or "Canto"
            counting[cantica] = counting.get(cantica, 0) + 1
            ref = f"{cantica}.{counting[cantica]}"
            for seg in sec.segments:
                seg.spine = SpineRange(fromRef=ref, toRef=ref)
        if len(counting) > len(per_cantica):
            per_cantica = counting
    return list(per_cantica.values())


def _canonical_edition(editions: list[Edition]) -> Edition:
    """The edition whose segmentation defines the unit numbering: the original
    language if bundled, else the Lectio edition, else the first."""
    for e in editions:
        if e.kind == "original":
            return e
    for e in editions:
        if e.kind == "modern":
            return e
    return editions[0]


# ---------------------------------------------------------------------------
# Apparatus detection (mirrors the app's bodySegments heuristic)
# ---------------------------------------------------------------------------

def _body_segments(segments: list) -> list:
    """Segments minus leading apparatus — all-caps headings ("ARGUMENT."), the
    prose block a heading introduces, and dash-chained chapter summaries — and
    minus heading-kind segments anywhere. Apparatus gets no spine."""
    start = 0
    after_heading = False
    while start < min(6, len(segments)):
        t = segments[start].text.strip()
        if len(t) < 80 and t.upper() == t and any(c.isalpha() for c in t):
            after_heading = True
            start += 1
            continue
        if start == 0 and len(t) < 600 and _chained_dashes(t) >= 1:
            start += 1
            continue
        if after_heading:
            after_heading = False
            start += 1
            continue
        break
    return [s for s in segments[start:] if s.kind not in ("heading", "omit")]


def _chained_dashes(text: str) -> int:
    """Em-dashes jammed between letters (word—word) — the signature of an old
    edition's chapter-summary chain, never of body prose here."""
    n = 0
    for i, ch in enumerate(text):
        if ch == "—" and 0 < i < len(text) - 1 and text[i - 1].isalpha() and text[i + 1].isalpha():
            n += 1
    return n
