# Lectio — the plan

Written 2026-11-17. `BIBLE.md` says what Lectio is. This says what happens next, and where
things live. It has seven parts: V1, the editions, releases, models and vintages, print,
the website, and spare tokens.

Three commands show where everything stands:

    python3 tools/release.py          # every book: its stage and its release date
    python3 tools/review/queue.py     # every edition: sections clear, open, unread
    python3 tools/catalog.py          # what is in the bundle (CATALOG.md)

## 1. V1

**What V1 is.** A free reader with a library of about twenty great books, each in a Lectio
edition that has been checked against its sources, with the older translations one tap away.
Nothing in it is a placeholder or a pointer to something unreleased. A new book appears
every week.

**When.** As soon as Apple approves SDIT's developer account and the launch editions are
fixed. Nothing else is in the way.

### Decided (2026-11-17)

- No "Coming soon" books. The app shows what can be read.
- Three places: **My Books** (what you have opened, most recent first, where the app
  opens), **Library** (every released book, sorted by timeline, genre, title or author) and
  **Explore**. Each book's page lists its editions.
- A red ribbon on the cover marks how far you have read. Opening a book opens its cover.
- No "check out". Opening a book is what puts it in My Books. Bookmarks, highlights, notes
  and saved words stay.
- No link to Gloss. Word study works inside the app as before.
- Bundle id `org.sandiegotech.Lectio`. Version 1.0.
- The app carries each book's release date and shows the book from that day (part 3).

### Done (2026-11-17)

- All 17 drafted editions reviewed, the fixes verified and applied (2,208 entries), each
  work made consistent within itself, its edition notes brought into line, and stamped
  "revised 2026-11-17". Nine segments that were editor's notes are marked `omit`.
- The bundle rebuilt: 17 works, every segment id unchanged.
- The app rebuilt around My Books, Library and Explore, with no placeholders.

### Left to do, in order

1. **The editor's read.** Each work's `review/2026-11-17/<slug>/rejected*.md` ends with what
   is left for the editor: a few passages to restore, a few rulings, glossary entries for
   explanations that were taken out of the text. Meditations first. Then
   `python3 tools/release.py approve <slug>`.
2. **One house style across works.** Each work is now consistent, but they differ from each
   other: the Homer uses typographic quotes, most others straight. Rule: typographic quotes
   and apostrophes, closed-up em dashes, American spelling, in every Lectio edition. One
   scripted pass, then rebuild.
3. **Finish the launch shelf.** Genesis 35–50, *The Art of War*, Epictetus and Plato's
   *Apology, Crito & Phaedo* are drafted in `drafts/`. Each needs ingest, integration and its
   review before it joins the shelf. Genesis is held out of the app until then. The three
   Eastern works have interim covers taken from the shelf art; give them proper masters.
4. **Store side**, the day Apple approves:
   - team id into `app/project.yml`; register the bundle id; create the app record
   - privacy policy and support pages on sandiegotech.org (both URLs are required)
   - App Privacy: no data collected. Age rating. Category: Books, then Education.
   - screenshots (iPad 13", iPhone 6.9") from the debug hooks; name, subtitle, description
   - review note: books appear on their release dates; say so plainly
5. **TestFlight** for a week with a handful of readers, on the smallest iPhone as well.
6. **Submit.**

### Not in V1

Audio, accounts, downloads on demand, the Lexicon, other languages, the cloud Philosopher.
All stay in the bible. None ships until V1 is live and being read.

## 2. The editions

Every edition goes through six stages. The first four are machine work. The fifth is the
editor's and cannot be delegated.

| Stage | What happens | Where |
|---|---|---|
| ingest | Public-domain base texts and the original into the bundle | `/ingest-book`, `pipeline/recipes.py` |
| draft | The Lectio rendering, section by section, on a branch | `tools/overnight/RUNBOOK.md` |
| review | Each section read against its sources; a graded report | `review/METHOD.md` |
| fix | Each finding re-checked; confirmed fixes written as a patch | `review/METHOD.md`, Verify |
| read | The editor reads the patch, strikes what he does not want | `review/<run>/<slug>/patch*.json`, `rejected*.md` |
| ready | Patch applied, bundle rebuilt, book approved | `tools/review/apply.py`, `tools/release.py approve` |

### What the first review found (2026-11-17)

All 17 drafted editions were read, about a million words. No section needs redoing. Of 442
sections, 212 graded A and 230 B. There were 51 errors of meaning, about 480 medium
faults, and roughly twice as many small ones. The same five causes account for most of them:

1. **The base translator's apparatus printed as the author.** Footnotes, bracketed glosses
   and editor's notes carried into the text: Long's note on Homer as Marcus's words; a
   "[Trans. note]" inside the Muses' speech in the *Republic* and at the end of *Iliad* XXIII.
2. **Drafted from the English base, not the original.** Where the base was wrong or coy, so
   was the draft: Marcus's grandfather's mistress became his father's; Antoninus was tidied.
3. **No style sheet.** Each section was drafted alone, so names, key terms, oaths and quote
   marks change from book to book: four English words for temperance in the *Ethics*, three
   for the aegis in the *Odyssey*, "virtù" kept in some chapters and translated in others.
4. **Explanation written into the sentence.** A gloss after a name, a moral after an ending.
5. **Single words in the wrong register.** "Girlfriend", "the haves", "for free" on one side;
   "car" for chariot, "chine", "yonder" on the other.

### What changes in the method

- **A style sheet before the first section.** Names, the dozen key terms, oaths, quote and
  verse style, what stays in the original language. Every drafter and reviewer reads it.
  The policies the verifiers wrote tonight (top of each `rejected*.md`) are the first ones.
- **Draft from the original**, with the public-domain translation as a control, not a base.
  Bundle the original for every work, so review can check against it instead of from memory.
- **A mechanical gate in the build**: no brackets or "Trans. note" in a Lectio segment, one
  quote style per work, no markdown, last segment of each section matched against the base.
- **Editorial segments.** A few segments are wholly invented and cannot be deleted, because
  ids are frozen. Add a `kind: "omit"` the app, print and audio skip.
- **Line breaks inside prose.** Quoted verse and the poems in Genesis are flattened by the
  build. Let a paragraph keep its newlines.

### The editor's part

For each book: open `rejected*.md` for the policies and the "Needs the editor" list, skim
`patch*.json` (high and medium first), delete entries you do not want, then:

    python3 tools/review/apply.py <slug>
    python3 -m pipeline.build
    python3 tools/release.py approve <slug>

A short work is an hour. An epic is an evening. Meditations first.

### Other languages

Spanish first. A translation starts only from an edition that is **ready**, is made from the
original with the Lectio English as the guide to register, and needs its own reader, a native
speaker, at the read stage. It is a new edition of the same work, same segment ids, same
provenance rules. *Meditaciones* is already set as a print proof; finish it after V1 as the
trial of the whole method. No second language until the first has a reader.

## 3. Releases

**The register** is `catalog/books.json`: every book Lectio intends to publish, 219 of them,
in release order. It holds only what a person decides: the order, the release date, whether
the editor has approved it, and its print record. `tools/release.py` reads the rest from the
repo and writes `catalog/RELEASES.md`.

**Launch**: 20 books. **Then one book every Monday**, from 2027-01-04, announced in the
newsletter. The first twelve weeks are dated; the rest of the register follows in order.
Short works come first so the weekly rhythm is real before the long ones are attempted.

**How a book gets out.** The bundle carries each work's release date; the app shows the work
from that day. So books do not need an App Store release each: one app update a month
carries the next four or five finished books, and each appears on its Monday. A book is put
in an update only when it is **ready**. If it is not ready, it does not go in, and the next
one moves up (`tools/release.py hold <slug>`, then `schedule`).

**The weekly routine.**

| Day | What |
|---|---|
| Any | Burn run drafts, reviews and patches the books four to six weeks out |
| Weekend | Editor reads one book's patch; it becomes ready |
| First week of the month | App update with the next month's ready books goes to review |
| Monday | The book appears in the app; its page goes up on the site; the newsletter carries it |

The newsletter piece is short: what the book is, why read it now, one passage from the
Lectio edition, the link. It is drafted from the book's own introduction and divergence notes
(`internal/daily/draft.py`), and the editor rewrites it in his own voice.

**Being four weeks ahead is the whole discipline.** Twenty at launch plus twelve dated means
the first book that has to be drafted from scratch on a deadline is due in January.

## 4. Models and vintages

**Which model.** The first review gives a measurement, not just an opinion. Serious and
medium faults per 10,000 words of draft, by the model that drafted it:

| Drafted by | Works | Faults per 10k words | Errors of meaning per 100k words |
|---|---|---|---|
| Opus 4.8 (June 2026) | 11 | 6.3 | 6.8 |
| Fable 5 (July 2026) | 4 | 2.1 | 1.4 |

The works differ, so this is suggestive, not proof. But the stronger model made about a
third as many faults and a fifth as many errors of meaning, and those errors are the ones
that matter: a reversed subject, a pronoun on the wrong person. So:

- **Draft with the best model available** (Fable 5.2 now). Drafting is done once per work
  and read by everyone after. It is the wrong place to save.
- **First review on Opus.** It is close reading against a source, it parallelises, and it
  found real errors tonight at a small fraction of the week's allowance.
- **Fix (verify) on the best model**, for the works that matter most. It decides what prints.
- The method changes in part 2 are worth more than any model change. Do both.

**One edition, stamped, with revisions.** Not a new edition every year by the calendar.

- An edition carries a **vintage** (the year it was drafted) and a **revision date**. Fixes
  from review are revisions: same vintage, new revision date, each change logged.
- A **new vintage** is a full redraft, and it is made only when it is measurably better: a
  trial redraft of three sections, reviewed blind against the current text, has to win on
  faults per 10k words and on the editor's own reading. Otherwise the current edition stands.
- Old vintages are archived with their provenance and stay citable. Print carries vintage
  and revision on the colophon.
- Try the trial once a year, when a new model generation arrives. Some years nothing changes.

## 5. Print

The Meditations proof shows the form is right: 5.5 × 8.5, the app's serif, the apparatus at
the back. `print/build_book.py` sets any edition from the bundle, so print costs almost
nothing once an edition is ready. What print adds is a harder gate: a book cannot be patched.

1. **Only a ready edition prints.** Then the editor reads the proof on paper, start to
   finish, and signs the colophon. That reading is the last revision before print.
2. **Meditations first**, after its patch is applied: cover from the SVG master, ISBN,
   KDP paperback, one proof copy in hand before it goes on sale.
3. **Then one print edition a month**, following the app by about eight weeks, shortest
   works first: Tao Te Ching, The Prince, Dhammapada, Analects, Gita, then the epics.
4. **Record it in the register**: `print: {status, isbn, date, revision}`.
5. **The PDF is free on the site** (part 6). The bound book is what is sold.

Decisions the editor owes: the imprint name on the spine, who holds the ISBNs (SDIT should),
and the price rule. IngramSpark comes later, for bookstores and libraries.

## 6. The website

A page for every book on sandiegotech.org, generated from the register and the bundle, so
the site, the app and the printed book cannot disagree.

- `sandiegotech.org/lectio/` — the library: released books, and the dated ones coming.
- `sandiegotech.org/lectio/<slug>/` — one book: what it is, the opening of the Lectio
  edition, the editions on hand, the free PDF, the link to the app, the printed book.
- `sandiegotech.org/lectio/<slug>/edition/` — how this edition was made. This is where the
  detail goes: model and vintage, sources, the style sheet, every divergence with its reason,
  the review record (sections read, faults found, fixes made, findings rejected and why),
  and the revision log. The review files already hold all of it.
- `sandiegotech.org/lectio/method/` — the method itself, once, plainly.

Each page carries Book schema markup, a canonical URL and a sitemap entry. The reading text
itself stays in the app and the PDF; the page shows an opening passage, enough to find and
judge, not a second reader to maintain.

Build it as `tools/site.py` writing into `../website/lectio/`, run with the monthly bundle
rebuild, deployed with the site's own `infra/deploy.sh`. Start with the launch shelf.

Built 2026-11-17: `python3 tools/site.py --check` writes `/lectio/`, `/lectio/mission/` and a page
per book, then verifies them. Hand-written copy is in `catalog/pages/`; the rest is derived.
For now the method page is `/lectio/mission/` and each book's edition detail is on its own page.
Since 2026-11-17 it also writes, for every page: search title and description (`seo` in the page
file), linked data, a share card, `index.md`, and for editions `edition.json`; and once: `feed.xml`,
`editions.json`, `/llms.txt`, `/llms-full.txt`. A new book gets all of it from its page file.

## 7. Where things live

    BIBLE.md  PLAN.md  CLAUDE.md      what it is · what is next · how to work here
    catalog/                          the register and the release schedule
    pipeline/                         public-domain sources → the bundle
      modern/                         the Lectio editions' source text (edit here, not content/)
    content/                          the bundle: generated, committed, read by everything
    review/<run>/<slug>/              reports, patches, policies, findings rejected
    app/                              the reader
    print/                            the book
    audio/                            recordings: manifests only
    tools/
      release.py  catalog.py          the release desk · the bundle's status board
      review/                         section.py · queue.py · apply.py
      overnight/                      the drafting loop and the Bible charter
    backup/                           local safety copies; not committed

One rule keeps it clean as it grows: a person edits `catalog/`, `pipeline/` and the app;
everything in `content/`, `CATALOG.md` and `catalog/RELEASES.md` is written by a tool.

## 8. Spare tokens

The weekly allowance resets Tuesday at 4:00 AM Pacific. What is unused then is gone.

**What the first run showed.** Reading and patching every drafted edition, about a million
words, with twenty Opus readers at once, used about a tenth of a week. Review alone will
never use the allowance. Drafting will: it is the expensive stage and the one the weekly
release depends on.

**The burn run.** Tuesday 12:30 AM to 3:45 AM, app open. Check usage first; run only if the
week is under 85%. Then, in this order:

1. Fix: verify open sections and write patches (`tools/review/queue.py --json N`).
2. Review: unread sections of drafted works.
3. Draft: the next undrafted books in the register, on the `overnight-vernacular` branch,
   style sheet first, per the overnight runbook. This is where the tokens go.
4. Ingest: sources and originals for the books after those.

**Rules.** A burn run writes reports, patches, and drafts on a branch. It never edits a
published edition on `main`, never applies a patch, never pushes to `main`. One agent per
work or half-work, writing a file per section so a stop loses nothing. Twenty agents is the
ceiling. Stop at 3:45 AM or at 95% of the week. End with `review/<run>/RUN.md`: usage at
start and end, what was done, what failed.

**During the week.** Keep a tenth of the allowance as a floor for ordinary work. If Monday
evening shows more than a third unused, start the run early rather than larger.
