# Nicomachean Ethics · verify 2026-11-17 · policies and rejections

Edition `lectio-modern`, checked against Chase 1911 and the Greek. The Greek is not bundled; readings were
judged from knowledge of the Bekker text, and each `why` in patch.json says so by citing it.

## Policies

### 1. Glossary of renderings (whole work)

One English word per key term in every book. patch.json carries every entry needed. It was built by sweeping
the full edition for each variant, not only the instances the reports name.

| Greek | Rendering | Variants removed |
| --- | --- | --- |
| sōphrosynē / sōphrōn | temperance / temperate | self-control (II, IV, IX), self-mastery (III, VI), self-command (X), self-restrained (IV) |
| akolasia / akolastos | self-indulgence / self-indulgent | dissipation (II), uncontrolled, undisciplined, dissolute (II–III), "no self-control at all" / "utter lack of self-control" (VII), "no self-restraint" (IV) |
| enkrateia / enkratēs | self-control / self-controlled | — (only ever this word now) |
| akrasia / akratēs | lack of self-control / the man who lacks self-control | "fails of/at self-control", "without self-control" |
| tryphē / tryphōn | luxuriousness / pampered | "self-indulgence" (VII seg-0002, 0018), which collided with akolasia |
| kalon (to kalon, kalos, kallion, kallistos) as a moral value or motive | noble / the noble / nobler / noblest | fine (II, III, IV, VI, VII, IX, X), honor (III courage, X lawgivers), honorable (III, VIII), dishonorable (IV) |
| aidōs | shame / a sense of shame | "a sense of honor" (III seg-0033, X seg-0028) |
| timē | honor | only timē is "honor" now |
| teleios | complete | final (I) |
| orthos logos | right reason | right principle (VI) |
| sophia | philosophic wisdom | theoretical wisdom (I) |
| politikon (zōon) | political animal | "made for a community" (I), "social animal" (IX), "political life" (VIII) |
| praotēs / orgilotēs | even temper / hot temper | mildness, irascibility (IV) |
| eirōneia / eirōn | self-deprecation / self-deprecating | false-modest (IV) |
| ho theos | the god / a god (lower case) | God (I, VII) |

The rules where a term needs more than one word:

- **akratēs, short form.** Book VII is about this one condition, so after seg-0003 it may use the short forms
  "the weak-willed man" and "weakness of will". Seg-0003 introduces them in apposition ("the man who lacks
  self-control — the weak-willed man"). Outside Book VII only the full form is used (VI seg-0012 patched).
  "Weak" alone never stands for the akratēs, because it is the name of the *astheneia* form in VII seg-0019.
  The short forms never name the akolastos.
- **kalon, non-moral uses.** Where *kalos* means beautiful or excellent of its kind, it keeps "fine",
  "finest" or "beautiful": a fine day (I-0019), fine children, the finest shoe, the finest harmony, the finest
  object of a sense (X-0010), fine music, fine distinctions. Some "fine" and "honorable" words render other Greek
  words, and they stay too: "something good and fine" (I-0032, *spoudaion*), "finer than the evening star"
  (V-0006, *thaumastē*), "a fine character" (IX-0034, *spoudaios*), "honorable" spending (IV-0011/0012,
  *timia*), "such fine or pleasant things" (VII-0011, *agathōn kai hēdeōn*).
  III seg-0032 keeps "longing for what's noble (that is, for honor)", which is the Greek *kalou orexis (timēs gar)*.
- **nous.** There are two senses, and each keeps its own word. As the faculty that grasps first principles
  (Book VI) it is "intuitive understanding". *Synesis* is "understanding", and bare "understanding" is no
  longer used for *nous*. As the highest, divine part of us (I-0012, I-0014, IX-0032/0033, X-0020 to 0027)
  it is "intellect". The everyday sense of good sense may stay "intelligence" (I-0016, VI-0018, X-0018, X-0031).
- **aretē.** "Virtue" is the moral sense. "Excellence" is used where the craft and function sense is live, or
  for the general class that includes the intellectual excellences (II-0001, VI). Book I seg-0019 marks the
  crossover once ("excellence, or virtue"). See Needs the editor for Book IV.

### 2. No contractions (mechanical; not patched entry by entry)

Books I, II, V, VI and X are written without contractions. Book III has 189, Book VII 9 and Book IV 3. After
patch.json is applied, expand every contraction in the edition: n't → not (can't → cannot, won't → will not),
'll → will, 're → are, 've → have, let's → let us, it's/that's/what's/there's/here's/he's/who's → … is.
These need judgment and are listed here: III-0017 "it's been" → it has been; III-0022 "he's let" → he has let;
III-0039 "what's been" → what has been; III-0034 "they'd lost" → they had lost. Every other 'd is would.
Possessive 's is untouched. patch.json's `old` strings quote the current text, contractions included, so the
patch must be applied before this pass. None of its `new` strings contain a contraction.

### 3. Book III voice

Besides policy 2, the spoken fillers are patched: "Well,", "here's a stronger point", "on down the line",
"flat out", "Same with …". This is enough to bring Book III into one voice with I and II. The register is not
otherwise wrong, so nothing more is rewritten.

### 4. Book VIII stiffness

The two knotted sentences are rewritten (seg-0015, seg-0045). The "different keys" image is dropped (seg-0044/0045).
The rest of Book VIII reads in the work's voice.

### 5. Markdown in Book X

All 21 `*…*` spans are removed. Where the stress mattered, the wording now carries it: "to what end",
"in a particular place", "really is", "he himself", "proper to man", "already have".

### 6. Chase's insertions

IX seg-0046: the Shakespeare line is removed and Aristotle's plain statement restored. VII seg-0014: the
homosexual and passive-intercourse examples that Chase silently cut are restored. Both are in-segment edits, so
they are patched rather than referred. The VII entry is flagged in its `why` for the editor to read.

## Rejected or narrowed

- I seg-0012 "in place (a habitation)": rejected. "Habitation" is current English, not archaism.
- I aretē "pick one rule" (medium): narrowed to the seg-0019 crossover plus the rule above. The other Book I
  uses of "excellence" (0034–0037) introduce the general class that Book II divides, which fits the rule.
- II seg-0010: the reviewer's fix ("the man who abstains but resents it is not") is amended to "is
  self-indulgent", which is what the Greek says (*ho d' achthomenos akolastos*).
- V seg-0025, setting the Euripides lines as verse: rejected. No segment in this prose edition has line
  breaks, and every verse quotation (Hesiod, Homer, Agathon, Evenus) is run inline. The garbled wording
  is fixed.
- VII "weak-willed may stand only as an occasional variant": narrowed. It is kept as the defined short form
  throughout Book VII (policy 1), because the book's running subject cannot carry "the man who lacks
  self-control" fifty times. The blur the issue names, akratēs against akolastos, is fully removed.
- X seg-0020, "intellect (the faculty we called intuitive understanding)": rejected. That is a gloss inside
  the sentence (METHOD: an error even when correct). The glossary handles the shift instead.
- X seg-0028 "a sense of shame": kept, as the reviewer allowed. It is *aidōs*, now the glossary word.
- VII seg-0008 "recites the right principle": not changed to "right reason". The Greek here is the reciting of
  *logoi* (arguments), not *orthos logos*.

## Needs the editor

- **aretē in Book IV.** Book IV says "excellence" 26 times for the moral virtues it treats, against "virtue" in
  III and V. Bringing it to policy 1 is a separate sweep of about 20 entries, and the reports did not raise
  it. It is left for the next pass.
- **Contraction pass (policy 2).** This needs a short script, run after `apply.py` and before
  `python3 -m pipeline.build`. Check the four judgment cases by hand.
- **VII seg-0014 restoration.** It is faithful and plainly worded. Because it adds content readers did not
  have before, the editor should read it before applying.

## Finish (2026-11-17)

Run on `pipeline/modern/nicomachean-ethics.json` after the patch was applied (all 206 `new` strings present, no `old` left).
Paragraph counts per book unchanged (37, 41, 47, 27, 32, 19, 35, 49, 46, 35); JSON formatting kept (indent 2, non-ASCII, no trailing newline).

- **Policy 2, no contractions: 197 expansions.** n't → not 74, can't → cannot 9, won't → will not 3, 's → is 68
  (it/that/what/there/he/who/whatever), let's → let us 3, 're 11, 've 10, 'll 10, 'd → would 5, and the four judgment
  cases by hand (III-0017 "it has been", III-0022 "he has let", III-0039 "what has been", III-0034 "they had lost").
  By book: III 186, IV 2, VII 9. Every remaining 's was read and is possessive (e.g. IV "honor's way", III "the
  mathematician's is not"). No contraction is left in the text. The divergence notes, overview and introduction had none.
- **Policy 1, glossary:** fully carried by patch.json; a sweep for every removed variant (self-mastery, self-command,
  dissipation, God, right principle, theoretical wisdom, final, mildness, false-modest, social animal …) finds none
  left outside the allowed exceptions. No change made.
- **Divergence notes rewritten (7) and one phrase fixed:** ergon (no in-sentence gloss now, I-0018); sōphrosynē/akolasia
  (no "self-mastery" gloss, III-0040, VI-0006); akrasia (full form, Book VII short forms per policy 1); enkrateia/karteria
  (quotes "holding out is to mastering…", the four characters now "temperate, self-controlled, lacking self-control,
  self-indulgent"); nous/to kalon in IX ("thinking part" in IX.4, "intellect" in IX.8); the bloom of pleasure in X.4
  (now quotes "an end that supervenes on it", the reason from the X-0011 patch); theōria (nous = "intellect", not
  "intelligence"). Generosity note: "for the sake of what is fine" → "what is noble". Overview and introduction
  describe no changed choice; untouched.

Left for the editor:
- VII seg-0012: "weak about money, honor, anger" uses bare "weak" for the akratēs, which policy 1 forbids; needs
  "weak-willed about …" or similar (not mechanical, not in patch.json).
- aretē in Book IV (see Needs the editor above), and the VII seg-0014 restoration read.
- Run `python3 -m pipeline.build` (not run here).
