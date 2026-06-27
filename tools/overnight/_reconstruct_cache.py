#!/usr/bin/env python3
"""Reconstruct the gitignored pipeline/.cache source files FROM the committed bundle.

The overnight cloud environment cannot reach gutenberg.org / wikisource.org (egress
policy). But the committed content/ editions were themselves produced from those
sources by deterministic, idempotent segmentation (normalize.split_paragraphs /
split_verse_blocks). So we can synthesize a source text per edition such that the
recipe reproduces the committed sections byte-for-byte: emit a heading line that
matches the recipe's heading_re, then the section's segments joined by blank lines.

This lets `python3 -m pipeline.build` run fully offline and produce an identity
rebuild (only genuinely new content — e.g. freshly translated Lectio books — differs).
"""
import json, glob, os

ROMAN = ["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV",
         "XV","XVI","XVII","XVIII","XIX","XX","XXI","XXII","XXIII","XXIV","XXV","XXVI"]
ORD = ["FIRST","SECOND","THIRD","FOURTH","FIFTH","SIXTH","SEVENTH","EIGHTH","NINTH",
       "TENTH","ELEVENTH","TWELFTH"]

# edition_id -> function(i_zero_based, label) -> heading line matching the recipe regex.
HEAD = {
    "edition.meditations.casaubon-1634": lambda i, l: f"THE {ORD[i]} BOOK",          # ^THE [A-Z]+ BOOK$
    "edition.meditations.long-1862":     lambda i, l: f"{ROMAN[i]}.",                # ^[IVXL]+\.$
    "edition.iliad.pope-1715":           lambda i, l: f"BOOK {ROMAN[i]}.",           # ^BOOK [IVXL]+\.$
    "edition.iliad.butler-1898":         lambda i, l: f"BOOK {ROMAN[i]}.",          # _iliad_book_sections ^BOOK [IVXL]+\.$
    "edition.odyssey.butler-1900":       lambda i, l: f"BOOK {ROMAN[i]}",            # ^BOOK [IVXL]+$
    "edition.aeneid.dryden-1697":        lambda i, l: f"BOOK {ROMAN[i]}",            # ^ *BOOK +[IVXL]+$
    "edition.republic.jowett-1871":      lambda i, l: f"BOOK {ROMAN[i]}.",           # ^ *BOOK [IVXL]+\.$
    "edition.nicomachean-ethics.chase-1911": lambda i, l: f"BOOK {ROMAN[i]}",        # ^BOOK [IVX]+$
    "edition.the-prince.marriott-1908":  lambda i, l: f"CHAPTER {ROMAN[i]}.",        # ^CHAPTER [IVXL]+\.(\[\d+\])?$
    "edition.analects.legge-1893":       lambda i, l: f"BOOK {ROMAN[i]}.",           # ^BOOK [IVXL]+\..*$
    "edition.confessions.pusey-1838":    lambda i, l: f"BOOK {ROMAN[i]}",            # ^BOOK [IVX]+$
    "edition.hamlet.original":           lambda i, l: f"ACT {ROMAN[i]}",             # ^ACT [IVX]+$
    "edition.divine-comedy.longfellow-1867": lambda i, l: l,                          # heading IS the label
    "edition.bhagavad-gita.arnold-1885":     lambda i, l: f"CHAPTER {ROMAN[i]}",       # ^[ \t]*CHAPTER [IVXL]+$
    "edition.dhammapada.muller-1881":        lambda i, l: l,                            # heading IS the label (^Chapter [IVXL]+\..*$)
    "edition.tao-te-ching.legge-1891":       lambda i, l: f"{i+1}.",                     # inline chapter number; chapters split on blank-line gaps
}

# Editions whose recipe splits chapters on 3+ newline gaps (not split_sections) need a
# wider separator between chapters so the gap survives reconstruction.
CHAPTER_SEP = {
    "edition.tao-te-ching.legge-1891": "\n\n\n\n",
}

CACHE = os.path.join(os.path.dirname(__file__), "..", "..", "pipeline", ".cache")

def main():
    os.makedirs(CACHE, exist_ok=True)
    done = []
    for f in sorted(glob.glob("content/works/*/editions/*.json")):
        d = json.load(open(f))
        prov = d.get("provenance") or {}
        if prov.get("source") != "gutenberg":
            continue
        eid = d["id"]; sid = prov.get("sourceId")
        if eid not in HEAD:
            raise SystemExit(f"no heading rule for {eid}")
        parts = []
        for i, s in enumerate(d["sections"]):
            head = HEAD[eid](i, s["label"])
            body = "\n\n".join(seg["text"] for seg in s["segments"])
            parts.append(head + "\n\n" + body)
        sep = CHAPTER_SEP.get(eid, "\n\n")
        text = (f"*** START OF THE PROJECT GUTENBERG EBOOK {sid} ***\n\n"
                + sep.join(parts)
                + f"\n\n*** END OF THE PROJECT GUTENBERG EBOOK {sid} ***\n")
        open(os.path.join(CACHE, f"gutenberg-{sid}.txt"), "w", encoding="utf-8").write(text)
        done.append(f"{sid}:{eid.split('.')[-1]}")
    print("reconstructed:", ", ".join(done))

if __name__ == "__main__":
    main()
