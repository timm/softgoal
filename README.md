# re : keys for i* goal models, by sampling + delta debugging

SHORT (Mathew, Menzies, Ernst, Klein; arXiv:1702.05568) redone
in ~100 lines of Python. syntax.py (authoring algebra) + infer.py (interpreter) are the engine: a theory is
operator algebra (`h <= b + c` for or, `b * c` for and,
makes/breaks/helps/hurts contribution links), worlds are
ISAMP-style samples (goals walked in random order, one guess
per choice point, denial not death), and the same interpreter
replays decision seeds prudently (`replay=True`: believed goals
are settled, ors prefer settled branches). run.py is the
pipeline: sample n1 worlds with hard goals gated, take the best
by distance-to-heaven, shrink its settable labels by unanimity
filter then Zeller ddmin, assess the seed with n2 fresh
replays. REPORT_keys.md has the algorithm, the table, and the
comparison to SHORT; REPORT_extend.md argues the design covers
iStar 2.0.

    make keys                     # the whole table, all models
    make keys-lisp                # same table via rig.lisp, ~1.3s
    ./run.py models/CSServices.py
    ./run.py -n1 256 -seed 3 models/CSServices.py
    ./small.py                    # a theory file runs itself

Models: the paper's 7 i* case studies (Horkoff) plus small.py,
a hand-written buy-vs-build exemplar. Theory files are plain
python: atoms declared, rules stated with `<=`, then
`HARD = [...]` (gated in the query) and `SOFT = q1 + q2 + ...`
(engaged and labeled in every world). About 0.4ms per random
world on the largest (351 node) model; make keys runs the
corpus in ~8s (the prolog original took ~50s).

History: this dir was grown in Prolog (nfr2..nfr5.pl, gen18.pl
and friends); that lineage, the .pl models, and the converters
from piStar/istarml/ai-se JSON (also feeding the 110-model
corpus in $MOOT/re, nfr3 dialect) live on branch `prolog1`.

nfr5.lisp + rig.lisp are the same engine and pipeline in Common
Lisp (81 + 113 lines; the reader replaces syntax.py's
operator-algebra classes). Worlds are hash tables with a trail
-- an alist world was tried and retired: free snapshots, but
O(n) reads made the replay-heavy pipeline 6x slower. RNG is the
house park-miller 16807, so lisp rows are stream-different but
statistically twin to python's (Mersenne) rows; the lisp corpus
runs in ~1.3s vs python's ~5s. Two port lessons, load-bearing
in BOTH directions: an ordered body form (`seq` in lisp, a
plain list in python) is required for the derive-then-insist
idiom `[x, (x,'t')]` -- a shuffled And runs the demand first
and fiats the goal without deriving it; and each language ended
up teaching the other its world structure (python took the
trail, lisp took the hash).
