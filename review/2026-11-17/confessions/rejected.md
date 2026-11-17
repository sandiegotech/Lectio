# Confessions · verify 2026-11-17 · policies and rejected issues

Latin checked from the verifier's own knowledge (not bundled); Pusey 1838 from the bundle.

## Policies

- **Quotation marks (mechanical, not patched).** One style for the whole edition: straight double quotes for quotations, straight single quotes only for a quotation inside a quotation, and straight apostrophes. This is what Books I, III, VII, IX and XI already use. Convert Books II, V, VI, XII and XIII (straight single), IV (curly single quotes and curly apostrophes), VIII (curly double and curly apostrophes) and X (curly double). Patch entries keep each book's current marks in `old`/`new`, so they apply cleanly before or after the normalization. The one exception is VI seg-0004, whose `new` already uses double quotes.
- **Manichaean (mechanical, not patched).** Spell it "Manichaean" everywhere, as Book III does. Only Book V seg-0023 differs ("Manichean", twice). "Manichee(s)" for the people stays.
- **Book titles (mechanical, not patched).** Use title case for every book title. Two need changing: Book VII "The unchangeable light" becomes "The Unchangeable Light", and Book X "The palaces of memory" becomes "The Palaces of Memory". The titles sit in the `title` field, not in a segment, so the editor changes them by hand.
- **distentio.** Render it "stretching-out" every time. XI seg-0030 and seg-0033 already do; XI seg-0039 and seg-0041 are patched. In seg-0039 the Latin wordplay distentus / extentus / intentio becomes "stretched out / stretched forward / stretching-forward", so the reader keeps hearing the same stem. XII seg-0021 ("every stretching-out") already agrees.
- **continentia.** Choose the word by its sense. For sexual restraint use "continence": VI seg-0020/0021, VIII seg-0028 (Continence in person), IX seg-0006. VIII seg-0018 is patched from "self-control" so that "Give me chastity and continence, but not yet" matches the figure of Continence who appears ten paragraphs later. For the general virtue of the ordered affections use "self-mastery": X seg-0040/0061, XIII seg-0037, and XIII seg-0048 (patched).
- **Quoted verse.** Mark the line breaks of quoted verse with "\n" inside the segment, which is the same source convention The Prince uses for Petrarch, and leave the wording as it is. Patched: Virgil in VIII seg-0004 and Ambrose's *Deus creator omnium* in IX seg-0033. Note: `pipeline/segment.py` currently joins lines inside a prose paragraph (The Prince's Petrarch already prints as one line), so these breaks will print only once the build honors line breaks within a paragraph. That is a pipeline follow-up and outside this patch.
- **Interjections (ei mihi, vae).** Translate the cry; never drop it or turn it into a description. *Ei mihi* becomes "Woe is me!" and *vae* becomes "woe to …". This matches what the edition already prints in I seg-0004, III seg-0011 and VI seg-0027. Patched: I seg-0025, II seg-0007/0017, VIII seg-0010, IX seg-0035, X seg-0039 (three cries plus the two vae clauses) and XI seg-0032. *Male mihi est* (XIII seg-0009) and *male mihi erat* (IX seg-0029) are not interjections and stay as they are.
- **Single words in the wrong register or modern sense.** Fix each one individually: confirmed cases are in patch.json, and the rejected ones are listed below.

## Rejected

- I seg-0011 · reviewer's "cure it with remedies": rejected. *Expiare* is ritual, so "charm it away" stays. Only the lost shrug (*nescio quibus*) is patched.
- I seg-0010 · reviewer's "finding it out": not used. It replaces one added object with another, so the patch strips the object instead.
- II seg-0007 · reviewer's "Oh, my God!" for *Ei mihi*: rejected. It adds "God" and is not the cry. The interjection policy gives "Woe is me!"
- II seg-0003/0011/0017, IV whole section, VI whole section, XII listed segments · quotation style: handled by the quotation-mark policy, not entry by entry.
- III seg-0016 · subject shift "Iniquity lies to itself … or men stand guilty": rejected. The Latin shifts the same way (*mentitur iniquitas sibi … aut rei tenentur*). Only "loved in the part" is patched.
- III seg-0020 · reviewer's full rewrite: partly used. The patch keeps the printed wording and moves the main clause forward, and does not add "In the dream" or its other new phrasing.
- V seg-0023 · Manichean: handled by policy.
- VII heading, X heading · title case: handled by policy, since a title is not a segment.
- VIII seg-0021 · "the moment I truly willed it, I would will it indeed": rejected. The repetition is Augustine's own (*mox ut vellem, utique vellem*: willing fully is the act), and the reviewer's "completely" would sharpen the paradox into a claim.
- IX seg-0033 · reviewer's reworded hymn ("so rest may give our slackened limbs"): wording not changed. Only the line breaks are added, per policy.
- X seg-0008 · reviewer's "embrace … fullness": rejected. "Fullness" loses the cloying sense of *satietas*, so "satiety" is used and "closeness" is kept.
- X seg-0039 · reviewer's suggested rendering of the vae clauses: replaced by the interjection-policy wording.
- X seg-0057 · reviewer's "storehouse": rejected. A storehouse suggests things of value, so "receptacle" (*receptaculum*) is used.
- X seg-0055 · reviewer's "put on show": the issue holds, but the patch changes only the noun and keeps "exhibited" (*exhibentur*).
- XI seg-0017 · reviewer's "in the sense that it is tending not to be": shortened to the Latin's own shape (*nisi quia tendit non esse*).
- IX seg-0006 · "chastity and continence": not changed. It is sexual continence, per the continentia policy.

## Finish (2026-11-17)

Run on `pipeline/modern/confessions.json` after the patch was applied (all 74 `new` strings present). Paragraph
counts per book unchanged; JSON formatting kept (indent 2, non-ASCII, no trailing newline). A check confirms the
text changed only in quote characters, "Manichean", and the two titles.

- **Quotation marks: 397 characters changed.** Straight single quotation marks → double in II, V, VI, XII (140;
  XIII had only apostrophes); curly ‘ ’ quotation marks → double in IV (43; IV seg-0018/0019 is one quotation running
  over two paragraphs, opened at each and closed at the end, which is kept); curly “ ” → straight double in VIII and
  X (160); curly apostrophes → straight in IV and VIII (54). Plural possessives (pupils', wives', Manichees',
  silversmiths', Moses') kept as apostrophes. No curly mark is left anywhere in the text. Also converted, as a
  clear case of the policy though the policy did not list Book IX: IX seg-0024, the word-as-word quotes
  'has been' / 'will be' / 'is' (8 marks, counted above), which stood in single quotes outside any quotation.
- **Manichaean: 2** (V seg-0023). "Manichee(s)" untouched.
- **Titles: 2.** Book VII "The Unchangeable Light", Book X "The Palaces of Memory" (the `title` fields).
- **Divergence notes: 3 rewritten, 1 requoted.** VII *dealbatiores* (patch reversed "whitewashed" → "brighter";
  note now argues for "brighter"); VIII *continentiam* (patch reversed "self-control" → "continence"; note now gives
  the continentia policy's reason); XI *distentio* (lectio now quotes "my life is a stretching-out"; note says the
  word is the same every time). XII *nihil aliquid*: lectio requoted with double marks to match the text.
  The notes' own quote style (single quotes in most, curly in a few) is apparatus, not edition text, and was left.
  Overview and introduction describe no changed choice.

Left for the editor: the quoted-verse line breaks need the pipeline follow-up named under Policies; run
`python3 -m pipeline.build` (not run here).
