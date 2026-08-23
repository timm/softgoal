#!/usr/bin/env python3
"""to-lisp.py : regenerate models/*.lisp (and small.lisp) from
the python theory files, for rig.lisp. Run after editing models."""
import sys; sys.dont_write_bytecode = True
import glob
from syntax import *

BAG = {'t':'makes','f':'breaks','ttf':'helps','fft':'hurts'}

def sx(g):
  if isinstance(g,Atom): return g.name
  if isinstance(g,tuple):
    if g[0]=='link': return f"({BAG[g[1]]} {g[2].name})"
    if g[0]=='=':    return f"(= {g[1].name} {g[2]})"
    return "("+g[0]+" "+" ".join(sx(x) for x in g[1:])+")"
  if isinstance(g,Link): return sx(('link',g.bag,g.x))
  if isinstance(g,And):  return "(and "+" ".join(sx(x) for x in g.xs)+")"
  if isinstance(g,Or):   return "(or "+" ".join(sx(x) for x in g.xs)+")"
  raise ValueError(g)

def port(path):
  RULES.clear()
  ns = {'__name__': 'theory'}
  exec(open(path).read(), ns)
  out = path.replace('.py','.lisp')
  with open(out,'w') as f:
    f.write(f";;;; {out} : GENERATED from {path} by to-lisp.py\n")
    for h,bs in RULES.items():
      for b in bs: f.write(f"(<- {h.name} {sx(b)})\n")
    f.write("(defparameter *hard* '("
            + " ".join(h.name for h in ns['HARD']) + "))\n")
    f.write("(defparameter *soft* '("
            + " ".join(sx(x) for x in alts(ns['SOFT'])) + "))\n")
  print(out)

if __name__ == '__main__':
  for p in sorted(glob.glob("models/*.py")) + ["small.py"]: port(p)
