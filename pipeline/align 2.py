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


def _lis_nondecreasing(pairs: list[tuple[int, int]]) -> list[tuple[int, int]]:
    """Longest chain of (i, j) with both coordinates non-decreasing — keeps anchors
    monotonic so the mapping never folds back on itself. `pairs` sorted by (i, j)."""
    if not pairs:
        return []
    import bisect
    tails_j: list[int] = []        # smallest possible tail j for a chain of each length
    tails_pair: list[tuple[int, int]] = []
    parent: dict[int, int] = {}
    idx_of: list[int] = []
    for k, (i, j) in enumerate(pairs):
        pos = bisect.bisect_right(tails_j, j)
        if pos == len(tails_j):
            tails_j.append(j); tails_pair.append((i, j)); idx_of.append(k)
        else:
            tails_j[pos] = j; tails_pair[pos] = (i, j); idx_of[pos] = k
        parent[k] = idx_of[pos - 1] if pos > 0 else -1
    # reconstruct
    chain: list[tuple[int, int]] = []
    k = idx_of[-1]
    while k != -1:
        chain.append(pairs[k]); k = parent[k]
    chain.reverse()
    return chain


def _anchor_positions(coarse: list[str], fine: list[str]) -> list[float]:
    """For each coarse paragraph, its position (a float index in fine-paragraph space),
    found by anchoring on tokens that are rare in BOTH editions, then interpolating."""
    L, S = len(coarse), len(fine)
    if L == 0:
        return []
    if S <= 1 or L == 1:
        return [(i * (S - 1) / max(1, L - 1)) for i in range(L)]

    C = [_tokens(t) for t in coarse]
    F = [_tokens(t) for t in fine]
    dfc, dff = Counter(), Counter()
    for s in C:
        dfc.update(s)
    for s in F:
        dff.update(s)
    # tokens rare in both → strong correspondence signal
    ci, fj = defaultdict(list), defaultdict(list)
    for i, s in enumerate(C):
        for t in s:
            if dfc[t] <= 2 and 1 <= dff.get(t, 0) <= 2:
                ci[t].append(i)
    for j, s in enumerate(F):
        for t in s:
            if dff[t] <= 2 and 1 <= dfc.get(t, 0) <= 2:
                fj[t].append(j)
    cand: set[tuple[int, int]] = set()
    for t in set(ci) & set(fj):
        for i in ci[t]:
            for j in fj[t]:
                cand.add((i, j))
    anchors = _lis_nondecreasing(sorted(cand))
    # collapse to one j per i (average), keep j non-decreasing
    by_i: dict[int, list[int]] = defaultdict(list)
    for i, j in anchors:
        by_i[i].append(j)
    pts: list[tuple[int, float]] = []
    last = -1.0
    for i in sorted(by_i):
        j = sum(by_i[i]) / len(by_i[i])
        if j < last:
            j = last
        pts.append((i, j)); last = j
    # sentinels at the ends so every coarse index is bracketed
    pts = [(-1, 0.0)] + pts + [(L, float(S - 1))]
    pos = [0.0] * L
    for i in range(L):
        # find bracketing anchors a (<= i) and b (> i)
        a = max(p for p in pts if p[0] <= i)
        b = min(p for p in pts if p[0] > i)
        if b[0] == a[0]:
            pos[i] = a[1]
        else:
            frac = (i - a[0]) / (b[0] - a[0])
            pos[i] = a[1] + frac * (b[1] - a[1])
    return pos


def _uniform_spans(n: int) -> list[tuple[float, float]]:
    return [(k / n, (k + 1) / n) for k in range(n)] if n else []


def _coarse_spans(positions: list[float], fine_n: int) -> list[tuple[float, float]]:
    """Contiguous [0,1] spans for coarse paragraphs from their fine-space positions,
    split at the midpoints between neighbours so each covers its share of the text."""
    L = len(positions)
    if L == 0:
        return []
    if L == 1:
        return [(0.0, 1.0)]
    bounds = [0.0]
    for i in range(L - 1):
        mid = (positions[i] + positions[i + 1]) / 2 + 0.5   # midpoint, fine-index space
        bounds.append(min(1.0, max(0.0, mid / fine_n)))
    bounds.append(1.0)
    # enforce monotonic, non-empty
    for i in range(1, len(bounds)):
        if bounds[i] < bounds[i - 1]:
            bounds[i] = bounds[i - 1]
    return [(bounds[i], bounds[i + 1]) for i in range(L)]


def _spans_for(seg_texts: list[str], ref_texts: list[str]) -> list[tuple[float, float]]:
    if len(seg_texts) == len(ref_texts):
        return _uniform_spans(len(seg_texts))           # identity → exact
    pos = _anchor_positions(seg_texts, ref_texts)
    return _coarse_spans(pos, len(ref_texts))


def assign_spines(editions: list[Edition]) -> int:
    """Populate Segment.spine for every edition of one work, in place. Returns the
    number of segments tagged. Sections are matched across editions by order."""
    if len(editions) < 2:
        return 0
    # group sections by order across editions
    orders = sorted({s.order for e in editions for s in e.sections})
    tagged = 0
    for order in orders:
        secs = []
        for e in editions:
            s = next((s for s in e.sections if s.order == order), None)
            if s is not None:
                secs.append(s)
        if len(secs) < 2:
            continue
        ref = max(secs, key=lambda s: len(s.segments))   # finest edition = the axis
        ref_texts = [seg.text for seg in ref.segments]
        for s in secs:
            spans = _spans_for([seg.text for seg in s.segments], ref_texts)
            for seg, (lo, hi) in zip(s.segments, spans):
                seg.spine = SpineRange(fromRef=f"{lo:.4f}", toRef=f"{hi:.4f}")
                tagged += 1
    return tagged
