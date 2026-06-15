"""Segmentation + stable-ID assignment (CONTENT_PIPELINE.md stage 4).

IDs follow the scheme  <editionId>.<sectionSlug>.seg-NNNN  and are zero-padded so
they sort lexically. Once an edition is published these IDs are frozen via the
id-ledger (see publish.py); re-running the pipeline must not renumber them.
"""
from __future__ import annotations

from .model import Section, Segment, SpineRange
from .normalize import split_paragraphs, split_verse_blocks


def section_id(edition_id: str, section_slug: str) -> str:
    return f"{edition_id}.{section_slug}"


def segment_id(section_id_: str, order: int) -> str:
    return f"{section_id_}.seg-{order:04d}"


def build_section(
    edition_id: str,
    section_slug: str,
    order: int,
    label: str,
    body: str,
    form: str,                       # "verse" | "prose"
    title: str | None = None,
    spine: list[SpineRange] | None = None,
) -> Section:
    """Turn a raw section body into a Section of segments.

    `spine`, if given, must be the same length as the produced segments and maps
    each segment onto the work's reference scheme for cross-translation sync.
    """
    sid = section_id(edition_id, section_slug)
    blocks = split_verse_blocks(body) if form == "verse" else split_paragraphs(body)

    if spine is not None and len(spine) != len(blocks):
        raise ValueError(
            f"spine length {len(spine)} != segment count {len(blocks)} for {sid}"
        )

    segments: list[Segment] = []
    for i, text in enumerate(blocks, start=1):
        segments.append(
            Segment(
                id=segment_id(sid, i),
                order=i,
                kind="verse_block" if form == "verse" else "paragraph",
                text=text,
                spine=spine[i - 1] if spine else None,
            )
        )

    return Section(id=sid, order=order, label=label, title=title, segments=segments)
