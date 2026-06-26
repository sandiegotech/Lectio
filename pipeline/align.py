"""Alignment spine (CONTENT_PIPELINE.md §4) — populate each Segment.spine so the
reader can scroll-sync and cross-highlight matching passages across editions.

Every segment gets a fractional span [from, to] within its section (0..1 strings).
Two segments in different editions correspond when their spans overlap — so the reader
maps a passage to its counterpart by span overlap, in either direction.

Two regimes, decided per (work, section):
  • equal segment counts  → uniform spans (index identity) — EXACT.
    Holds for Hamlet (every act 1:1) and ~90% of Dante's cantos.
  • unequal counts        → anchor-and-interpolate against the finest edition.
    Distinctive tokens shared by both editions (proper nouns, numbers, rare words)
    pin known correspondences; positions between anchors interpolate linearly, with a
    proportional fallback where a stretch has no anchors. This is what fixes prose like
    the Nicomachean Ethics (Lectio ~1 paragraph ≈ 3 of Chase's). Pure-Python, no AI.
"""
from __future__ import annotations

import re
from collections import Counter, defaultdict

from .model import Edition, SpineRange

_STOP = {
    "the", "and", "that", "this", "with", "from", "have", "has", "had", "for", "not",
    "but", "are", "was", "were", "they", "them", "their", "then", "than", "what",
    "which", "who", "whom", "whose", "when", "where", "will", "would", "should", "could",
    "there", "here", "into", "upon", "such", "some", "more", "most", "much", "also",
    "thus", "therefore", "because", "since", "while", "though", "although", "however",
    "these", "those", "other", "another", "each", "every", "both", "either", "neither",
    "about", "above", "after", "again", "against", "between", "before", "being", "been",
    "does", "doing", "done", "itself", "himself", "herself", "themselves", "very",
    "must", "shall", "may", "might", "can", "cannot", "one", "two", "any", "all",
    "out", "off", "over", "under", "same", "like", "even", "only", "ever", "never",
    "good", "thing", "things", "make", "made", "well", "many", "kind", "way", "part",
}


def _tokens(text: str) -> set[str]:
    """Distinctive tokens of a passage: proper nouns (mid-sentence capitals) and
    longer non-stopword words. Lowercased for matching across editions."""
    out: set[str] = set()
    for w in re.findall(r"[A-Za-z]+", text):
        lw = w.lower()
        if lw in _STOP:
            continue
        if len(lw) >= 4:
            out.add(lw)
        if len(w) >= 3 and w[0].isupper():
            out.add(lw)
    return out


def _overlap(a: set, b: set) -> float:
    """Token-overlap (containment) coefficient 0..1 — rewards a fine paragraph whose
    distinctive words are mostly contained in a coarse one (good for 1-to-many prose)."""
    if not a or not b:
        return 0.0
    return len(a & b) / min(len(a), len(b))


def _dp_anchors(C: list[set], F: list[set]) -> list[tuple[int, int]]:
    """Monotonic content alignment of coarse paragraphs C to fine paragraphs F by token
    overlap (Needleman–Wunsch with gaps). Returns confident (i, j) match pairs; a segment
    with no real counterpart — e.g. an edition's per-book ARGUMENT/summary heading, or
    trailing apparatus — falls through as a gap instead of dragging a real line out of
    place. This is what keeps an opening invocation aligned to the other edition's
    invocation rather than to its chapter title."""
    m, n = len(C), len(F)
    if m == 0 or n == 0:
        return []
    GAP = -0.06
    dp = [[0.0] * (n + 1) for _ in range(m + 1)]
    bt = [[2] * (n + 1) for _ in range(m + 1)]   # 0 = match, 1 = skip coarse, 2 = skip fine
    for i in range(1, m + 1):
        dp[i][0] = i * GAP; bt[i][0] = 1
    for j in range(1, n + 1):
        dp[0][j] = j * GAP; bt[0][j] = 2
    for i in range(1, m + 1):
        ci = C[i - 1]
        for j in range(1, n + 1):
            s = _overlap(ci, F[j - 1])
            diag = dp[i - 1][j - 1] + (s if s > 0 else GAP)
            up = dp[i - 1][j] + GAP
            left = dp[i][j - 1] + GAP
            if diag >= up and diag >= left:
                dp[i][j] = diag; bt[i][j] = 0
            elif up >= left:
                dp[i][j] = up; bt[i][j] = 1
            else:
                dp[i][j] = left; bt[i][j] = 2
    pairs: list[tuple[int, int]] = []
    i, j = m, n
    while i > 0 and j > 0:
        b = bt[i][j]
        if b == 0:
            if _overlap(C[i - 1], F[j - 1]) > 0.15:   # keep only confident matches as anchors
                pairs.append((i - 1, j - 1))
            i -= 1; j -= 1
        elif b == 1:
            i -= 1
        else:
            j -= 1
    pairs.reverse()
    return pairs


def _aligned_positions(seg_texts: list[str], ref_texts: list[str]) -> list[float | None]:
    """Each segment's fractional position (0..1) on the reference edition's axis, or None
    when it has no counterpart there — a leading argument/summary heading, trailing notes,
    etc. Matched segments take their match's fraction; interior gaps interpolate between
    their matched neighbours; leading and trailing gaps stay None, so a heading can never
    become a sync target."""
    n, m = len(ref_texts), len(seg_texts)
    if n == 0:
        return [None] * m

    def f(j: int) -> float:
        return (j + 0.5) / n

    if seg_texts == ref_texts:                       # the reference edition itself
        return [f(j) for j in range(m)]
    pairs = _dp_anchors([_tokens(t) for t in seg_texts], [_tokens(t) for t in ref_texts])
    if not pairs:                                    # no shared content (e.g. cross-language) → proportional
        return [f(round(i * (n - 1) / max(1, m - 1))) for i in range(m)]
    pos: list[float | None] = [None] * m
    for i, j in pairs:
        pos[i] = f(j)
    matched = [i for i, _ in pairs]
    for i in range(matched[0] + 1, matched[-1]):     # interior gaps interpolate
        if pos[i] is None:
            lo = max(k for k in matched if k < i)
            hi = min(k for k in matched if k > i)
            pos[i] = pos[lo] + (i - lo) / (hi - lo) * (pos[hi] - pos[lo])
    return pos                                        # before matched[0] / after matched[-1] stay None


def assign_spines(editions: list[Edition]) -> int:
    """Populate Segment.spine across one work's editions, in place. The clean modern
    (Lectio) edition — which opens on real text, not an argument heading — is the
    reference axis; every other edition is content-aligned to it. Each segment carries a
    point position on that axis; segments with no counterpart get no spine. Returns the
    number of segments tagged. Sections are matched across editions by order."""
    if len(editions) < 2:
        return 0
    orders = sorted({s.order for e in editions for s in e.sections})
    tagged = 0
    for order in orders:
        es = [(e, s) for e in editions
              for s in [next((s for s in e.sections if s.order == order), None)]
              if s and s.segments]
        if len(es) < 2:
            continue
        # reference axis: the modern edition's section if present, else the longest one.
        ref = next((s for e, s in es if e.kind == "modern"), None) \
            or max((s for _, s in es), key=lambda s: len(s.segments))
        ref_texts = [seg.text for seg in ref.segments]
        for _, s in es:
            for seg, p in zip(s.segments, _aligned_positions([sg.text for sg in s.segments], ref_texts)):
                if p is None:
                    seg.spine = None
                else:
                    seg.spine = SpineRange(fromRef=f"{p:.4f}", toRef=f"{p:.4f}")
                    tagged += 1
    return tagged
