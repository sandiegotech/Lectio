# audio — the recordings

The third edition of every work, after the reader and the printed book: a recording of the
Lectio edition, read aloud.

**No audio files live in this repo.** A recording is 100–400 MB per work; git is the wrong
place for it and it is the wrong thing to ship inside the app. What lives here is the part
that is text: how a recording was made, what is in it, and where to find it.

```
audio/
  README.md
  <workId>/
    manifest.json     # the recording's contract with the app — committed
    script/           # anything editorial the recording was made from — committed
```

Masters (`.wav`) stay outside the repo; delivery copies (`.m4a`) go to whichever host the
app downloads from. `audio/**/media/` is gitignored so a stray file cannot be committed by
accident.

## The manifest

One per work, and it is the only thing the app reads. It anchors the audio to the same
segment ids the reader and the printed book use, so a listener's position is a reader's
position:

```json
{
  "workId": "work.marcus-aurelius.meditations",
  "editionId": "edition.meditations.lectio-modern",
  "narrator": "…",
  "recorded": "2026-08",
  "provenance": { "…": "same honesty rules as an edition: who or what read it" },
  "tracks": [
    {
      "sectionId": "edition.meditations.lectio-modern.book-01",
      "file": "book-01.m4a",
      "bytes": 18234112,
      "duration": 1284.5,
      "sha256": "…",
      "marks": [{ "segmentId": "…seg-0001", "t": 0.0 }]
    }
  ]
}
```

`marks` is the point of the whole format: a timestamp per segment id means the app can
follow the text while it plays, resume a chapter where you stopped reading it, and jump to
audio from a highlight. Without them a recording is just a file that happens to be nearby.

## Provenance applies here too

If a recording is synthesised rather than read by a person, the manifest says so and the app
says so — the same rule the editions follow (`BIBLE.md`, `CONTENT_PIPELINE.md`). A synthetic
voice is not a scandal; an unlabelled one is.

## Not decided yet

Where the `.m4a` files are hosted, and how the app fetches them. See `docs` in the repo root
and the storage note in `CLAUDE.md`.
