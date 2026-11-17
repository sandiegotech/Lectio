# Tao Te Ching · lectio-modern · rejected issues (verify, run 2026-11-17)

Checked against legge-1891 and the received Wang Bi text. No Chinese is bundled, so every reading of the Chinese is from my own knowledge, and the `why` of each patch entry says so.

## Policies

- **德 is "power", everywhere.** The edition's own notes and introduction already call te "the quiet power", and "power" was the majority use (chs. 10, 21, 23, 28, 41, 54, 59, 60, 65, 79). "Virtue" is retired. patch.json moves chs. 38, 51, 55 and 68 to "power", titles included, so that 玄德 is "the mysterious power" in 10, 51 and 65. There are two exceptions. In ch. 49, 德善 / 德信 is 得 ("is won") and stays. In ch. 63, 報怨以德 becomes "Repay resentment with kindness", because "repay resentment with power" reads as revenge and the Lectio Analects 14.34 renders the same proverb "repaying injury with kindness". If the editor wants no exception, the alternative is "Repay resentment with power".
- **No glosses inside the line.** An explanation that follows a term goes into a divergence note, not into the sentence. Patched in chs. 10, 20, 25, 52, 79, plus the "credit" in ch. 2.
- **Hedges stay hedged.** Where the Chinese has 似 / 若 / 或 ("seems", "as if", "perhaps"), the English says so. Patched in ch. 4, and ch. 15's "enemies" is put back to "neighbors". Ch. 15's last line is not a hedge problem (see below).
- **去彼取此 is "He lets that go and takes hold of this."** It is used the same way in all three places (12, 38, 72).
- **The ideal person is "he"**, as the sage is everywhere in the edition. A generic maxim may use "you". Singular "they/their" is not used for the person the chapter describes. Patched in 13, 22, 56 and 69. Tense holds within a chapter: patched in 30, 74 and 80.
- **The base is the received Wang Bi text.** A variant reading is kept only when a divergence note records it (25 王/人, 15 蔽而新成). Undocumented variants are brought back to the base (2 恆也, 13 寵為上, 39 譽).
- **Titles are patched as text.** In pipeline/modern/tao-te-ching.json each title is a field of its section node, and apply.py's replace runs over the whole node, so title entries carry `"seg": "title"`. Their `old` occurs exactly once in the node (the paragraphs use lowercase forms). Retitled: 28 "Know the Masculine, Keep to the Feminine", 44 "Your Name or Your Self", and the four 德 titles.

## Needs the editor

- **Divergence notes go stale.** The divergence list is top-level in the source, not inside a section, so apply.py does not touch it. After the patch, these entries quote wording that no longer exists or defend the choice being reversed. They need rewriting by hand: Chapter 2, close · Chapter 4, line 1 · the seven excellences (8) · the gate of heaven (10) · the close (貴/愛以身為天下) (13) · the rude borderer, closing image (20) · the closing line (道法自然) (25) · the title of the chapter (38) · the names kings take (42) · verses 1 and 3 (德畜之) (51) · opening line (含德之厚) (55) · the close (直而不肆) (58) · repaying resentment (63) · the close (玄德 / 大順) (65) · the close (是謂不爭之德) (68) · near losing the treasures (69) · the second verse (72) · the closing line (75) · the tools of ten and a hundred (80). Also look at the 德 notes for 23 ("power/virtue"), 60 and 79, which say "virtue" in passing.
- **Ch. 75's divergence note** argues for the reading the patch reverses ("the one who does not clutch at life is the one who actually treasures it"). It has to be rewritten, not just re-quoted.

## Rejected

- 13 `seg-0002` · "drops the disgrace half (辱為下)": rejected as framed. Wang Bi reads 寵為下 and has no disgrace half; that is Legge's base. The line is still patched to the Wang Bi reading, because "from above" and "dread something worse" are not in it.
- 15 `seg-0003` · (pattern: hedges) "he can wear out and be made new again": not patched. It follows the 蔽而新成 emendation, which the divergence note records and which matches ch. 22 (敝則新). Flagged so the editor knows it departs from Wang Bi 蔽不新成.
- 16 `seg-0002` · "what was fated" → "one's destiny": rejected. The divergence note chooses 命 as the given lot deliberately, and "destiny" carries the same sense of fate. No gain.
- 17 `seg-0002` · "we did this ourselves" → "it happened of itself": rejected. It is a deliberate, documented rendering of 我自然, and the reviewer allows it if deliberate.
- 25 `seg-0003` · "the human being" for 王: rejected. The divergence note records the 人 variant, which was the reviewer's condition for keeping it.
- 46 `seg-0002` · missing 罪莫大於可欲: rejected. Wang Bi lacks the clause, so the edition follows its base. Legge's text has it.
- 57 `seg-0002` · "start to happen" is filler: rejected. "Start" renders 起 in 奇物滋起.
- 58 `seg-0001` · "crafty and broken" for 缺缺: rejected. The doubled pair mirrors the doubled 淳淳 ("honest and whole"). The divergence note gives "deficient, cunning, broken", and Wang Bi's commentary reads contention into the line.
- 60 `seg-0003` · "gathers in the people" adds a location: rejected. 焉 points somewhere, and the documented reading takes it as the people. That is a choice about a pronoun's referent, not a gloss added to the line. The proposed "flows back and meets" drops 焉 altogether.
- 2 `seg-0004` · the report's fix "does not lean on what he has done": rejected as worded. It is patched with the edition's own ch. 77 phrase for 為而不恃 ("does not rely on what he has done").
- 4 `seg-0002` · the report's fix "it only seems to be there": rejected as worded. "Only" adds doubt that 似或存 does not carry. It is patched as "yet it seems to be there".
- 20 `seg-0001` · the report's fix "a curt one": rejected as worded. 阿 is offhand, not curt. It is patched as "a careless one", which keeps the edition's adjective.
- 44 `title` · the report's fix "What Is Enough": rejected as worded, since it crowds ch. 46 "Knowing You Have Enough". It is patched as "Your Name or Your Self".
- 45 `seg-0001` · the report's fix "yet it is never used up": rejected as worded, because it drops 其用. It is patched as "yet its use never runs out".
- 75 `seg-0004` · the report's fix "Only the one who ... is wiser": rejected as worded, because "only ... wiser than" reads as a ranking of everyone. It is patched as "It is the one who does not strain after living who is wiser than the one who prizes life."

## Finish (2026-11-17)

Done in `pipeline/modern/tao-te-ching.json` after the patch was applied. Paragraph counts unchanged in all 81 sections; JSON formatting kept.

- **Mechanical policies.** None left to apply. Every policy above was carried by patch entries. A sweep after the patch finds no "virtue" for 德 in the text and 去彼取此 as "He lets that go and takes hold of this" in all three places (12, 38, 72).
- **Divergence notes rewritten: 25 of 169.** Re-quoted and re-argued to match the patched text: Chapter 2 close ("it never leaves him"), Chapter 4 line 1 (the ancestor, with the hedge), the seven excellences ("In dwelling"), the gate of heaven ("play the part of the female"), 13's close ("his own body"), the rude borderer ("a rustic"), 20's closing image ("I prize being fed by the Mother", the Way left unnamed), 道法自然 ("what is so of itself", once), the opening of 38 ("The highest power makes no claim to power"), the names kings take ("widowed", as in 39), 51 (德畜之 "power"), 55 ("One full of power"), 58's close ("never overbearing"), 63 (the "kindness" exception and why), 65's close ("the great accord"), 68's close ("the power of not contending"; 用人之力 is not 德), 69 ("the enemy"), 72's second verse ("what they live by"), 75's closing line (rewritten: the line ranks the one who prizes life second), 80 ("Though they have"). "Virtue" for 德 removed in passing from the notes on 23, 59, 60 and 79, and the 52 note no longer cites "the inner light".
- **Overview and introduction.** Already say "power" for te; no change.

Left for the editor:
- The patch `why` for 道法自然 says "so of itself" is the edition's word for 自然 in chs. 17 and 51. Only 51 uses it (17 has "we did this ourselves"), so the rewritten note cites 51 alone.
- Six notes quote wording that was already loose before this patch (Chapter 4 "empty, yet never used up"; 23's threefold parallel; 25 "the human being is great"; 51 "It is commanded by no one"; 59 "by restraint you yield early"; 74's carpenter line). Not touched, since no patch changed them.
- The note on 39's royal titles glosses 寡 as "the one of little worth" while the text says "widowed". It predates the patch and was left.
- The pipeline build has not been run, and the edition's provenance does not yet record the revision.
