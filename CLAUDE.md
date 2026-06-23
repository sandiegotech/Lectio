# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**Lectio** — an iPad-first reader whose goal is to let anyone today read a great work of the Western canon
(the Harvard Classics) with ease. The headline feature is the **Lectio Modern Edition**: a fresh, plain-modern-
English edition of each work produced by deep research, read by default — with one tap to any public-domain
translation or the original language. Initial corpus: **3 works** — Meditations, The Iliad, and Plato/Aristotle.

Three parts:
- `pipeline/` — an offline Python tool that turns public-domain books into a portable JSON content bundle.
- `content/` — the generated bundle (committed; it's the app's input).
- `app/` — the SwiftUI app (target `Lectio`, bundle `com.sdit.Lectio`) that reads the bundle.

Product vision is in `BIBLE.md`; content/data design is in `CONTENT_PIPELINE.md`. Read those before large changes.

## Commands

Build the content bundle (stdlib only, no deps; caches sources to `pipeline/.cache/`):
```
python3 -m pipeline.build
```

Generate + build the app (XcodeGen at /opt/homebrew/bin/xcodegen; the `.xcodeproj` is generated, not committed):
```
cd app
xcodegen generate
xcodebuild -project Lectio.xcodeproj -scheme Lectio -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M5)' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
```

Run in the simulator and screenshot (headless; there's no tap support, so use the debug hook):
```
xcrun simctl boot <iPad-udid>
xcrun simctl install booted app/build/Build/Products/Debug-iphonesimulator/Lectio.app
# Debug hook opens straight into the reader. Env MUST use the SIMCTL_CHILD_ prefix —
# `simctl launch <dev> <bundle> KEY=VALUE` passes KEY=VALUE as an ARGUMENT, not an env var.
SIMCTL_CHILD_LECTIO_OPEN_WORK=work.marcus-aurelius.meditations \
  xcrun simctl launch --terminate-running-process booted com.sdit.Lectio
xcrun simctl io booted screenshot /tmp/shot.png
```

There is no test suite yet.

## Architecture & invariants

**The pipeline → bundle → app contract.** `pipeline/model.py` dataclasses define the JSON shape; `app/Lectio/Models.swift` is the Swift mirror. These must stay in sync — change one, change the other. The bundle layout (`manifest.json` → `works/<id>/work.json` + `editions/<short>.json`, `collections/`, optional per-work `enrichment.json`, `dictionary/`) is documented in `CONTENT_PIPELINE.md §7`.

**Stable segment IDs are frozen.** Every readable unit is a `Segment` with an ID like `<editionId>.<sectionSlug>.seg-NNNN`. IDs are deterministic from content order; `pipeline/idledger.py` records them in `content/.idledger.json` and the build flags drift. Never reorder published content — highlights, notes, the alignment spine, and saved words all anchor to these IDs.

**Provenance is mandatory.** Every `Edition` (and later, media) carries a `Provenance` record; `publish.validate()` rejects editions without one. AI-generated content must record model + source edition. This is a product principle (honesty), not just bookkeeping.

**Adding a book = a recipe.** Generic modules (`normalize`, `segment`, `adapters`) stay dumb; per-book editorial decisions (heading patterns, metadata, which trailing apparatus to cut) live in a function in `pipeline/recipes.py`, appended to `RECIPES`. See the `meditations()` recipe as the template. (There is an `/ingest-book` skill that walks this.)

**The alignment spine** (`CONTENT_PIPELINE.md §4`) is how multiple translations scroll-sync: each `Work` declares a `referenceScheme` (e.g. Homer = `book.line`) and segments carry a `spine` range. Not yet implemented — it's the MVP's signature feature (Iliad translation-compare).

**AI is deferred and swappable.** v1 ships no AI. `pipeline/ai/provider.py` defines the seam; planned backends are Apple Foundation Models (on-device, free), Gemma (offline pack), and Claude API (paid "Philosopher" tier). Wire any AI feature through a capability layer, never a direct call.

## App specifics

- SwiftUI, iOS 17+, `SWIFT_VERSION = 5.0` (Swift 5 language mode), target family iPhone+iPad.
- Design language is **"The Margin"**: warm parchment palette in `Theme.swift` (single `Palette.natural`), serif reading text (`.system(design: .serif)`, no bundled fonts), one rubrication-red accent. The signature element is the right-hand **margin rail** (`Views/MarginRail.swift`) holding the living layer (people, definitions, connections, saved words, reading progress).
- The content bundle is included as a folder reference (`../content` in `project.yml`) and read at runtime via `Bundle.main.url(..., subdirectory: "content")` in `Library.swift`.
- **Cover assets.** Covers ship in `content/` as **compressed JPEGs** (~1400px, q82, ~300 KB each — keeps the bundle ~50 MB instead of ~440 MB). The **high-res PNG masters live OUTSIDE the repo at `~/Documents/Lectio-Masters/`** (mirroring the `content/` path layout) — they are the print-quality source and are *not* committed. To add/replace a cover: drop the high-res original in `~/Documents/Lectio-Masters/...`, then emit the app copy with `magick MASTER -resize '1400x1400>' -background white -flatten -strip -quality 82 content/.../<name>.jpg`. Covers are referenced as `.jpg` in `Library.swift` (`coverURL`, `collectionImageURL`) and `pipeline/collections.py` (`PLANNED_COVERS`). Server-side on-demand download is deferred (Cloudflare R2 when the catalog outgrows a bundled app).
- `enrichment.json` per work feeds the rail and is hand-authored editorial seed; the pipeline does not overwrite it.
