# Dhammapada · lectio-modern · rejected issues (verify, run 2026-11-17)

Checked against muller-1881 and the Pali. The Pali is not bundled, so it was read from the verifier's own knowledge, and each `why` in patch.json says so.

## Policies

- **Glosses (parentheses and appositives).** Nothing in the verse explains the verse. "Nirvana" stays only where the Pali has *nibbāna* (23, 32, 75, 126, 134, 184, 203, 204, 226, 285, 289, 369, 372). Wherever Müller's parenthetical "(Nirvana)" was written into the line, it is removed and the Pali's own term stays alone: 92, 93, 154, 218, 225, 323, 368, 381, 383. The other Müller glosses are removed the same way: "the Buddhas" (254), "the Buddha" (273), "of craving" (275), the dashed "the Law"/"the Order" (190), "restraint and meditation" (384), "Indra" for Maghavan (30), and "the tempter" after Mara (7, 274, 337). The parenthesis sweep of the whole edition found only the three Pali transliterations in 277–279, and they are removed. Kept: the edition's Buddha/Awakened One doublet (a translation of the word, not a gloss), "an Arhat, the worthy one" (420), and "Samana, an ascetic" / "Pabbajita, one gone forth" (388), where the verse is a pun on the Pali words and needs them.
- **Errors carried over from Müller.** Where the Pali reads otherwise, follow the Pali. Brahmā the god is "Brahma", never "Brahman" (105, 230); "Brahmin" is kept for *brāhmaṇa*. Also fixed: "outward acts" to "no true ascetic outside this teaching" (254, 255), "monastery" (302), "cravings" for doubt (141), "good mother/father" for honoring them (332), the kingdom and tiger mix-up (295), and "Let the fool crave" (73). After the patch, no "Brahman", "outward acts" or "monastery" is left in the edition. "Monasteries" in v73 is correct, since *āvāsa* there means monks' dwellings.
- **Terms.** Each Pali term gets one rendering. *Appamāda* is "heedfulness" and *pamāda* is "heedlessness", never "carelessness" (26–32, 241, 371). *Dhamma* as the Buddha's doctrine is "the teaching" ("the true teaching" for *saddhamma*) and is never left untranslated (190, 194, 354). Where *dhamma* means justice or eternal law it is "law" (5, 115, 176, 257). *Saṅgha* is "the Order" (190, 194, 298). *Bhikkhu* is "monk" (343). *Samaṇa* is "ascetic", never "seeker" (184).
- **Dash style.** Em dashes close up (—) everywhere, as in 20 of the 26 sections. This is a mechanical normalization and is not patched entry by entry. After `apply.py` has run, replace every remaining " — " with "—" in sections 2, 3, 4, 11, 15 and 25 of `pipeline/modern/dhammapada.json` (verses 24, 28, 32, 33, 40, 43, 55, 147, 149, 151, 153–154, 208, 362, 366, 367, 378). Do it in that order. Two patch entries (368, 381) quote a spaced dash in `old` and remove it themselves. No `new` text adds a spaced dash.

## Needs the editor

- None blocking. v128 fit inside Chapter IX's last segment (`seg-0012`), using the edition's own joint number "127, 128." as in "153, 154.", so no segment was added. Once it is applied, the provenance should note the restored verse.
- The edition's `divergences` note for verses 1–2 quotes "the mind ... makes everything". Its wording should change along with the patch for those verses.

## Rejected

- I `seg-0001`, `seg-0002` · removing "All that we are is shaped by what we have thought": rejected. Keeping Müller's cadence beside the Pali is a choice the edition recorded in its divergences, and the famous line stays recognizable. Only the mistranslated clause ("makes everything" for *manoseṭṭhā*) is patched.
- II `seg-0010` · proposed "Maghavan, Indra,": rejected as a new gloss. The patch restores "Maghavan" alone, and "lord of the gods" identifies him.
- IV `seg-0001`, `seg-0002` · proposed "the realm of Yama, lord of the dead": the gloss is rejected and the severity is lowered to low. "Realm of Death" was not wrong, so the patch only restores the proper noun.
- VIII `seg-0009` · "reverence to the upright is better" called a repetition: rejected. The Pali line itself ends *abhivādanā ujjugatesu seyyo* after "not worth a quarter". The repetition is in the source.
- XXIII `seg-0013` · proposed "to honor the holy": changed to "to honor Brahmins". *Brahmaññatā* names Brahmins, and the edition uses "Brahmin" for *brāhmaṇa* everywhere else.

## Finish (2026-11-17)

Done in `pipeline/modern/dhammapada.json` after the patch was applied. Paragraph counts unchanged in all 26 sections; JSON formatting kept.

- **Dash style: 16 changes.** " — " closed to "—" in section text: section 2 (3), 3 (3), 4 (1), 11 (4), 15 (1), 25 (4). No spaced dash is left in any section. The one divergence note that quotes the text with a spaced dash (verse 33) was matched to it. The overview, introduction and the notes' own prose keep their spaced dashes, because the policy covers the verses only.
- **Other policies.** Carried by the patch. A sweep finds no "Brahman" for Brahmā, and no "carelessness", "seeker", "(Nirvana)", "Indra", "the tempter", "outward acts" or "monastery" left in the text.
- **Divergence notes rewritten: 15 of 79.** Verses 1–2 (now quotes "the mind is chief of all" and drops the claim that the mind "makes" everything), 21–32 (heedlessness, never carelessness), 29, 33 (dash), 51–52, 134 ("you have reached Nirvana", not "come close"), 154, 188–192 ("the teaching", "the Order"), 229–230 (Jambu river kept by name; Brahma, not Brahman), 256–257 (dhamma as "law"), 277–279 (Pali terms out of the verse), 323, 324 ("in rut"), 354 ("the teaching"), 383 ("the Uncreated", no Nirvana gloss).

Left for the editor:
- The overview still speaks of "the mind that makes the world". This is a summary, not a rendering, and it was left. It sits a little at odds with the verse 1–2 fix if the editor wants it exact.
- The provenance should note the restored v128 (see "Needs the editor" above). The pipeline build has not been run.
