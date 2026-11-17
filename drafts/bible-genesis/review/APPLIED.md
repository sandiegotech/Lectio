# Genesis 35–50 · review and fix pass · 2026-11-17

One reader. I checked against the bundled KJV 1611 and against the Hebrew from my own knowledge (it is not on disk, so a printed text should confirm the readings below). Sixteen reports are in this folder. Every finding was checked a second time before any edit was made. I changed text only: no paragraph was added, removed or reordered, and no spine was touched. The JSON keeps the drafter's formatting byte for byte; my formatter reproduces the ten untouched files exactly.

Self-check after the edits: `python3 drafts/bible-genesis/selfcheck.py` passes. All 16 chapters are covered verse for verse and the total is 12,804 words. I also checked coverage paragraph by paragraph against the KJV. No paragraph has text belonging to a verse outside its range, and none is missing a verse.

Grades: 15 A, 1 B (chapter 41, on the first pass; A after the second look). No high-severity issues. One medium, which I dropped. Six lows, all applied.

## Changes applied (all low)

| Verse | Old → new | Why |
| --- | --- | --- |
| 37:8 | "Are you going to be king over us? Are you going to rule us?" → "Are you **really** going to be king over us? Are you **really** going to rule us?" | The Hebrew doubles both verbs (*hamalokh timlokh … mashol timshol*). The edition renders that emphasis with "really" (18:13, 27:21, and 37:10 in the same paragraph). |
| 41:9 | "Today I **must** bring up my offenses." → "Today I bring up my offenses." | "must" is not in the Hebrew (*ani mazkir hayom*). It adds a reluctance the text does not state. |
| 42:16 | "stay **in chains**" → "stay **confined**" | It is the same verb as 42:19 (*'asar*), which the draft renders "stay confined" there. "in chains" sharpens it and breaks the echo. |
| 43:28 | "And they **knelt and bowed**." → "And they **bowed their heads and bowed down**." | *qadad* is bowing the head, not kneeling. The edition renders the same pair "bowed his head and bowed down" at 24:26 and 24:48. |
| 49:13 | "his flank will **rest on** Sidon" → "his flank will **be at** Sidon" | The Hebrew has no verb (*veyarkhato al-Tsidon*). "rest" adds an image. |
| 50:17 (×2) | "forgive the **crime** of …" → "forgive the **offense** of …" | *pesha* paired with *chatta't* is "offense … sin" at 31:36. "crime" is courtroom register. |

## Dropped on second look

- **41:43 "the chariot of his second-in-command"** (medium in report 41). I flagged it as a misreading of *mirkevet hammishneh asher lo* ("his second chariot", KJV). On a second look it holds. *mishneh* is used of the second-ranking man elsewhere (2 Kings 23:4, 2 Chronicles 28:7), and NJPS, NRSV and Alter all read it as the viceroy's chariot. That fits the scene: Joseph is given the deputy's rank and its chariot. Left as drafted. Chapter 41 is A once this is dropped.

Considered and not raised (recorded so they aren't raised again):
- 35:4 "buried" for *taman*: it means "hide", and hiding in the ground is the usual sense (Joshua 7:21).
- 36:6 "another land": the Hebrew "to a land" is elliptical, and the versions fill it in differently. The draft's word is the least it can supply.
- 37:2 "a boy among the sons of Bilhah": within the range of *na'ar et*.
- 40:7 "so dark" for *ra'im* (of faces): an idiomatic equivalent.
- 43:18 the two verbs are reordered ("fall on us and overpower us"). The sense is unchanged.
- 47:12 "down to the mouths of the little ones": keeps the Hebrew's *lefi*.

## Recommendations on the cruxes in NOTES.md

1. **37:3 *ketonet passim***: keep "an ornamented coat". It commits to less than "many colours" or "long-sleeved", and a reader needs the coat to be visibly special. Policy 2 is met if a `divergences` note gives both readings. "a coat of passim" would cost the reader the story's central object.
2. **37:28, 36: Ishmaelites / Midianites / Medanites**: keep all three as the Hebrew has them, with the loose subject at 37:28, and add a note. Never harmonize.
3. **49:10 "until Shiloh comes"**: keep the received text. It needs a `divergences` entry listing the four readings.
4. **49:5 *mekheroteihem***: keep "their weapons". It is the majority modern reading, and no open phrasing makes a sentence. Mention it in the 49 note.
5. **49:22–26**: keep the received pointing throughout ("fruitful bough", "from there, the Shepherd", "my ancestors"). One note can cover the block.
6. **49:14, 20, 21**: keep as drafted. No note is needed beyond the 49 note.
7. **36:24 "the yemim"**: keep, on the "gopher wood" model. **36:26 "Dishan"**: keep the received text under policy 2 and add a short note, because the reader will see two "sons of Dishan". This is the one place where the received text actively confuses. If the editor would rather read "Dishon" with KJV and Chronicles, it is defensible as a scribal slip rather than a guess, but it would be the edition's first emendation in a list. **36:2/14 "daughter"** and **36:39 "Hadar"**: keep.
8. **38:21–22 "the consecrated woman"**: keep. The change of word is the point of the scene, and it needs a note.
9. **41:40, 41:43, 41:56, 41:34**: keep all as drafted. "Joseph opened all that was in them" is rough, but it is the Hebrew.
10. **47:21, 47:31**: keep the received text, with two notes (47:31 explains Hebrews 11:21).
11. **48:22 "one shoulder of land"**: keep. *shekhem* as a topographic word means a ridge or slope, so "of land" makes explicit a sense the word already carries rather than adding a new idea. Give it a note that carries the Shechem pun.
12. **45:24 "Do not be stirred up on the road"**: keep. It reads aloud acceptably and keeps both senses open. If the editor wants one sense, "Do not quarrel on the road" is the usual reading.
13. **39:6 "well built and beautiful"** and **39:14, 17 "to play with"**: keep both. "shapely" would read oddly of a man, and the 26:8 echo is worth the slight ambiguity.
14–17. **35:7, 35:16/48:7, 35:22, 40:16, 40:19, 46:13, 46:15, 50:20**: accept as drafted.

## Still for the editor

- Write the `divergences` notes. The minimum set is cruxes 1, 2, 3, 7 (Dishan), 8, 10 and 11.
- Lineate chapter 49 once the pipeline keeps `\n` inside a segment.
- Integrate into `pipeline/modern/bible-genesis.json`. Nothing outside `drafts/bible-genesis/` was touched.
