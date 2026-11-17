# Meditations · verify 2026-11-17 · rejected and policies

Authority: the bundled Greek (`greek-original`). Long (1862) and Casaubon (1634) are witnesses, not sources of text.

## Policies

1. **Long's apparatus stays out.** Nothing from Long's square brackets, footnotes, conjectures, ellipses or corruption marks (+) goes into the text unless the bundled Greek has it. Every bracket, ellipsis, `+` and note-segment in Long was swept, not only the reported ones. Patched as a result: I.17 "historical writers"; II.6 "one life"; IV.3 "chance jumble" and the repeated refrain; IV.18 "Agathon"; IV.19 "clinging to something else"; IV.30 "hold to my reason"; IV.33 "Leonnatus"; IV.34 "one of the Fates"; V.8 "the universe itself"; V.14 "philosophy"; VI.14 "universal"; VII.31 "law rules all"; VII.40–41 (Cicero's Latin from Long's footnote, printed as text); VII.48 "a fine saying of Plato's"; VII.58 "remember..."; VIII.3 "aligned with their pursuits"; VIII.33 "wealth or prosperity"; X.8–9 (Homer from Long's footnote, printed as text); X.21 "is wont"; X.23 Plato quotation; XI.18 heading; XI.18 "Apollo"; XI.26 "Ephesians"; XII.3 "the god that is within you"; XII.27 "Catellinus"; XII.36 "the world" and "or three". Long's other brackets supply words the Greek implies and are left alone.
2. **Frozen segments, leaked notes.** Two segments held only Long's notes (VII `seg-0041`, X `seg-0009`). A segment cannot be removed or left empty (an empty paragraph disappears in the build and shifts every later id), so each takes over the genuine Greek beside it: X `seg-0009` takes the closing sentence of X.8 (a fresh thought in the Greek, πρὸς μέντοι τὸ μεμνῆσθαι…); VII `seg-0041` takes the second verse of the VII.40 couplet. Book V's Hesiod line, split across `seg-0035`/`seg-0036`, is made whole in `seg-0036` the same way. Nothing is added or removed, and no text crosses into another chapter.
3. **The inner daimon** is "the divinity within (you / him / me)" everywhere: II.13, II.17, III.3, III.4, III.6, III.7, III.12, III.16, V.10, V.27, X.13, XII.3. Where Marcus says ὁ ἐν σοὶ θεός or τὸ ἐν σοὶ θεῖον (III.5, XII.1) the existing "divinity within you" already matches. VII.17 names the Greek word (policy 7).
4. **"Womanish."** θῆλυς / θηλύτερος is "unmanly" (II.10 patched; IV.28 already has it). ἀνδρόγυνοι in III.16, a different word, keeps its literal "men who have turned themselves into women". γυναικάριον (V.11) stays "a weak woman's"; κίναιδος (V.10) becomes "a debauchee".
5. **Pronouns.** For a generic person the work says "a man … he", and "people" for the plural, as Books I–VII and IX–XII already do. Book VIII's "a person … they" is patched everywhere it occurs (the singular "they" was found by a sweep of the whole work, and it was only in VIII), plus III.4's "A person like this" (ὁ ἀνὴρ ὁ τοιοῦτος).
6. **Repeated verses.** The Book VII wording is canonical, and XI.6 quotes it word for word: "If the gods care nothing for me and my children, there is a reason for this too." / "We must not be angry at things." / "Life must be reaped like a ripe ear of grain."
7. **Greek puns.** Where a sentence depends on a Greek word and is false or empty in English, the Greek word is named once, transliterated without accents, inside the sentence: eudaimonia/daimon (VII.17), katorthoseis (V.14), aktines/ekteinesthai (VIII.57), philei (X.21). Where English carries the play it stays English: limb / part (VII.13), fortunate / fortune (V.37, patched from "lot"), the -minded names of X.8 (explained in the text itself).
8. **Speakers and quotations.** Wherever the bundled Greek has quotation marks (the imagined objector, Socrates, Epicurus, Epictetus, the poets, Plato), Lectio uses double quotation marks. The exception is a turn already marked in words ("you say", "you may object") or a quick self-question that cannot be misread (IV.12 "Do you have reason? I do."). Quoted verse runs on as prose. This is a prose edition, so its paragraphs cannot hold line breaks, and a slash would trip readers.
9. **Mechanical (described here, not patched):** single quotation marks used as primary quotes (I.12 'too busy', III.4, X.8 'rational' …) become double; dashes are unspaced em dashes throughout (I.4, I.8, I.14 and others use spaced " — "). Apply as one normalization pass with the build.
10. **Colophons** ("Among the Quadi at the Granua", "This in Carnuntum") are not carried. The bundled Greek omits them. They belong in the enrichment layer as notes on Books I and II.

## Rejected

- I `seg-0017` form (colophon): the bundled Greek has no place note at either end of Book I; policy 10.
- II `seg-0017` form (colophon): same; policy 10.
- II `seg-0006` "Go on, wrong yourself" (imperative): the bundled Greek reads Ὑβρίζεις, ὑβρίζεις ἑαυτήν, indicative; Long's imperative follows another text. The Lectio wording stands.
- III `seg-0016` "men who have turned themselves into women" (change to match II): a different Greek word (ἀνδρόγυνοι), kept literal; policy 4.
- III `seg-0004`, X `seg-0015` (daimon notes): no separate fix needed; covered by policy 3.
- IV `seg-0032` proposed fix ("I get no nourishment … and still I hold to reason"): the issue holds but the fix is wrong. The bundled Greek reads τροφὰς … ἔχω καὶ οὐκ ἐμμένω ("I have the nourishment and do not abide"). Patched to the Greek instead.
- VI `seg-0014` proposed fix (slaves in the third rank): the issue holds but the fix is wrong. The bundled Greek puts the slaves in the second rank and reads καθὸ λογική, "not as rational". Patched to the Greek instead.
- X `seg-0009` proposed fix "delete seg-0009": segment ids are frozen. Replaced in place by the end of X.8; policy 2.
- XII `seg-0009` proposed "boxer": a pancratiast is not a boxer. Patched to "bare-handed fighter … gladiator" instead.
- V `seg-0041` proposed "shouting from the Rostra": the bundled Greek reads κλαίων (crying). Patched to "crying out on the Rostra".
- V `seg-0028` "Neither tragic actor nor prostitute" (considered, not raised): Long marks it corrupt, but the bundled Greek has Οὔτε τραγῳδὸς οὔτε πόρνη. Kept.
- VI `seg-0027` "But it is not so." (considered for quotation marks): it reads correctly as Marcus's own reply, and marking it adds nothing.
- VII `seg-0013` limb / part (considered as a Greek pun): English carries the distinction; policy 7.
- XI `seg-0015` "a wolfish, false friendship" (considered as Long's gloss): λυκοφιλία is glossed lightly enough to read clean; kept.
- XII `seg-0018` (Long's "[For let thy efforts be—]", considered): Lectio's sentence stands without the dropped connective and does not mislead.

## Finish

Applied to `pipeline/modern/meditations.json` and `meditations-books/book-02…12.json` after the patch (all 155 patch entries confirmed present first). Paragraph counts per book identical before and after; each file keeps its own JSON layout (indent 2 for `meditations.json` and `book-07.json`, single-line for the rest), non-ASCII kept, trailing newline kept.

- **Policy 9, quotation marks:** 12 pairs of single quotation marks used as primary quotes became double (I.12 "too busy"; I.16 "driven to the sweating point"; III.4 three; IX.10 "fruit"; X.8 three; X.40 two; X.41 one). Possessive apostrophes (Epictetus', Maximus', neighbors', Augustus', Empedocles') left alone. No single quotation marks used as quotes remain.
- **Policy 9, dashes:** 19 spaced " — " in the text became unspaced "—" (all in Book I; Books II–XII were already unspaced). The same rule applied to the overview, introduction and divergence notes: 7 more. The provenance fields (`method`, `sourcesCited`) were not touched.
- Policies 1–8 and 10 were carried by patch entries; nothing further to do mechanically. No colophons in the text.
- **Divergence notes:** the daimōn note rewritten: Lectio now prints "the divinity within you" everywhere (policy 3), not "the spirit within you" / "your inner guide", and VII.17 names the Greek. The hēgemonikon note rewritten: it claimed "the mind that governs you" / "your directing mind", which the text never uses; the edition says "the ruling faculty" (18 times), with "ruling power", "governing part" and "guiding principles" where the sentence needs it. The title note stands. Overview and introduction describe no choice the edition has dropped.

Left for the editor:
- The hēgemonikon note now records agreement with Long rather than a divergence. It was wrong before this patch, not made wrong by it; keep it as written or drop it.
- The divergence notes and front matter use curly quotation marks while the text uses straight ones; policy 9 does not name a typographic style, so nothing was changed.
- Run the pipeline build and record the revision in provenance.
