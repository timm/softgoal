#!/usr/bin/env python3
"""paint.py: tests/run.sh CSV (stdin) + tests/t*.lisp  ==>  HTML report (stdout)."""
import csv, sys, glob, os, html, re
HERE = os.path.dirname(os.path.abspath(__file__))
lines = [l.rstrip("\n") for l in sys.stdin]
worlds = {l.split(",")[1]: l.split(",")[2:] for l in lines if l.startswith("best,")}
rows = list(csv.DictReader(l for l in lines if not l.startswith("best,")))
FAMILY = {range(1,11):"Structural", range(11,18):"Logical", range(18,23):"Replay & keys", range(23,25):"Stochastic"}
def fam(n): return next(v for k,v in FAMILY.items() if n in k)
def src(name):
    txt = open(os.path.join(HERE, name+".lisp")).read()
    note = txt.splitlines()[0].lstrip("; ")
    note = re.sub(r"^\d+\s+", "", note)
    body = "\n".join(l for l in txt.splitlines()[1:] if not l.startswith("(defparameter"))
    goals = "\n".join(re.sub(r"\(defparameter \*(\w+)\* \(quote (\(.*\))\)\)", r"\1: \2", l)
                      for l in txt.splitlines() if l.startswith("(defparameter"))
    body += "\n\n" + goals
    return note, body
OPS = {"<-","&lt;-","hard:","soft:","and","or","seq","=","makes","breaks","helps","hurts","t","f"}
def painted(name, body):
    "clauses with every atom coloured by its label in the best world"
    w = dict(kv.split("=") for kv in worlds.get(name, []))
    def tok(m):
        a = m.group(0)
        return a if a in OPS else f'<span class="{w.get(a, "x")}">{a}</span>'
    return re.sub(r"[^\s()]+", tok, html.escape(body.strip()))
def dot(cls, x, label):
    return f'<span class="d {cls}" style="left:{x}%" title="{label} = {x}"></span>'
out=[]; crashes=0; fams={}
for r in rows:
    n=int(r["model"][1:3]); fams.setdefault(fam(n),[]).append(r)
for f, rs in fams.items():
    out.append(f'<h2>{f}</h2><div class="rows">')
    for r in rs:
        name=r["model"]; note,body=src(name); crash=r["mu"]=="CRASH"
        if crash:
            crashes+=1
            plot='<div class="strip crash"><span>no worlds sampled → <code>(reduce #\'min nil)</code> → rig crashes</span></div>'
            nums='<td colspan="4" class="num dim">—</td>'
        else:
            mu,best,seed=int(r["mu"]),int(r["best"]),int(r["muSeed"])
            lo,hi=min(mu,best,seed),max(mu,best,seed)
            plot=(f'<div class="strip"><span class="rng" style="left:{lo}%;width:{hi-lo}%"></span>'
                  +dot("mu",mu,"mu")+dot("best",best,"best")+dot("seed",seed,"muSeed")+'</div>')
            nums=f'<td class="num">{r["n_filt"]}</td><td class="num">{r["seed"]}</td><td class="num">{r["tests"]}</td><td class="num">{r["pct"]}%</td>'
        out.append(f'''<details open class="row{" bad" if crash else ""}"><summary><table><tr>
<td class="name"><b>{name[4:]}</b><small>{html.escape(note)}</small></td>
<td class="plot">{plot}</td>{nums}</tr></table></summary>
<pre>{painted(name, body)}</pre></details>''')
    out.append('</div>')
ok=len(rows)-crashes
print(f'''<title>nfr5 Test Strip</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;600&family=IBM+Plex+Sans:wght@400;600&display=swap">
<style>
:root{{--bg:#f9f9f7;--sf:#fcfcfb;--ink:#0b0b0b;--ink2:#52514e;--mute:#898781;--grid:#e1e0d9;--axis:#c3c2b7;
--mu:#2a78d6;--best:#eb6834;--seed:#1baf7a;--crash:#d03b3b;--crashbg:#fbeaea;--t:#006300;--f:#d03b3b}}
@media(prefers-color-scheme:dark){{:root:not([data-theme=light]){{--bg:#0d0d0d;--sf:#1a1a19;--ink:#fff;--ink2:#c3c2b7;--grid:#2c2c2a;--axis:#383835;--mu:#3987e5;--best:#d95926;--seed:#199e70;--crashbg:#3a1c1c;--t:#0ca30c;--f:#e66767}}}}
:root[data-theme=dark]{{--bg:#0d0d0d;--sf:#1a1a19;--ink:#fff;--ink2:#c3c2b7;--grid:#2c2c2a;--axis:#383835;--mu:#3987e5;--best:#d95926;--seed:#199e70;--crashbg:#3a1c1c;--t:#0ca30c;--f:#e66767}}
body{{background:var(--bg);color:var(--ink);font:15px/1.5 "IBM Plex Sans",system-ui,sans-serif;margin:0;padding:2rem 1rem 4rem}}
main{{max-width:62rem;margin:0 auto}}
h1{{font:600 1.6rem/1.2 "IBM Plex Mono",monospace;margin:0 0 .25rem;text-wrap:balance}}
h2{{font:600 .8rem/1 "IBM Plex Mono",monospace;letter-spacing:.08em;text-transform:uppercase;color:var(--ink2);margin:2rem 0 .5rem;border-bottom:1px solid var(--grid);padding-bottom:.4rem}}
.lt{{color:var(--t)}} .lf{{color:var(--f)}}
p.lede{{color:var(--ink2);max-width:65ch;margin:0 0 .75rem}}
.verdict{{display:flex;gap:1.5rem;font-family:"IBM Plex Mono",monospace;font-size:.9rem;margin:1rem 0}}
.verdict b{{font-size:1.6rem;display:block;line-height:1}}
.verdict .c b{{color:var(--crash)}}
.legend{{display:flex;gap:1.25rem;font-size:.8rem;color:var(--ink2);font-family:"IBM Plex Mono",monospace;margin:.5rem 0 0}}
.legend i{{display:inline-block;width:10px;height:10px;border-radius:50%;margin-right:.35rem;vertical-align:-1px}}
.cols{{display:grid;grid-template-columns:16rem 1fr 3.2rem 3.2rem 3.2rem 3.2rem;font:.7rem "IBM Plex Mono",monospace;color:var(--mute);letter-spacing:.05em;text-transform:uppercase;padding:0 .5rem .25rem;gap:.5rem}}
.cols span:nth-child(n+3){{text-align:right}}
.rows{{background:var(--sf);border:1px solid var(--grid);border-radius:4px;overflow-x:auto}}
details+details{{border-top:1px solid var(--grid)}}
summary{{list-style:none;cursor:pointer;padding:.45rem .5rem}} summary::-webkit-details-marker{{display:none}}
summary:hover{{background:var(--bg)}} summary:focus-visible{{outline:2px solid var(--mu);outline-offset:-2px}}
details.bad summary{{box-shadow:inset 4px 0 var(--crash);background:var(--crashbg)}}
table{{width:100%;border-collapse:collapse;table-layout:fixed}} td{{padding:0 .25rem;vertical-align:middle}}
td.name{{width:16rem}} td.name b{{display:block;font:600 .9rem "IBM Plex Mono",monospace}} td.name small{{display:block;color:var(--ink2);font-size:.75rem;line-height:1.25}}
td.num{{width:3.2rem;text-align:right;font:.85rem "IBM Plex Mono",monospace;font-variant-numeric:tabular-nums}} td.dim{{color:var(--mute)}}
.strip{{position:relative;height:22px;margin:0 8px;background:linear-gradient(to right,var(--axis) 1px,transparent 1px) 0 0/25% 100% repeat-x;border-bottom:1px solid var(--axis)}}
.strip.crash{{background:none;border:0;font:.75rem "IBM Plex Mono",monospace;color:var(--crash);line-height:22px}}
.rng{{position:absolute;top:10px;height:2px;background:var(--axis)}}
.d{{position:absolute;top:6px;width:10px;height:10px;margin-left:-5px;border-radius:50%;border:2px solid var(--sf);box-sizing:content-box}}
.d.mu{{background:var(--mu)}} .d.best{{background:var(--best)}} .d.seed{{background:var(--seed)}}
pre .t{{color:var(--t);font-weight:600}} pre .f{{color:var(--f);font-weight:600}} pre .x{{color:var(--ink)}}
pre{{margin:0;padding:.5rem 1rem .7rem;border-top:1px dashed var(--grid);font:.8rem/1.45 "IBM Plex Mono",monospace;color:var(--ink2);background:var(--bg);overflow-x:auto;white-space:pre}}
</style>
<main>
<h1>nfr5 Test Strip</h1>
<p class="lede">Two dozen tiny goal models, each built to exercise one branch of <code>nfr5.lisp</code>'s sampler or <code>rig.lisp</code>'s keys pipeline. Each strip is distance-to-heaven on 0–100: lower is better. Under each, its clauses painted by the best world: <b class="lt">green = t</b>, <b class="lf">red = f</b>, plain = never labeled.</p>
<div class="verdict"><div><b>{ok}</b>ran</div><div class="c"><b>{crashes}</b>crashed</div><div><b>{len(rows)}</b>models</div></div>
<div class="legend"><span><i style="background:var(--mu)"></i>mu, all sampled worlds</span><span><i style="background:var(--best)"></i>best world</span><span><i style="background:var(--seed)"></i>mu of seed replays</span></div>
<div class="cols"><span>model</span><span>d2h 0 · 25 · 50 · 75 · 100</span><span>cands</span><span>seed</span><span>tests</span><span>pct</span></div>
{"".join(out)}
</main>''')
