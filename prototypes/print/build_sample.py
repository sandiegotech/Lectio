import json, os, html

ROOT = "/Users/megalith2/Documents/GitHub/Personal/Lectio"
FONTDIR = "file:///Users/megalith2/Documents/GitHub/San%20Diego%20Tech/Tools/Gallery/Gallery/Resources/Fonts"
OUT = "/tmp/lectio_print"

d = json.load(open(f"{ROOT}/content/works/work.homer.iliad/editions/lectio-modern.json"))
sec = d["sections"][0]
paras = [s["text"] for s in sec["segments"] if s.get("kind") != "heading"]
prov = d["provenance"]

def mark(text, word, sup="°"):
    return text.replace(word, f'<span class="key">{word}<sup>{sup}</sup></span>', 1)

# Body paragraphs (escape, then add opt-in markers on first mentions)
p = [html.escape(t) for t in paras]
p[0] = mark(p[0], "Rage")
p[0] = mark(p[0], "Achilles")
p[2] = mark(p[2], "Chryses")
p[1] = mark(p[1], "Agamemnon")

CSS = f"""
@font-face{{font-family:'EBG';src:url('{FONTDIR}/EBGaramond-Regular.ttf');font-weight:400;font-style:normal}}
@font-face{{font-family:'EBG';src:url('{FONTDIR}/EBGaramond-Italic.ttf');font-weight:400;font-style:italic}}
@font-face{{font-family:'EBG';src:url('{FONTDIR}/EBGaramond-Medium.ttf');font-weight:500;font-style:normal}}
:root{{--paper:#F4EEE1;--ink:#2B2620;--soft:#6B6355;--accent:#9E3B2E;--gold:#9A7B2E;--rule:rgba(43,38,32,.18)}}
*{{box-sizing:border-box}}
@page{{size:6in 9in;margin:0}}
html,body{{margin:0;padding:0;background:#cfc9ba}}
.page{{position:relative;width:6in;height:9in;background:var(--paper);color:var(--ink);
  font-family:'EBG',Georgia,serif;display:flex;flex-direction:column;
  padding:.62in .8in .55in .8in;overflow:hidden;page-break-after:always}}
.runhead{{display:flex;justify-content:space-between;font-size:8.5pt;letter-spacing:.18em;
  text-transform:uppercase;color:var(--soft);padding-bottom:.06in;margin-bottom:.28in;
  border-bottom:.5px solid var(--rule)}}
.body{{flex:1 1 auto;font-size:11.2pt;line-height:1.62;text-align:justify;hyphens:auto}}
.body p{{margin:0 0 .9em 0;text-indent:1.1em}}
.body p:first-of-type{{text-indent:0}}
.eyebrow{{font-size:9.5pt;letter-spacing:.32em;text-transform:uppercase;color:var(--accent);
  font-weight:500;margin-top:.5in}}
.chtitle{{font-style:italic;font-size:26pt;color:var(--ink);margin:.06in 0 .02in 0;font-weight:500}}
.chrule{{width:46px;height:1px;background:var(--accent);opacity:.6;margin:.14in 0 .34in 0}}
.dropcap::first-letter{{font-size:3.1em;line-height:.82;float:left;padding:.04em .08em 0 0;
  color:var(--accent);font-weight:500;font-style:normal}}
.key{{white-space:nowrap}}
.key sup{{font-size:.62em;color:var(--accent);font-weight:500;padding-left:.02em}}
.footer{{flex:0 0 auto;margin-top:.22in;padding-top:.1in;border-top:.5px solid var(--rule);
  font-style:italic;font-size:9pt;line-height:1.45;color:var(--soft)}}
.footer b{{font-style:normal;font-variant:small-caps;letter-spacing:.06em;color:var(--accent);font-weight:500}}
.notes h4,.colo h4{{font-size:9.5pt;letter-spacing:.28em;text-transform:uppercase;color:var(--gold);
  font-weight:500;margin:.1in 0 .2in 0}}
.notes p{{font-size:10pt;line-height:1.5;margin:0 0 .7em 0;color:var(--ink)}}
.notes .nkey{{font-style:italic;color:var(--accent)}}
.colo{{margin-top:.3in;border-top:.5px solid var(--rule);padding-top:.3in}}
.colo .ed{{font-style:italic;font-size:18pt;margin-bottom:.04in}}
.colo .row{{display:flex;font-size:9.5pt;line-height:1.5;margin-bottom:.5em}}
.colo .row .lab{{flex:0 0 1.25in;font-variant:small-caps;letter-spacing:.05em;color:var(--soft)}}
.colo .row .val{{flex:1;color:var(--ink)}}
.approved{{margin-top:.32in;border-left:2px solid var(--gold);padding:.04in .18in;
  font-style:italic;font-size:10.5pt;color:var(--ink)}}
.folio{{position:absolute;bottom:.3in;left:0;right:0;text-align:center;font-size:8.5pt;color:var(--soft)}}
"""

def page_opener():
    body = f'<p class="dropcap">{p[0]}</p>' + "".join(f"<p>{x}</p>" for x in p[1:4])
    foot = ('<b>Where we are —</b> the Greek army, in the tenth year of the war at Troy. '
            'Chryses, a priest of Apollo, comes to the camp to ransom his captured daughter from Agamemnon.')
    return f'''<div class="page">
      <div class="eyebrow">Book I</div>
      <div class="chtitle">The Quarrel</div>
      <div class="chrule"></div>
      <div class="body">{body}</div>
      <div class="footer">{foot}</div>
      <div class="folio">1</div>
    </div>'''

def page_two():
    body = "".join(f"<p>{x}</p>" for x in p[4:9])
    foot = ('<b>Where we are —</b> Agamemnon has refused the ransom and driven the old priest away with threats. '
            'Rejected, Chryses prays to Apollo — and the god begins to answer.')
    return f'''<div class="page">
      <div class="runhead"><span>The Iliad · Book I</span><span>Lectio Edition · 2026</span></div>
      <div class="body">{body}</div>
      <div class="footer">{foot}</div>
      <div class="folio">2</div>
    </div>'''

def page_back():
    notes = [
      ('Rage', 'Homer’s first word is <i>mēnis</i> — not ordinary anger but a god-like, almost sacred wrath. The Lectio Edition renders it “rage” for its weight; older versions say “wrath” or “anger.”'),
      ('Achilles', 'The greatest of the Greek warriors. His withdrawal from the fighting, set in motion here, drives the whole poem.'),
      ('Agamemnon', 'Commander of the combined Greek army and king of Mycenae — “lord of men.”'),
      ('Chryses', 'A priest of Apollo, whose daughter Agamemnon holds as a war-prize. To dishonor him is to risk the god.'),
    ]
    notes_html = "".join(f'<p><span class="nkey">{html.escape(k)}.</span> {v}</p>' for k,v in notes)
    sources = "; ".join(html.escape(s) for s in prov["sourcesCited"])
    return f'''<div class="page">
      <div class="notes">
        <h4>Notes — for the curious</h4>
        {notes_html}
      </div>
      <div class="colo">
        <div class="ed">Lectio Edition · 2026</div>
        <div class="row"><div class="lab">Translation</div><div class="val">The Lectio Modern Edition — SDIT’s own rendering into clear modern English. Not a historical translation.</div></div>
        <div class="row"><div class="lab">Produced</div><div class="val">{html.escape(prov.get("retrievedDate",""))} · model {html.escape(prov.get("aiModel",""))}</div></div>
        <div class="row"><div class="lab">Sources consulted</div><div class="val">{sources}</div></div>
        <div class="row"><div class="lab">Method</div><div class="val">A synthesis of the full public-domain translation tradition, informed by the major modern renderings as research and checked against the Greek. No copyrighted translation is reproduced.</div></div>
        <div class="approved">Read and approved in full before printing. — Editor of record, June 2026.</div>
      </div>
      <div class="folio">iii</div>
    </div>'''

pages = [page_opener(), page_two(), page_back()]

def doc(inner):
    return f"<!doctype html><html><head><meta charset='utf-8'><style>{CSS}</style></head><body>{inner}</body></html>"

open(f"{OUT}/sample.html","w").write(doc("".join(pages)))
for i,pg in enumerate(pages,1):
    open(f"{OUT}/page-{i}.html","w").write(doc(pg))
print("wrote sample.html + per-page files")
