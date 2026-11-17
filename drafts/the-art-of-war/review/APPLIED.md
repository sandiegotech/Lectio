# The Art of War · fixes applied

Review and fix pass, 2026-11-17. Each finding in 01.md–13.md was checked a second time against
the Chinese (pipeline/.cache/wikisource-zh-sunzi-bingfa.txt) before it touched a book file.
Text only: no paragraph added, removed or reordered (counts checked before and after); JSON
rewritten at indent 2 with non-ASCII kept and the trailing newline as before.

Grades: A — II, IX, X, XII · B — I, III, IV, V, VI, VII, VIII, XI, XIII · C — none.
No paragraph holds Giles's commentary or any gloss; the stray Giles lines in the working copy
(Turenne, Aids to Scouting, Tu Yu, the note on honour) appear nowhere in the draft.

## Applied

### Medium

- **V p-009** · fidelity
  "the fighting looks disordered … his form turns like a wheel" → "the fighting is in disorder … his form is round"
  鬥亂而不可亂, 形圓而不可敗: the Chinese says the fighting is in disorder and the form is round; "looks" and "turns like a wheel" were a commentator's reading in the line.
- **XIII p-004** · fidelity
  "It cannot be proved by measuring the heavens." → "It cannot be proved by measurement."
  不可驗於度, "verified by measures"; "the heavens" is the commentators' gloss, which the style sheet keeps out of the line. Divergence note XIII.5 rewritten: phrase and lectio now quote the new wording, and the note says why the heavens stay in the note and why "calculation" is not used (it is 計).
- **IV p-005** · read-aloud
  "To see a victory no further off than everyone else can see it is" → "To see a victory no further than everyone else can see is"
  見勝不過衆人之所知; "further off" put the distance on the victory and made the line hard to follow.

### Low

- **I p-011** · "to help from outside" → "to help them from outside" — 以佐其外, 其 = the calculations; the helped thing was missing.
- **I p-017** · "how much less, then, no points at all?" → "how much less, then, with no points at all?" — 而況於無算乎; the clause did not parse.
- **III p-004** · "Attack cities only when there is no other choice." → "The rule for attacking cities is to do it only when there is no other choice." — 攻城之法: the key term 法 had been dropped.
- **III p-006** · "He contends for the world … his gain can be complete." → "He always contends for the world … his gain can be kept whole." — 必 restored; 利可全 keeps 全 as "whole" per the style sheet.
- **III p-013** · "throwing your own army" → "throwing his own army" — the subject of the passage is the ruler.
- **VIII p-007** · "count on your being ready … your having made yourself" → "count on our being ready … our having made ourselves" — 吾 as our side is "we / our" per the style sheet.
- **XI p-010** · "It is the nature of war" → "So it is the nature of war" — 故兵之情主速; the only 故 dropped in the chapter.
- **VI, divergence VI.21** (note only) · "this is one of only two places where the book names a real country." → "this is one of only two places where the book names Yüeh; the other is the boat crossed by the men of Wu and the men of Yüeh in Chapter XI." — XIII also names Hsia, Yin and Chau, so the claim was false.

## Dropped on second look

- **VII p-001** · "After that, nothing is harder" — 合軍聚衆，交和而舍，莫難於軍爭 is one sequence; the English needs the connective to carry it, and it adds no meaning.
- **XI p-006** · "on scattering ground you do not fight" — after "That is why" an imperative will not stand; the statement form is required by the English, and the eight clauses after it are imperatives as the Chinese is.
- **XI p-038** · "from a thousand li away you kill his general" — 千里殺將; the commentators read it as "even at a thousand li", which the draft gives.

## For the editor

- **I p-010**: 將聽吾計 as "the general who heeds" (with Giles) or "if you heed my plans" (Sun Tzu to the king). The divergence note sets out both; the draft keeps "general".
- **XIII p-004**: "measurement" is now bare. If the editor finds it too dark, the choice is between leaving it to the note (as now) and allowing a gloss in the line.
- **STYLE.md**: VII p-006 rightly says "the generals of all three of your armies" for 擒三軍將, since p-007 names the general of the leading army (上軍將). The style sheet's 三軍 = "the whole army" should list this place as the exception.
