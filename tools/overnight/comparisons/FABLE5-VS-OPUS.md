# Fable 5 vs Opus 4.8 — Meditations Book I, blind re-translation

_July 2026. Method: a Fable 5 agent re-translated Meditations Book I from the same
sources as the shipped Opus 4.8 Lectio edition (Long 1862 as literal floor, Casaubon
1634 and the Greek for cruxes), under a **blind condition** — it never saw the Opus
rendering. Full Fable output: [fable5-meditations-book1.json](fable5-meditations-book1.json).
The shipped Opus text is Book I of `content/works/work.marcus-aurelius.meditations/editions/lectio-modern.json`._

## Verdict

**Fable 5 is a clear upgrade on fidelity and texture; Opus 4.8 is marginally smoother
for a first-time reader.** Fable found two outright fidelity problems in the shipped
Opus text, restored several concrete details Opus generalized away, kept the Greek's
ledger form, and documented its choices — while staying fully modern and readable.

## Evidence

**Fidelity errors in the shipped Opus Book I** (both verified against Long and the Greek):

1. **I.17 — wrong person.** Greek/Long: *"my grandfather's concubine."* Opus: *"my
   father's mistress"* — wrong relative, softened word. Fable: correct.
2. **I.16 — dropped clause.** Long: *"he had overcome all passion for boys"* (in the
   Greek). Opus omits the clause entirely. Fable renders it: *"He put an end to the
   affairs with boys."* Opus also drops the Lorium/Lanuvium clothing lines and the
   Tusculum toll-collector sentence from the same entry.

**Concreteness.** Opus generalizes; Fable keeps Marcus's actual particulars:

| Greek/Long | Opus 4.8 | Fable 5 |
|---|---|---|
| Greens/Blues, short shields/long | "the racing teams… rival gladiators" | "neither the Greens nor the Blues… neither the short shields nor the long" |
| ἀκύβευτον (the dice metaphor) | "steady purpose" | "a steadiness of purpose the dice of fortune cannot touch" |
| ἀόργητον (I.1) | "keep my temper under control" | "freedom from anger" (the absence, not the struggle — the Stoic point) |

**Form.** Long's Book I has 20 segments. Fable mirrors them 1:1 (17 ledger entries +
Long's two editorial notes recast as modern editor's notes + the "Among the Quadi"
subscription) — which the alignment spine rewards. Opus ships 17, silently dropping
the apparatus and the subscription.

**Scholarship.** Fable logged 3 reasoned divergences (ἀόργητον; στοργή in Fronto's
barb; dropping Long's interpolated "brother" before Severus — he is almost certainly
Claudius Severus the Peripatetic) plus a translator's note. This is the provenance
posture the BIBLE asks for.

**Where Opus is better.** Its fuller sentences ("From my mother, I learned reverence
and generosity…") are a touch easier on a reader meeting Marcus for the first time;
Fable's compressed ledger ("From my mother: reverence for the gods; generosity…")
asks slightly more. Opus's smoothness, though, was partly purchased with the
generalizations above.

## Implications

- The four editions now being produced (Confessions, Analects, The Prince, Republic)
  are Fable 5 — good.
- The eight Opus-era editions are candidates for a **Fable 5 re-vintage** (the BIBLE's
  vintage mechanism anticipated exactly this). Worth prioritizing Meditations, given
  the two Book I findings above. Human review gate still applies to everything.
