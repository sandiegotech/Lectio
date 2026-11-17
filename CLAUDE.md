# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**Lectio** — an iPad-first reader whose goal is to let anyone today read a great work of the Western canon
(the Harvard Classics) with ease. The headline feature is the **Lectio Modern Edition**: a fresh, plain-modern-
English edition of each work produced by deep research, read by default — with one tap to any public-domain
translation or the original language. The bundle holds 17 works; V1 ships whichever have cleared review (`PLAN.md` §1).

One text, three editions of it — the reader, the printed book, the recording — all anchored to the
same segment ids:

| | | |
| --- | --- | --- |
| `pipeline/` | offline Python; turns public-domain books into the content bundle | committed |
| `content/` | the generated bundle — **the app's input, and the source every edition reads** | committed |
| `app/` | the SwiftUI app (target `Lectio`, bundle `org.sandiegotech.Lectio`) | committed |
| `print/` | the printed editions: one generator, cover engine, cover masters | committed; `print/out/` is not |
| `audio/` | recordings: manifests and scripts only, never media (see `audio/README.md`) | committed |
| `tools/` | dev utilities that belong to no edition (`overnight/`) | committed |

**Media never enters git.** Audio (100–400 MB per work) lives in object storage; `.wav/.m4a/.mp3`
and `audio/**/media/` are gitignored. What git holds is text: code, the bundle, manifests, SVG
cover masters.

Product vision is in `BIBLE.md`; content/data design is in `CONTENT_PIPELINE.md`. Read those before large changes.

## Commands

Build the content bundle (stdlib only, no deps; caches sources to `pipeline/.cache/`):
```
python3 -m pipeline.build
```

Content status board — what's ingested, which works have covers, which have a complete
Lectio (Vernacular) edition + the model/date that produced it (`CATALOG.md`, generated):
```
python3 tools/catalog.py
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
  xcrun simctl launch --terminate-running-process booted org.sandiegotech.Lectio
xcrun simctl io booted screenshot /tmp/shot.png
```

There is no test suite yet.

## Architecture & invariants

**The pipeline → bundle → app contract.** `pipeline/model.py` dataclasses define the JSON shape; `app/Lectio/Models.swift` is the Swift mirror. These must stay in sync — change one, change the other. The bundle layout (`manifest.json` → `works/<id>/work.json` + `editions/<short>.json`, `collections/`, optional per-work `enrichment.json`, `dictionary/`) is documented in `CONTENT_PIPELINE.md §7`.

**Stable segment IDs are frozen.** Every readable unit is a `Segment` with an ID like `<editionId>.<sectionSlug>.seg-NNNN`. IDs are deterministic from content order; `pipeline/idledger.py` records them in `content/.idledger.json` and the build flags drift. Never reorder published content — highlights, notes, the alignment spine, and saved words all anchor to these IDs.

**Provenance is mandatory.** Every `Edition` (and later, media) carries a `Provenance` record; `publish.validate()` rejects editions without one. AI-generated content must record model + source edition. This is a product principle (honesty), not just bookkeeping.

**Adding a book = a recipe.** Generic modules (`normalize`, `segment`, `adapters`) stay dumb; per-book editorial decisions (heading patterns, metadata, which trailing apparatus to cut) live in a function in `pipeline/recipes.py`, appended to `RECIPES`. See the `meditations()` recipe as the template. (There is an `/ingest-book` skill that walks this.)

**The alignment spine** (`CONTENT_PIPELINE.md §4`) is how multiple translations stay in register: each `Work` declares a `referenceScheme` (e.g. Homer = `book.line`) and segments carry a `spine` range. Implemented in `pipeline/align.py` (stage 5, runs inside `build.py` for every multi-edition work): canonical unit tables (Iliad/Odyssey/Aeneid line counts, NE chapters, Hamlet scenes; Meditations derives section counts from the bundled Greek; Dante is canto-per-section) allocated proportionally across each edition's body segments — apparatus (Pope's "ARGUMENT.", Butler's summaries) gets no spine. v1 is proportional, refined in-app by shared proper nouns; exact line capture can replace the tables later without changing the contract. The app matches by spine overlap (`spineMatch` in `ReaderView.swift`) for Compare and for resolving bookmarks/highlights across editions, falling back to positional+noun heuristics for unaligned works.

**AI is swappable, never a direct call.** `pipeline/ai/provider.py` defines the pipeline-side seam; planned backends are Apple Foundation Models (on-device, free), Gemma (offline pack), and Claude API (paid "Philosopher" tier). In the app, the one shipped AI feature is **the Docent** (`app/Lectio/Docent.swift`): the in-margin reading companion, backed by Apple's on-device model (FoundationModels, iOS 26+, Apple Intelligence hardware only). It goes through the `DocentProvider` capability layer — `AppleDocent` today, Gemma/Claude conform later. Answers are grounded in the anchored passage + the enrichment sidecar (glossary hits, passage notes, chapter overview), never the model's own memory; the UI labels every answer AI-generated. On unsupported devices the feature hides entirely.

## App specifics

- SwiftUI, iOS 17+, `SWIFT_VERSION = 5.0` (Swift 5 language mode), iPhone and iPad.
- Design language is **"The Margin"**: warm parchment palette in `Theme.swift` (day and night), serif text (`.system(design: .serif)`, no bundled fonts), one rubrication-red accent.
- **Home** (`Views/LibraryView.swift`) has three sections. **My Books**: the books this reader has opened, most recent first and featured large; a first launch shows one starter book (`StarterBook.workId`, Meditations) as a presentation rule, not a saved position. **Library**: every released work on shelves, sorted by Timeline, Genre, Collection (series collections, readable works only), Title or Author. **Explore** (`Views/ExploreView.swift`): one famous line per page from a readable book, with "Read this passage". A red ribbon on a cover shows reading progress.
- Opening a book from My Books, "Read now" or Explore plays the cover-opening animation (`Components/BookOpening.swift`, an overlay above the NavigationStack); DEBUG hooks push straight in.
- **No placeholders.** Collections' `planned` shells stay decodable in `Models.swift` but nothing displays them. A work with `releaseDate` (YYYY-MM-DD) later than today is hidden; `Library.refreshReleases()` re-checks at midnight and on foreground.
- The book overview (`Views/BookOverviewView.swift`) lists every edition (labels from `EditionInfo.label`, shared with the reader's menus). The reader (`Views/ReaderView.swift`) has a right-hand drawer (Docent · Compare · About; a bottom sheet on iPhone), a centered chapter dropdown, bookmarks in a header menu, and a five-step text size in About.
- Personal data (reading places, saved words keyed by work + term, highlights and notes) goes through `CloudStore`: the local copy is authoritative, iCloud key–value storage is a mirror, and a newer cloud value is adopted only from the change notification.
- The content bundle is a folder reference (`../content` in `project.yml`), read via `Bundle.main.url(..., subdirectory: "content")` in `Library.swift`. Edition texts decode lazily; `Library.edition` is lock-guarded so word study and the opening animation can decode off the main thread.
- **Cover assets.** The SVG is the master: `print/covers/<slug>.svg`, built by `print/covers/build_covers.py`. `content/works/<id>/cover.jpg` is generated from it (`print/covers/export_app_covers.py`) because SwiftUI has no runtime SVG decoder; the raster each cover is traced from lives in `print/covers/source/<workId>.jpg` — **never trace `content/.../cover.jpg`**. Planned-shelf covers (`content/collections/book-covers/`) are not shown in V1, and `project.yml` strips them from the app bundle.
- **Delivery is not decided.** Today the whole text bundle ships inside the app; audio (100–400 MB per work) must never be bundled. The candidate is Apple-hosted asset packs (Background Assets, iOS 26+); Cloudflare R2 is the fallback. Do not build a server for this without a reason.
- `enrichment.json` per work feeds the reader's margin and is hand-authored editorial seed; the pipeline does not overwrite it.
- **The Docent** lives in the reader's drawer (`SidePanel.ask` in `ReaderView.swift`, UI in `Views/DocentPanel.swift`) and in the selection card ("Ask"); it hides where the on-device model can't run. Its name is one constant (`DocentFeature.name`).
- **DEBUG hooks** (env vars with the `SIMCTL_CHILD_` prefix; none compile into Release): `LECTIO_OPEN_WORK=<workId>`, `LECTIO_DEBUG_BOOK=<title>`, `LECTIO_DEBUG_LIBRARY`, `LECTIO_DEBUG_EXPLORE`, `LECTIO_DEBUG_FIRST_LAUNCH`, `LECTIO_DEBUG_SEARCH=<q>`, `LECTIO_DEBUG_SEED_READING=<workId>`, `LECTIO_DEBUG_ALL_RELEASES`, `LECTIO_DEBUG_STUDY=<workId>|<term>`, `LECTIO_DEBUG_CONCEPT=<id>`, `LECTIO_DEBUG_EDITION=<editionId>`, `LECTIO_DEBUG_SELECT=<word>`, `LECTIO_DEBUG_COMPARE` (+`_SYNC`), `LECTIO_DEBUG_PROVENANCE`, `LECTIO_DEBUG_CONTEXT`, `LECTIO_DEBUG_SEED_MARKS` (+`_NOTE_EDITOR`), `LECTIO_DEBUG_DOCENT` (+`_ASK=<q>`, `_MOCK`), `LECTIO_DEBUG_PREVIEW`, `LECTIO_DEBUG_DARK`, `LECTIO_DEBUG_BOTTOM`.
