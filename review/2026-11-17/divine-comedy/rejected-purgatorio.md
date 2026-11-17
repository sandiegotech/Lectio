# The Divine Comedy · Purgatorio verify (sections 035–067) · rejected and policies

Verified 2026-11-17 against `longfellow-1867` and the Italian (not bundled; judged from knowledge of the Petrocchi text). Patches are in `patch-purgatorio.json`.

## Policies

- **L · Latin and Occitan stay in the original, with no English gloss in the line.** Where Dante writes Latin (psalms, hymns, beatitudes, Adrian's "scias quod ego fui successor Petri", "ad vocem tanti senis") or Arnaut's Occitan, the edition prints it as Dante does. No English translation goes in the verse, whether after a dash, in brackets, or in an announcing phrase ("in his own tongue"). If a reader needs the English, it goes in the enrichment notes, not in the text. Where Dante writes the line in Italian (e.g. "Godi tu che vinci", "Beato se', grifon", "osanna"), the edition translates it as usual. Patched under this policy: 036 seg-0016 (gloss line removed), 046 seg-0037, 047 seg-0010, 051 seg-0023, 053 seg-0017 / seg-0025 / seg-0033, 054 seg-0046 (the English is turned back into Dante's Latin), 060 seg-0047. Canto XXVI's bracketed Occitan gloss (seg-0050–0052) is under "Needs the editor".
- **C · The canto's closing line stands alone.** Each canto ends on a single line (3n+1). Where the edition has a segment for it (most cantos), it is that segment, and only that line. Where the frozen segment ids leave no segment for it (036, 047, 058, 067), it is the last line of the final segment, on its own line: never run into the tercet's last line and never broken across two lines. Patched: 036 seg-0044 (run-on line split), 066 seg-0054 (broken line joined), 067 seg-0048 (half-line removed, closing line kept exactly). 047 and 058 already follow the rule.
- **T · Tercet realignment.** A segment holds one tercet. Where a gloss pushed tercets off by a line, the gloss is removed and lines move back between neighbouring segments, one patch entry per segment, with no segment added or removed. Done for 036 seg-0016–0021. 051 only needed its two four-line tercets brought back to three lines (seg-0023, seg-0031); nothing slipped there. 056 and 060 cannot be fixed this way (see below).

## Needs the editor

- **056 Purgatorio XXII · tercets off by one from seg-0012 to the end.** The padded line in seg-0012 ("The opposite vice — / throwing money away —") pushes 0012–0018 one line late, leaving seg-0019 as a one-line orphan ("it is for the contrary fault this came to me."). From seg-0020 on, each segment holds Dante's tercet one number earlier (modern 0020 = Longfellow 0019), and the closing line (154, "quanto per lo Vangelio v'è aperto") is folded into the last line of seg-0052. Realigning means rewriting all 41 segments from 0012 to 0052: 0012–0018 back on Dante 34–54 without the padding, each of 0019–0051 taking the next segment's tercet, and seg-0052 ending as the closing line alone. That would match Longfellow exactly (52 = 51 tercets + 1), but every highlight or note anchored from seg-0019 on would then point at a different tercet, which in effect renumbers the canto. Not patched; the editor should decide. The local fixes in 0002, 0014 and 0034 are patched and work either way.
- **060 Purgatorio XXVI · bracketed English prose of the Occitan, seg-0050–0052.** Three segments hold editorial apparatus ("[The Occitan, in plain English: …]"), so the canto has 53 segments for 148 lines (Longfellow 51; ideal 50). Under Policy L the gloss should come out of the verse and go to the enrichment sidecar. Segments cannot be removed or emptied under the frozen-id rule, and no Dante lines are left to put in them. The editor has to decide whether to retire the three segment ids or keep a note-style segment. seg-0053 (closing line) is already correct.

## Rejected

- 042 seg-0017 · read-aloud low · "not so much that … it hid what the distance had hidden before". The double negative is Dante's ("ma non sì che … non dichiarisse"), the sense is intact, and the proposed fix ("it failed to show") is no clearer.
- 047 seg-0051 · form low · split the closing line into its own segment. Under frozen ids there is no 52nd segment, and the closing line is already on its own line (Policy C).
- 058 seg-0051 · form low · same request, same answer (Policy C).
- 048 seg-0048 · read-aloud low · "the hard bit". The next half-line ("meant to hold a man inside his bounds") settles the sense at once, and the proposed "in the mouth" lengthens the line for nothing (Dante: "quel fu 'l duro camo").
- 049 seg-0013 · form low · render "Beati misericordes" in English. Rejected under Policy L. The inconsistency the reviewer saw was Canto XII's English beatitude, which is now patched back to Latin.
- 056 seg-0002 · register low · English for "Beati … sitio". Rejected under Policy L. The word itself was wrong ("sitio" for Dante's "sitiunt") and is patched.
- 059 seg-0043 · register low · "Virum non cognosco" to English. Rejected under Policy L.
- 063 seg-0001 · register low · "Beati quorum tecta sunt peccata" to English. Rejected under Policy L.
- 064 seg-0006 · register low · "ad vocem tanti senis" to English. Rejected under Policy L.
- 067 seg-0004 · register low · "Modicum, et non videbitis me" to English. Rejected under Policy L. Dante's Italian aside "sorelle mie dilette" is correctly in English. The English for the Latin belongs in enrichment, as the reviewer also suggested.
- 036 seg-0016 · reviewer's re-break of 0017–0021 was adopted in substance. The one change is in seg-0021: "And Virgil answered" now opens that segment, as "E Virgilio rispuose" opens Dante's tercet (61), rather than closing seg-0020.
- 056 seg-0012 · form medium · the tercet re-break proposed in the report. Deferred to the editor (above), not rejected on the merits.
- 060 seg-0050 · form medium · remove seg-0050–0052. Deferred to the editor (above). Correct on the merits.
