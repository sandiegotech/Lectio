# The Divine Comedy · Paradiso verify (sections 068–100) · rejected and policies

Verified 2026-11-17 against `longfellow-1867` and the Italian. The Italian is not bundled, so I judged it from my own knowledge of the Petrocchi text. Patches are in `patch-paradiso.json`: 174 entries (95 medium, 79 low) plus a null entry for 082. Many medium entries are whole-segment realignments: 074 seg-0038–0043, 075 seg-0039–0050 and 097 seg-0012–0050. Of the reports' 42 mediums, 41 are confirmed and 1 is rejected (082).

## Policies

These follow the Purgatorio verifier's Policies L and C so the three canticles share one rule.

- **L · Latin stays in Latin, with no English gloss in the line.** Where Dante writes Latin, the edition prints it as he does. No English goes in the verse after a dash, in brackets, or in place of the Latin. A reader who needs the English gets it from the enrichment notes. Where Dante gives the words in Italian, the edition translates them as usual: "Sperino in te" in XXV 73 stays English at 092 seg-0025, while "Sperent in te" in XXV 98 goes back to Latin, as Dante does himself. "Hosanna" as an English word is kept (075 seg-0010, 099 seg-0045). Patched under this policy:
  - 074 seg-0001: lines 2–3 of the hymn turned back from English into Latin.
  - 079 seg-0031: "non decimas, quae sunt pauperum Dei".
  - 083 seg-0012: "'Ave'", with the gloss "the angel" dropped.
  - 085 seg-0031: the dash glosses removed from DILIGITE IUSTITIAM / QUI IUDICATIS TERRAM.
  - 092 seg-0033: "Sperent in te".
  - 099 seg-0004: "Miserere mei", given whole.
  - 099 seg-0020: "sine causa".
  - 082 seg-0010 (Cacciaguida's Latin) and 090 seg-0043 ("Regina coeli") already follow the rule.
- **C · The canto's closing line stands alone.** Each canto ends on one line (3n+1). That line is the canto's last segment and nothing else. It is never folded into the last tercet and never broken across two lines, and the tercet before it ends where Dante's does: no stranded word leads into it. If frozen ids leave no segment for the closing line, it is the last line of the final segment, on a line of its own. Patched:
  - 075 seg-0049/0050.
  - 086 seg-0049/0050.
  - 087 seg-0050: two lines joined into one.
  - 088 seg-0047/0048: a mid-phrase split mended.
  - 097 seg-0050.
  - 100 seg-0048/0049: the stranded "by" now opens the last line of the poem.
  - 084 is under "Needs the editor".
- **T · Tercet realignment.** A segment holds one tercet. Where segments had slipped off the source stanzas, lines move back between neighbouring segments, one patch entry per segment, with no segment added or removed. Wording is kept except where a line straddled two tercets and had to be rewrapped. After patching, every Paradiso canto except 084 has Longfellow's line count and segment count, with three lines per segment and one closing line. Done for:
  - 074 seg-0038–0043: also removes the four-line seg-0043 and the extra line.
  - 075 seg-0002–0004 and seg-0039–0050.
  - 097 seg-0012–0050: a straight one-line shift, rewrapped at 0012–0014, 0018–0020, 0034–0035 and 0037–0038.
  - 086 seg-0049/0050.
  - 099 seg-0014/0015 and seg-0022/0023: half-line spills. The rest of 099 was already on its tercets; Dante's own enjambments were left alone.
  - Small half-line spills also fixed: 073 seg-0010/0011 and 081 seg-0002/0003.
  - Four-line tercets brought back to three: 070 seg-0028, 076 seg-0024 and seg-0040.
- **Q · Quotation marks (mechanical, not patched entry by entry).** The edition's house style is straight quotes: `"` for speech and `'` for speech within speech. Normalize the curly quotes in 072, 099 and 100 at apply time. Justinian's speech in 073 got straight quotes added at seg-0001 and seg-0048.
- **S · Leading spaces (mechanical).** Strip the leading space from every continuation line in 074. The segments patched here (0001, 0030, 0038–0043) are already written without them.

## Needs the editor

- **084 Paradiso XVII · closing line has no segment of its own.** The Lectio has 47 segments to Longfellow's 48. Every tercet up to seg-0046 is aligned, and the closing line ("nor on any other proof that does not show.", XVII 142) is the fourth line of seg-0047. Giving it its own segment means adding seg-0048, which the frozen-id rule forbids. As it stands it is on its own line inside the last segment, so it already meets the fallback in Policy C. The difference is that Compare pairs Lectio seg-0047 with Longfellow seg-0047 + seg-0048. The editor decides whether to add the segment.

## Rejected

- 082 seg-0037 · fidelity medium · "the relative 'which' points to Montemalo". In "Non era vinto ancora Montemalo / dal vostro Uccellatoio, che, com' è vinto / nel montar sù, così sarà nel calo", the "che … è vinto" is Montemalo. Florence's Uccellatoio outdid Rome in its rise and will outdo it in its fall. That is the standard reading, and the Lectio says exactly this. The proposed fix would not change the meaning; it would only reshuffle the line.
- 090 seg-0030 · fidelity low · "greatest fire" changed to "greater fire". Italian "il maggior foco", with the article, is a superlative. Christ has already risen out of sight (seg-0029), so "greatest" can only mean Mary, the greatest of the lights left.
- 069 seg-0007 · register low · "God-shaped kingdom". This is an exact rendering of "deiforme regno". The supposed catchphrase echo is too faint to justify a change.
- 099 seg-0003 · voice low · partly rejected. "you see" is Dante's ("sì come tu vedi") and stays; only the filler "ranged … there" is cut.
- 100 seg-0015 · adopted, with one note. The reviewer's "we must believe" is right, because "non si dee creder" with the negative carried into "no creature's eye" gives the same sense. The Lectio's "you cannot believe" nearly said the opposite, so the issue stands as a fidelity medium.
- 074 seg-0040 · the report's proposed cut was adopted in substance but started one segment earlier, at seg-0038, because "by one road or the other" (VII 114) had already spilled into seg-0039. 074 seg-0033/0034 ("as far below as … / to rise above") follows Dante's own enjambment ("poi, / quanto") and was left as it is.
- 072 seg-0001 · form low · curly quotes. Covered by Policy Q and not patched.
- 074 seg-0002 · form low · leading spaces. Covered by Policy S and not patched.
- 100 · Longfellow appendix of sonnets (longfellow seg-0050–0063). This is a recipe problem in the Longfellow bundle, already noted, and is out of scope here.
