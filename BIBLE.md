# Project Bible — Lectio

> *Lectio* (Latin: "a reading"). The goal is simple and ambitious: **let any person today read a great
> work of the Western canon — any of the Harvard Classics — with genuine ease.** Built for iPad first,
> then iPhone and Mac.

---

## 1. The North Star

The greatest books ever written are free and in the public domain — and almost nobody reads them. Not
because people aren't capable, but because the on-ramp is brutal: archaic translations, no context, dense
walls of text, names and references that assume a 1900 classical education. Existing reading apps (Kindle,
Apple Books) just hand you the same forbidding 1909 file and wish you luck.

**Lectio removes the friction.** Open *The Iliad* or *Meditations* and you get a clear, modern, readable
version by default — then, the moment you're curious, you can hold it against any historical translation or
the original language, with the people, words, and ideas explained right beside the text. The measure of
success: *a smart, busy person with no classics background finishes a great book and feels it was easy and
worth it.*

---

## 2. The Flagship: the Lectio Modern Edition

The headline feature, and the thing only we do: **a fresh, plain-modern-English edition of each work,
produced by deep research.** This is what makes a daunting classic feel like a great book you can actually
read today.

**What it is.** A faithful rendering of the work into clear contemporary English — the sense and force of the
original, in the language people actually read now. Not a dumbed-down summary; a real, readable edition.

**How it's made (the deep-research process).** For each section we:
1. Gather *all* available material: every public-domain translation, the original-language text, and all
   relevant scholarship — modern translations (Wilson, Fagles, Lattimore), academic commentaries, critical
   editions, and the ancient scholia. Copyrighted works are research inputs, not reproduced content:
   copyright protects expression, not facts or ideas. What scholarship says about a passage can be
   synthesized and cited; the text of a copyrighted translation cannot be included.
2. Research the passage: what it means, where translators diverge, what context a modern reader is missing,
   what the best scholarship has established.
3. Produce a modern rendering synthesized from the full scholarly record — faithful to the original, informed
   by every serious reading of it, expressed in original language.
4. **Human review gate** before publish — checked against sources, flagged where the text is interpretive.

**Provenance is a first-class feature, not fine print.** Every Lectio Modern Edition carries a full
provenance record:
- **Model** — the AI model used (e.g., *claude-sonnet-4-6*)
- **Date produced** — when this edition was generated (e.g., *June 2026*)
- **Sources consulted** — the scholarship and editions that informed it, cited by name
- **Method** — a plain-language description of the deep-research process above

The reading surface shows only "Lectio Modern Edition." The full provenance record is one tap away and
included in any exported PDF. It is **never** passed off as a historical translation.

**Editions have vintages.** As models improve, the Lectio Modern Edition can be regenerated — producing a
2026 edition, a 2028 edition, and so on. The current edition is always the default. Older vintages are
archived with their original provenance intact: the 2026 edition with claude-sonnet-4-6 remains a permanent,
citable record. Readers who care about consistency (students citing a passage) can pin to a specific vintage.

**It's the default, not the only option.** You read the Modern Edition by default; one tap switches to any
public-domain translation (Pope, Butler, Long, Casaubon…) or the original language. *Accessibility by
default, depth on demand.*

---

## 3. Read Any Version (already built)

Every work carries multiple **editions**: the Lectio Modern Edition, every public-domain translation we can
source, and the **original-language** text. The reader has an edition switcher: latest/most-readable first,
the original last. Switching keeps your place (same book/chapter across editions).

Each edition carries a **provenance card** shown in the switcher and available in full on export:

| Edition type | Label | Provenance shown |
|---|---|---|
| Lectio Modern Edition | "Lectio Modern Edition · 2026" | Model, date, sources consulted, method |
| Historical PD translation | "Alexander Pope · 1715" | Translator, year, source (e.g. Standard Ebooks) |
| Original language | "Greek original" | Source edition (e.g. Wikisource) |

The reading surface stays clean — translator + year is enough. The full record (for Lectio editions: which
model, which scholarship informed it; for historical editions: which digitization source) lives one tap away
and in any exported PDF. Students citing a passage pin to a specific vintage; the citation includes the
edition, vintage year, and model.

*Status: shipped for Meditations (George Long 1862, Méric Casaubon 1634, and the Greek original).*

---

## 4. The Margin — comprehension beside the text

The signature UI ("The Margin"): the reading column stays calm while a quiet right-hand **rail** carries the
living layer — tap a word for its definition, see the people in the passage, the connections to other works
and ideas, your saved words, and your reading progress. This is where context lives so the text doesn't have
to be interrupted. (Later: the full connection graph, art per scene — see §7.)

*Status: shipped — tap-to-explore words, save words, editorial enrichment per passage.*

---

## 5. The Corpus — start with 3 works, get it right

We prove the whole experience (Modern Edition + multi-translation + Margin) on **three great works** before
scaling to the rest of the Harvard Classics:

1. **Meditations** — Marcus Aurelius (Stoic philosophy). *In progress.*
2. **The Iliad** — Homer (epic poetry; the multi-translation showcase: Pope's couplets vs. Butler's prose).
3. **Plato or Aristotle** — a foundational philosophical work. Recommended: **Plato's *Apology / Crito /
   Phaedo*** (the trial and death of Socrates) — short, gripping, and far more approachable than Aristotle
   for a first reader. (Both are in Harvard Classics Vol. 2 alongside Meditations.) *Decision pending.*

Getting these three right — especially the Modern Edition quality — is the whole game. Breadth comes after.

---

## 6. Sourcing & Rights (the discipline)

| Layer | Source | Rights posture |
|---|---|---|
| Public-domain translations | Standard Ebooks, Project Gutenberg, Wikisource | PD; redistributable; included in app |
| Original-language texts | Wikisource, etc. | PD; included in app |
| **Lectio Modern Edition** | AI synthesis from all available scholarship | Ours; provenance = model + date + sources cited |
| Modern in-copyright translations (Fagles, Wilson, Lattimore…) | Research input only | **Never reproduced**; cited as source in provenance |
| Copyrighted scholarship (Knox, Graziosi, academic papers…) | Research input only | **Never reproduced**; synthesized and cited |
| Annotation dictionary | AI synthesis from full scholarly record | Ours; each entry cites its sources |
| Dictionary | Webster's 1913 (PD) | PD; fallback for unannotated words |
| Art (later) | Museum open-access, Wikimedia Commons | PD / CC0 |

**The reproduction / synthesis distinction.** Copyright protects expression, not facts or ideas. Modern
translations and scholarly commentary are research inputs — the pipeline reads them, synthesizes their
insights, and cites them; it never reproduces their text. The output (Modern Edition, annotation entries)
is original expression informed by the full scholarly record. This is the same thing a human researcher does.

**Rule:** every piece of content carries a provenance record or it doesn't ship.

---

## 7. Beyond the MVP (the depth layer)

The connection graph ("Connect Gloss"): works, people, places, ideas, and artworks as linked nodes — walk a
work's influences and descendants, jump between every author on a theme, see the art a scene inspired. The
Margin is already the surface for this; the graph fills it in. Shared with the sibling app **Gloss**.

---

## 8. Ecosystem, AI & Business Model

**Ecosystem.** Lectio is one of several apps sharing an account-level identity and a tuned AI ("the
Philosopher") with the sibling app **Gloss**. Lectio *consumes* these; it doesn't own them.

**AI strategy (swappable, deferred).** The pipeline ships no live AI; the Modern Edition is produced offline
and reviewed, then served as static, finished content. Runtime comprehension aids route through a capability
layer with interchangeable backends:
- **Apple Foundation Models** — on-device, free, offline; light aids (define, recap, simplify) where hardware allows.
- **Gemma (MLX)** — later optional offline pack.
- **Claude API** — the cloud tuned "Philosopher"; highest fidelity, cross-app, any device.

**AI cost architecture — pre-generate, don't stream.** The goal is near-zero per-user API cost. The way to
achieve it is to treat AI generation as a pipeline responsibility, not a runtime one:

1. **Annotation dictionary per work.** For each text the pipeline runs a generation pass — feeding the AI
   the full available scholarship (PD translations, modern translations as research, academic commentaries,
   the ancient scholia) — to produce ~300–400 annotation entries: proper nouns (Achilles, xenia, the
   Furies), recurring concepts, and high-frequency allusions a modern reader will stumble on. Each entry
   cites the sources it synthesized from. Entries are generated once, human-reviewed, and committed to
   `content/` as static data alongside the text. Tap-to-explore resolves against this dictionary first.
2. **Webster's 1913 fallback.** Any word not in the annotation dictionary falls through to Webster's 1913
   (public domain, already in the plan). No API call.
3. **On-device for the rest.** Anything genuinely unanticipated — an arbitrary tap on a word not in either
   dictionary, a quick contextual gloss mid-sentence — routes to Apple Foundation Models. Free, offline,
   no latency.
4. **Live API only for personalized inference.** The only remaining use case for a server-side call is
   something genuinely personalized: a recap of exactly where a specific reader stopped, a custom
   difficulty-dial adjustment on an arbitrary passage. These features can be deferred until there is a
   student cohort and an institutional API budget to support them, or gated behind an SDIT account.

The pre-generated annotation dictionary is the better product anyway — a student tapping "xenia" should get
a considered, edited definition, not whatever the model generates cold that afternoon. The pipeline
produces quality; the device handles edge cases.

**Business model — SDIT subscription.**
- **Free** — read any public-domain edition + the original, the Margin's basic aids, dictionary, saved words.
- **SDIT subscription** — the **Lectio Modern Edition** (the deep-research modern translations) + the cloud AI
  comprehension aids and cross-app intelligence. Tiers: *Student* and *Philosopher*. Login ships from day one.

The split: **public-domain reading is free; the modern, made-for-today experience is the paid value.**

---

## 9. Roadmap

- **P0 — Foundation** *(done)*: pipeline → portable JSON bundle; stable IDs; provenance; iPad reader.
- **P1 — Multi-edition reading** *(done)*: edition switcher; Meditations w/ 3 editions; the Margin; word save.
- **P2 — The 3-work corpus**: ingest Iliad (multiple PD translations) + Plato/Aristotle; fuller enrichment;
  full Webster's 1913 dictionary so every word resolves.
- **P3 — The Modern Edition**: build the deep-research production process; produce + review the Modern Edition
  for the 3 works; ship it as the default edition; account/login + subscription gating.
- **P4 — Depth**: connection graph, art per scene, the 15-min/day Harvard reading path, streaks.
- **P5 — Scale**: the rest of the Harvard Classics; more collections.

## 10. The MVP

**A reader where a newcomer opens one of the 3 works, reads the Lectio Modern Edition with ease, taps a hard
word and gets it, switches to a historical translation or the Greek out of curiosity, and finishes feeling it
was approachable.** Free public-domain reading + the paid Modern Edition, proven on three works.

## 11. Open questions
- Plato vs. Aristotle for work #3 (recommend Plato's *Apology/Crito/Phaedo*).
- How much of the Modern Edition is acceptable to generate vs. how much human review per work.
- Exact free/Student/Philosopher boundaries and pricing.
- Original-language depth (display only, or interlinear/lexical for Greek/Latin).
