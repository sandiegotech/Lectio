# Aeneid · verify · 2026-11-17

Lectio edition `lectio-modern`, checked against Dryden (1697) and the Latin. The Latin is not bundled, so it was checked from the verifier's own knowledge; line references are given in each `why` in `patch.json`.

## Policies

1. **Names.** Use the names Virgil gives, in his Latin forms: Pallas, Minerva, Tritonia (never "Athena"); Vulcan; Tartarus, Erebus, Orcus and Dis, not "hell"; Monoecus, not "Monaco". Do not add a name he leaves out (Ariadne, Theseus, Polyxena), and do not drop one he gives (Harpalyce, the Agathyrsi and Dryopes, Phegeus and Sagaris, Thaemon and Thymbris). A translated name ("Byrsa, 'the Hide'", "the Turning Islands") is a gloss, and it belongs in `enrichment.json`, not in the sentence. Patched: every "Athena" (I, II, III), every "hell" (IV, VI, VIII, XII), and the dropped or added names the reports flagged.
2. **Oaths and idioms.** No monotheist oaths ("God, …", "God in heaven", "I wish to god"): use the god Virgil names (Jupiter) or a plain cry ("Ah", "oh"). No modern idioms that call up something outside the poem ("gone with the wind", "for free", "wheel of fortune", "cut and run", "let me at it", "out cold", "lay down the law", "sponsor"). Every instance found in a search of all twelve books is patched.
3. **Word order.** Do not keep the Latin order when it puts the English subject last or separates a relative clause from its noun. Patched where flagged (VII seg-0008, seg-0015). Any others should be fixed when they turn up, not by a sweep.
4. **Contractions and speech register.** The poet's narration does not contract. Direct speech may contract where the speaker is talking in the moment (soldiers, quarrels, grief). Prayers, oaths, prophecy and speeches of state stay uncontracted. Books VII–VIII (almost no contractions) are already within this rule and stay as they are. Books IX–XII are not rewritten wholesale: the slang inside them is patched under policy 2, and "shan't" is patched. About 45 contractions in narration (I, V, IX–XII: "He didn't stop", "it couldn't hold", "he'd") should be expanded in one mechanical pass. That pass is a normalization and is not patched entry by entry. Run it after `apply.py`.
5. **Famous lines.** Keep each famous line at its own length and shape. Patched: *forsan et haec olim meminisse iuvabit* (I), *possunt, quia posse videntur* (V), *tu regere imperio populos … hae tibi erunt artes* (VI). Checked and left as they are: *sunt lacrimae rerum*, *timeo Danaos et dona ferentes*, *facilis descensus Averno*, *audentes fortuna iuvat*, *sic itur ad astra*, *una salus victis*.
6. **Quotation marks in Books II–III.** Aeneas's narration in II–III is printed without outer quotation marks. Its frame does the work: II seg-0001 ("Aeneas … began:") and III seg-0037 ("So Aeneas … told"). Speeches inside it keep ordinary double quotation marks. As everywhere else, a speech that runs on into a new paragraph reopens with a quotation mark. Patched: the outer opening quotation mark (II seg-0002) and closing one (II seg-0049) are removed, and the opening marks missing from Sinon's speech (II seg-0011, 13, 15, 16) and Dido's (I seg-0035) are added. This settles the form issues raised for II seg-0002 and III seg-0036, which needed no other entry.
7. **The shared last line.** XI.831 and XII.952 are the same Latin line (*vitaque cum gemitu fugit indignata sub umbras*). Both now read "and life fled with a groan, resentful, down to the shades." The line has no pronoun, as in the Latin, so the two read identically.
8. **Punctuation style.** Book XI alone uses curly quotation marks and apostrophes. Normalize it to the straight marks the other books use, mechanically, after `apply.py`. The XI patch entries match the current curly text so that they apply first.

## Rejected

- IV seg-0043 · "only to be away — cruel — when you lay down here?". The report asks to make *crudelis* address Dido ("cruel sister"). In *ut sic te posita crudelis abessem*, *crudelis* most naturally reads as nominative: Anna calls herself cruel for being away. The edition's reading is defensible, so it was left alone.
- XII seg-0029 · "fled the daylight in terror". The report reads *lucemque perosa* ("hating the light"). The line here is 12.660 *lucemque exterrita fugit*, "fled the light in terror", which the edition renders correctly. *Lucemque perosi* belongs to the suicides of VI.435.
- II seg-0002 / III seg-0036 · single quotation marks for speeches inside the narration, plus reopening every paragraph of II–III. This was superseded by policy 6 (no outer quotation marks), which needs six entries instead of about eighty.
- XI seg-0001 · curly quotation marks. Handled by policy 8, not patched entry by entry.

## Finish · 2026-11-17

Run after `apply.py`, on `pipeline/modern/aeneid.json`. Paragraph counts are unchanged in all twelve books (39, 49, 37, 44, 40, 38, 42, 32, 35, 37, 32, 41). The JSON round-trips byte for byte in the file's own formatting.

**Policy 8 (Book XI punctuation).** 172 curly marks made straight in Book XI: “ ” became ", and ‘ ’ became '. Book XI now matches the other books.

**Policy 4 (contractions in narration).** 40 contractions expanded in the poet's narration: I 2, V 2, IX 19, X 2, XI 1, XII 14. Narration and speech were told apart by quotation marks, and then every hit was read in context. All the 'd forms are past perfect ("he'd forgotten" became "he had forgotten"). The rest: n't to "not" (can't to "cannot"), "it's" to "it is", "what's" to "what is". These include two in similes (IX "a hunger he cannot reach", XII "will not answer") and two in reported thought (IX "they would not come out", XI "that he had not taken Aeneas in"). Not changed: I "everyone's astonishment", a possessive. No contraction was found in the narration of IV, VI, VII or VIII. Speech was not touched.

**Divergence notes.** Two were rewritten because a patch changed the wording they quote:
- VI.851–853 *tu regere imperio*: `lectio` now quotes "You, Roman, remember: rule the nations with your power...". The note adds the policy 5 reason: the line is kept at its own length, with *memento* kept and *hae tibi erunt artes* naming Rome's art once.
- XII.952 *vitaque cum gemitu*: `lectio` now quotes "and life fled with a groan..." with no "his". The note says XI.831 is rendered identically, with no pronoun, as in the Latin (policy 7). "A soul that goes down" is now "a life that goes down".

The overview and introduction describe no choice the edition has dropped, so they were left alone.

**Left for the editor**
- **Books II–III contractions.** Aeneas's narration in these books has 13 contractions, such as "I'll begin", "he'd fallen among enemies" and "I didn't look back". Policy 4 names I, V and IX–XII, and II–III are a speech, so these were left. Decide whether Aeneas's tale follows the speech rule or the narrator's.
- **Speech register in IX–XII.** Policy 4 also says prayers, oaths, prophecy and speeches of state stay uncontracted. This needs judgment speech by speech and was not swept.
- **Book V curly quotes.** V seg-0027 has curly single quotation marks: ‘Troy’ and ‘the Trojan ride.’ Policy 8 covers Book XI only, so these were left.
- **"Hell" in Book VII.** The text still has "I will stir up Hell", "her own sisters in Hell" and "her hellish voice". Policy 1 bans "hell", but its patch covered only IV, VI, VIII and XII. Divergence note 19 (VII.312 *Acheronta movebo*) argues for "Hell". If VII is brought under policy 1, rewrite that note to match.
- **Stale divergence notes from before this run.** No patch touched these:
  - Note 0 (I.462): quotes "there are tears for things, and mortal matters touch the heart". The text reads "there are tears for the way of things, and the troubles of mortal men touch the heart".
  - Note 1 (I.1): quotes and argues for "I sing of arms and of a man". The text keeps "Arms, and the man, I sing", so the note argues for a choice the edition does not make.
  - Note 8 (III.707–711): quotes "There I lost my father Anchises". The text reads "There, after all the storms of the sea had battered me, I lost my father Anchises".
