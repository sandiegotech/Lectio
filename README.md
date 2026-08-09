# Lectio

> *Lectio* (Latin: "a reading"). **Let any person today read a great work of the Western canon — any
> of the Harvard Classics — with genuine ease.** iPad first, then iPhone and Mac.

The greatest books ever written are free and in the public domain, and almost nobody reads them — not
because people can't, but because the on-ramp is brutal: archaic translations, no context, dense walls of
text, names and references that assume a 1900 classical education. Lectio removes that friction.

Open *The Iliad* or *Meditations* and you get a clear, modern, readable version by default. The moment
you're curious, hold it against any historical translation or the original language, with the people,
words, and ideas explained in a quiet right-hand margin.

The product vision lives in [BIBLE.md](BIBLE.md); content and data design in
[CONTENT_PIPELINE.md](CONTENT_PIPELINE.md). Read those before large changes.

## The flagship: the Lectio Modern Edition

The headline feature, and the thing only we do: **a fresh, plain-modern-English edition of each work,
produced by deep research** — faithful to the original, synthesized from the full scholarly record,
expressed in the language people actually read now. It's the default; one tap switches to any
public-domain translation (Pope, Butler, Long, Casaubon…) or the original language.

Provenance is a first-class feature: every edition carries a record (model + date + sources cited for
Lectio editions; translator + year + digitization source for historical ones). Nothing ships without one.

## Repository layout

Three parts, connected by one contract:

| Path | What it is |
|---|---|
| [`pipeline/`](pipeline/) | Offline Python tool (stdlib only) that turns public-domain books into a portable JSON content bundle. |
| [`content/`](content/) | The generated bundle — committed, because it's the app's input. |
| [`app/`](app/) | The SwiftUI reader (target `Lectio`, bundle `com.sdit.Lectio`) that reads the bundle. |

**The pipeline → bundle → app contract.** `pipeline/model.py` dataclasses define the JSON shape;
`app/Lectio/Models.swift` is the Swift mirror. They must stay in sync. Every readable unit is a `Segment`
with a frozen, deterministic ID (`<editionId>.<sectionSlug>.seg-NNNN`) that highlights, notes, and saved
words anchor to — never reorder published content.

## Building

Build the content bundle (no dependencies; caches sources to `pipeline/.cache/`):

```sh
python3 -m pipeline.build
```

Generate and build the app (needs [XcodeGen](https://github.com/yonaskolb/XcodeGen); the `.xcodeproj` is
generated, not committed):

```sh
cd app
xcodegen generate
xcodebuild -project Lectio.xcodeproj -scheme Lectio -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5)' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
```

Run in the simulator (the debug hook opens straight into the reader):

```sh
xcrun simctl install booted app/build/Build/Products/Debug-iphonesimulator/Lectio.app
SIMCTL_CHILD_LECTIO_OPEN_WORK=work.marcus-aurelius.meditations \
  xcrun simctl launch --terminate-running-process booted com.sdit.Lectio
```

## Adding a book

Adding a work is writing a *recipe*: generic modules (`normalize`, `segment`, `adapters`) stay dumb, while
per-book editorial decisions (heading patterns, metadata, which trailing apparatus to cut) live in a
function in [`pipeline/recipes.py`](pipeline/recipes.py). The `meditations()` recipe is the template, and
there's an `/ingest-book` skill that walks the whole flow.

## Design language

The app's design language is **"The Margin"**: a warm parchment palette, serif reading text, one
rubrication-red accent. The signature element is the right-hand **margin rail** holding the living layer —
people, definitions, connections, saved words, reading progress — so context lives beside the text and the
reading column stays calm.

## Status

Foundation and multi-edition reading are shipped (Meditations with the Modern Edition placeholder, George
Long 1862, Méric Casaubon 1634, and the Greek original; the Margin; word save). Current corpus in the
bundle: Meditations, The Iliad, The Odyssey, and The Aeneid. Next up is fuller enrichment and the
deep-research Modern Edition production process. See [BIBLE.md §9](BIBLE.md) for the full roadmap.

---

Part of the [San Diego Institute of Technology](https://sandiegotech.org) ecosystem.

## Rights

The app, pipeline, and print tooling are MIT-licensed. The Lectio Editions,
annotation dictionaries, enrichment, and cover art in `content/` are
CC BY-NC 4.0 — free to read, share, and teach from with credit; commercial
rights reserved to the San Diego Institute of Technology, whose printed
editions fund the work. The public-domain texts in the bundle remain public
domain. See [LICENSE.md](LICENSE.md).
