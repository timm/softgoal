#!/usr/bin/env python3
"""run.py : keys-from-sampling pipeline; port of gen18.pl.
Usage: python3 run.py [OPTIONS] models/small.py

Options:
  -n1   worlds sampled (target + unanimity)  = 1000
  -n2   replays per quality estimate         = 30
  -eps  ablation damage threshold            = 0.05
  -seed random seed                          = 1
  -z0   zeller start/min granularity         = 2
  -zup  zeller growth when stuck             = 2
  -zdn  zeller step-down after cut           = 1
"""
import sys; sys.dont_write_bytecode = True   # no __pycache__
import re, math, random
from itertools import islice
from infer import *

class o:
  def __init__(i,**d): i.__dict__.update(d)
  def __repr__(i):     return 'o'+str(i.__dict__)

def coerce(s):
  for f in (int, float):
    try: return f(s)
    except ValueError: pass
  return s

the = o(**{m[1]: coerce(m[2]) for m in
           re.finditer(r"\n\s+-(\w+)[^=\n]*= (\S+)", __doc__)})

def cli(d):
  "update(d) from -flag value pairs on the command line"
  for k in d:
    for i,a in enumerate(sys.argv):
      if a == '-'+k: d[k] = coerce(sys.argv[i+1])

def load(path):
  RULES.clear()          # one theory per Rig, even in-process
  ns = {'__name__': 'theory'}
  exec(open(path).read(), ns)
  return ns['HARD'], ns['SOFT']

def walk(g):
  yield g
  if isinstance(g,tuple) and g and g[0] in ('and','or'):
    for x in g[1:]: yield from walk(x)

# the candidate pool: what a stakeholder can SET -- leaves
# (nothing derives them) and or-alternatives (branch picks).
# HARD/SOFT never enter RULES, so the Prolog goals(_) guard
# is structural here, not legislated.
def statics(hard, soft):
  heads   = set(RULES)
  targets = {g[2] for bs in RULES.values() for b in bs
                  for g in walk(b)
                  if isinstance(g,tuple) and g[0]=='link'}
  mention = ({a for bs in RULES.values() for b in bs
                for a in syms(b)}
             | heads | set(hard) | set(syms(soft)))
  quals   = targets - heads
  leaves  = mention - heads - quals
  choicy  = {a for bs in RULES.values() for b in bs
               for g in walk(b)
               if isinstance(g,tuple) and g[0]=='or'
               for a in g[1:] if isinstance(a,Atom)}
  return mention, quals, leaves, (mention-heads)|choicy

def norm(lo,hi,x):
  return 0.5 if hi<=lo else (x-lo)/(hi-lo)

def musd(ds):
  mu = sum(ds)/len(ds)
  return mu, math.sqrt(sum((d-mu)**2 for d in ds)/len(ds))

def ddmin(test, c, n):
  if len(c)==1: return c
  sz = max(1,(len(c)+n-1)//n)
  chunks = [c[i:i+sz] for i in range(0,len(c),sz)]
  for ch in chunks:               # a chunk passes alone?
    if test(ch): return ddmin(test, ch, the.z0)
  for ch in chunks:               # dropping a chunk passes?
    rest = [x for x in c if x not in ch]
    if rest and test(rest):
      return ddmin(test, rest, max(n-the.zdn,the.z0))
  if n < len(c):                  # split finer
    return ddmin(test, c, min(len(c),the.zup*n))
  return c                        # 1-minimal

class Rig:
  "one model's pipeline: generate, reduce, assess."
  def __init__(s, hard, soft):
    s.hard, s.soft = hard, soft
    _, s.quals, s.leaves, s.settable = statics(s.hard, s.soft)
    s.mention = _
    s.q = ([g for h in s.hard for g in (h,(h,'t'))]
           + [And(alts(s.soft))])   # engage EVERY softgoal
    s.tests = 0
    s.mm    = (0,0,0,0)   # set by yardstick
    s.dbest = 0.0         # set by run

  def gen(s, n, seed=(), replay=False):
    return list(islice(sample(s.q, dict(seed), replay), n))

  def bf(s, w):
    "benefit = qualities won; footprint = leaves bought"
    return (sum(1 for q in s.quals  if w.get(q)=='t'),
            sum(1 for l in s.leaves if w.get(l)=='t'))

  def d2h(s, w):
    b, f = s.bf(w)
    nb, nf = norm(s.mm[0],s.mm[1],b), norm(s.mm[2],s.mm[3],f)
    return math.sqrt(((1-nb)**2 + nf**2)/2)

  def yardstick(s, ws):
    Bs, Fs = zip(*[s.bf(w) for w in ws])
    s.mm = (min(Bs),max(Bs),min(Fs),max(Fs))

  def candidates(s, wbest, ws):
    return [(x,v) for x,v in wbest.items()
            if x in s.settable
            and not all(w.get(x)==v for w in ws)]

  def replays(s, seed):
    return [s.d2h(w) for w in s.gen(the.n2, seed, replay=True)]

  def passes(s, seed):
    s.tests += 1; ds = s.replays(seed)
    return bool(ds) and musd(ds)[0] <= s.dbest+the.eps

  def assess(s, seed):
    return musd(s.replays(seed))

def shortname(path):
  return (path.split('/')[-1].replace('.py','')
          .replace('CS','',1))

def rig(name, hard, soft):
  random.seed(the.seed)
  r  = Rig(hard, soft)
  ws = r.gen(the.n1)
  r.yardstick(ws)
  ds = [r.d2h(w) for w in ws]
  mu0, sd0 = musd(ds)
  r.dbest, wbest = min(zip(ds,ws), key=lambda p:p[0])
  cands = r.candidates(wbest, ws)
  seed  = ddmin(r.passes, cands, the.z0) if cands else []
  mus, sds = r.assess(seed)
  print(f"{name},{100*mu0:.0f},{100*sd0:.0f},{100*r.dbest:.0f},"
        f"{100*mus:.0f},{100*sds:.0f},{len(cands)},{len(seed)},"
        f"{r.tests},{100*len(seed)/len(r.mention):.0f}")

def run(path):
  "cli entry: theory from a file path"
  hard, soft = load(path)
  rig(shortname(path), hard, soft)

def main():
  "theory-file entry: the __main__ module IS the theory"
  import __main__ as m
  cli(the.__dict__)
  rig(shortname(m.__file__), m.HARD, m.SOFT)

if __name__ == '__main__':
  cli(the.__dict__)
  if len(sys.argv) < 2 or sys.argv[-1].endswith('.py') is False \
     or sys.argv[-1].endswith('run.py'):
    sys.exit(__doc__)
  run(sys.argv[-1])
