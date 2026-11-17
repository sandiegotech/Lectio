# Genesis · Lectio Vernacular · verify 2026-11-17 · rejected and deferred

Checked against KJV 1611 (bundled) and the Hebrew (from my own knowledge; not bundled).

## Policies

1. **Hebrew poetry set as verse (2:23, 3:14–19, 4:23–24, 9:25–27, 25:23, 27:27–29, 27:39–40).**
   The charter's rule stands: these poems must print as lines. The pipeline can't carry it yet
   (see "Needs the editor"), so this run patches none of them. The wording of each poem is
   unchanged and correct. Only the lineation is missing.
2. **Cruxes stay open in the sentence.** Where the Hebrew is unknown or ambiguous, print the
   received text and leave the ambiguity where the Hebrew leaves it. A scholar's guess or an
   emendation goes in a `divergences` note, not into the verse. This is the same rule the
   edition already follows for Nephilim and El Shaddai. Patched: 6:14 "gopher wood", 14:20 "he
   gave him", 16:13 the received reading, 3:22 God's sentence left unfinished.
3. **Key words.** Restore a word only when it has its own Hebrew word and the rendering dropped
   it (1:14 "signs"). Keep a pilot rendering when the English idiom carries the meaning or it
   follows a recognized reading (2:17, 3:16, 1:27; see below). *hesed* is "kindness" (charter),
   so 21:23 is patched. *shamayim*: "sky" for the physical sky (birds, stars, dew, rain, the
   windows of the sky, the Babel tower, voices and fire coming "from the sky"), and "heaven" when
   it is a divine title or God's place (24:3, 24:7 "God of heaven", 28:17 "the gate of heaven",
   which matches "maker of heaven and earth" at 14:19 and 14:22).
4. **Spelling.** "seedtime" is one word (8:22, patched once; no other instance).

## Rejected

- 1:27 `seg-0007` (medium) "he created it": Fox renders it the same way. "It" agrees with "humanity" in 1:26–27, and the turn from singular to plural ("it" … "them") is still there. This is a deliberate pilot choice and not a stumble.
- 2:17 `seg-0005` (medium) "you die": In English, the present tense is the plain way to state a certain consequence ("eat it and you die"), and here it carries the force of *mot tamut*. "Surely" adds church register. The serpent's "You will not die" (3:4) still answers it. The pilot reads the same.
- 3:16 `seg-0004` (medium) "pains in childbirth": Reading *itsvonekh weheronekh* as one idea ("your pain in pregnancy") is the mainstream reading (NRSV, NJPS, Alter). Nothing is dropped. The pilot reads the same.
- 6:5 `seg-0002` (low) "every shape the thoughts of the heart took": This reads aloud cleanly and keeps *yetser* as an image. The proposed wording is a matter of taste.
- 7:23 `seg-0005` (low) "And he wiped out": The Masoretic pointing is active (*vayyimach*). The passive comes from the versions. God is the subject from 6:7 ("I will wipe…"), and the next sentence already says "They were wiped off the earth."
- 28:12 `seg-0003` (low) "its top reaching the sky": This echoes 11:4, where the Babel tower has "its top in the sky" (*rosho vashamayim*). The stairway answers the tower. Jacob sees a stairway to the sky, then names the place "the gate of heaven." The words differ, and the move from sight to meaning is the point.

## Needs the editor

- **Verse inside the Bible Vernacular (pipeline change).** `_bible_vernacular_edition` in
  `pipeline/recipes.py` joins the paragraphs with `"\n\n"` and calls `build_section(..., form="prose")`.
  `split_paragraphs` in `pipeline/normalize.py` then collapses every single newline inside a
  paragraph into a space (`re.sub(r"\s*\n\s*", " ", p)`). A blank line would start a new segment
  and break the spine-length check. So no line break inside a Genesis segment can survive the
  build. Verse works such as the Divine Comedy keep their lines only because the whole edition
  is built with `form="verse"` (`split_verse_blocks`, kind `verse_block`). Needed: let a prose
  section keep `\n` inside a paragraph (e.g. a `split_paragraphs(keep_lines=True)` used by the
  Bible recipe), and check that the app's paragraph renderer honors those newlines. Then patch
  the seven poems as lines with segment ids unchanged: 2:23 (`ch2 seg-0007`), 3:14–19 (`ch3
  seg-0003..0005`), 4:23–24 (`ch4 seg-0006`), 9:25–27 (`ch9 seg-0006`), 25:23 (`ch25 seg-0004`),
  27:27–29 and 27:39–40 (`ch27 seg-0005`, `seg-0008`). The pilot already sets 2:23 and 3:14–19 as
  verse.
- **Notes for the open cruxes** (policy 2): consider `divergences` entries for 6:14 *gopher*
  ("cypress" is a guess), 14:20 (who gave the tenth), and 16:13 (the "and lived" emendation, which
  could join the El-roi note). A patch can't add these.
- **Pilot sync:** if 1:11, 1:14 and 3:22 are applied, make the same changes in
  `print/experiments/the-bible-vernacular-pilot.md`. The charter treats the pilot as the register
  standard.
