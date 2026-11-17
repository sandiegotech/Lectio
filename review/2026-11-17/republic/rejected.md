# Republic · verify 2026-11-17 · policies and rejected issues

## Policies

1. **Glosses and translators' notes are never printed as Plato's text.** Anything that explains a name, a pun, a proverb or an allusion inside the sentence comes out, and goes to the enrichment sidecar if it is worth keeping. I swept all ten books for parentheses, brackets, "the name means", "the god of", "the river of", "as in", "that is" and similar, and checked them against Jowett's notes. Patched: I seg-0001 (Bendis), III seg-0025, VI seg-0073 / 0144 / 0199 / 0387 / 0407, VII seg-0077 / 0275, VIII seg-0027 / 0156 / 0219, IX seg-0344, X seg-0096 / 0314. Kept because Plato wrote them: III seg-0148 "(I'll drop the meter; I'm no poet)", II seg-0280 (Niobe), II seg-0311 ("the river of Argos", in Aeschylus' line), III seg-0250 (dactyl / heroic), IV seg-0108 (Apollo at Delphi), X seg-0313 ("that is, once every hundred years"), and the translated river names Heedlessness and Forgetting in X seg-0317 / 0318.
2. **Oaths.** When the Greek swears by Zeus (μὰ Δία, νὴ Δία, πρὸς Διός), the edition prints "by Zeus". It prints "by the gods" for πρὸς θεῶν, "by the dog" and "By Heracles" as they stand, and "Good heavens" for the exclamation βαβαί. "God", "god", "Good lord" and "Ye gods" are never used as interjections. "Heaven forbid" is kept for a wish that names no god. "Honestly" is changed only where it stands in for an oath I am confident of (IX seg-0056, 0272). Patched in I, II, IV, IX and X.
3. **Fixed terms.** The four virtues are wisdom, courage (adjective "brave"), **self-command** (adjective "self-commanded") and justice. Book IV, which defines σωφροσύνη, already uses "self-command", and the word suits the "master of himself" argument. The patch changes "self-discipline" (III), "self-restraint" (II) and "temperance" (VI, VII, IX) to match. γυμναστική is **"physical training"** throughout, as in III and IV, since "gymnastics" now means the sport. The patch changes II, V, VII and VIII. The divided line uses VI's terms everywhere: intelligence, thought, conviction, imaging (the latter two together opinion). VII's recap (seg-0265, 0267, 0268) said "what we called them before" but used different names, so it now matches; "science" stays for ἐπιστήμη, since that is Plato's own change.
4. **A line quoted twice uses one wording.** Odyssey 20.17 (III seg-0098, IV seg-0365) is "He struck his chest and rebuked his own heart". Book IV's wording wins because κραδίην ἠνίπαπε means "rebuked", and IV seg-0366 builds on "rebuke".
5. **Contractions (Book VII).** Dialogue follows the norm of Books VI and VIII. The patch contracts the short exchanges in VII (25 words or fewer) and leaves the long expository speeches (the cave, the curriculum, the line recap) uncontracted, as the other books also do. It skips replies where the stress falls on the verb ("It is.", "So it is.", "Let us, he replied.") and two that are not unique in the section ("That is right, he said."). Not every uncontracted form in VII is patched. A later read-through can finish the job by ear.
6. **Verse and quotation marks (mechanical, not patched).** Verse quotations run inline as prose inside single quotes, with no line breaks and no " / " separators. This is already the case in every book except II. Book II's slashes (seg-0021, 0028, 0030, 0033, 0035, 0038, 0271, 0279, 0309) should be replaced by a plain space in one pass. Apostrophes and quotation marks should be normalized to one character set across the edition in the pipeline: Book IX is typographic (’), Books I and VIII are mixed, and the rest are ASCII. The two double-quoted verse lines in IV (seg-0061, 0365) are patched to single quotes, because that is a convention error, not a character-set one.
7. **Modern words.** Words that date the text or bring in an office, a gym, a bank or a date are replaced with plain words: girlfriend, the haves, consumer, payroll, workouts / the gym, literally (misused), trigger / short-fused / crack up, enforcers, No way, parked, hands-on, operators, bazaar / in stock / browse, converts to cash, instincts. Ordinary current English such as "job", "deal" and "file under" stays.

## Rejected

- I seg-0124 · form: "True." inside Socrates's question. Fixing it needs a segment split, and segment ids are frozen. Leave it for a segmentation revision.
- I seg-0338 / 0339, II seg-0011, V seg-0498 · register: "file under" is ordinary English and renders τίθης ἐν … μέρει / εἰς ἄλλο γένος fairly. Only V seg-0447 ("file among philosophers"), the one that grates, is patched.
- IV seg-0102 · fidelity: "six feet tall" for τετράπηχυς (four cubits) is an accurate conversion with the same meaning. The reviewer marked the fix optional.
- VI seg-0407 · register: the term "imaging" (εἰκασία) is a standard rendering and is kept. Only the gloss after it is removed, and VII is matched to it.
- IX seg-0194 · voice: "I honestly can't say" renders Οὐ πάνυ … ἔχω εἰπεῖν (581e), not an oath (from my knowledge of the Greek).
- III seg-0300 onward, V seg-0036 etc. · voice ("gymnastics" vs "physical training"): resolved by Policy 3, not rejected. Listed here only so the Book III and V reports' fixes are not raised again in their original form.
- II verse-form items (seg-0021 … 0309, 0347): handled by Policy 6, not entry by entry.
- IV seg-0118 etc. · high (σωφροσύνη): handled by Policy 3. Book IV is the reference, so it needs no entries.

## Finish (2026-11-17)

Patch already applied (175 entries; every `old` gone, every `new` in place). Done in `pipeline/modern/republic.json` only; paragraph counts per book unchanged before and after (492, 349, 497, 457, 563, 408, 372, 447, 405, 318), JSON formatting kept (indent 2, non-ASCII kept, no trailing newline).

- Policy 6, verse slashes: 15 " / " replaced by a space in Book II (seg-0021, 0028, 0030, 0033, 0035, 0038, 0271, 0279, 0309).
- Policy 6, one character set: ASCII, the majority. 188 typographic quotes (‘ ’) in the text changed to ' (Book I 34, VIII 26, IX 127, and the Book IX title "The Tyrant's Soul"), and 34 in divergence notes 21-26. Greek `phrase` fields untouched. No double quotes remain in the text.
- Policies 1, 2, 3, 4, 7: swept the whole work for leftovers. None of temperance / self-discipline / self-restraint / gymnastic(s) / gym, no "God"/"god"/"Good lord"/"Ye gods" interjections, no listed modern word, no stray translator's note or parenthetical gloss outside the ones Policy 1 keeps. Nothing to change.
- Divergence notes rewritten: #16 (509b) now says Glaucon speaks comically, not that he laughs (VI seg-0380); #17 (divided line) quotes the line as it now stands, without the "reading of shadows and likenesses" gloss, and notes that VII's recap uses the same four names. The other 28 notes still quote the text (some by summary or with changed capitals) and needed nothing. Overview and introduction make no choice the patch changed.

Left for the editor:
- Policy 5: the by-ear read-through of Book VII contractions.
- Policy 2, "Honestly" not changed, Greek unchecked: III seg-0249 (400a, I believe μὰ Δία, so probably "By Zeus, he said, I can't"), IV seg-0220, VI seg-0012.
- Policy 7, one judgment case: II seg-0040 "some divine instinct" (θείᾳ φύσει); "divine nature" would match the IX seg-0009 fix.
- Policy 1 conflict: III "by imitation — impersonating their characters — or by a mix" (392d) is a gloss in the text, and divergence note #8 defends it. Decide; if it goes, rewrite note #8.
- The glosses the patch removed (I seg-0001 Bendis, VI seg-0199 Heraclitus, VI seg-0387 Ouranos pun, VIII seg-0027 nuptial number, IX seg-0344 729 ≈ year, X seg-0096 Creophylus, etc.) still need their notes added to `enrichment.json`.
- Note #20 quotes "the turning around of the soul"; the text says "of a soul" (VII seg-0077). It was like that before the patch.
- I seg-0124 segmentation (see Rejected). Pipeline build not run.
