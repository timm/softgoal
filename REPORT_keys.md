# REPORT_keys.md : keys via sampling + delta debugging

nfr5 experiments of 2026-08-14/15 (Apple Silicon, seed 1).
Since 2026-08-15 the engine is syntax.py + infer.py, driven by run.py (python); the
prolog originals (nfr5.pl, gen18.pl, the .pl models) that this
note's prose quotes live on branch `prolog1`. A Common Lisp
port of engine AND pipeline (nfr5.lisp + rig.lisp, 2026-08-16,
park-miller rng) reproduces this table statistically -- same
mu/best/seed-size story every row, stream-luck differences only
-- with the corpus at ~1.3s vs python's ~5s; see README. Port equivalence
was verified the hard way: an early python table diverged on
KidsandYouth (a best it could not replay) and the whole-world
prudence check traced it to the query engaging ONE softgoal
(SOFT is an or) instead of all of them; one And() fixed it and
every row fell into the prolog regime. One 90-line interpreter both
generates worlds and replays decisions; a unanimity filter then
Zeller's ddmin shrink the best world's labels to a minimal
seed. On Horkoff's seven Kids Help Phone goal models, seeds of
1-13 labels (1-5% of a model's atoms) steer fresh samples to
near the best world found in 1000 unguided runs, with every
hard goal satisfied in every world. Reproduce: `make keys`, or
`./run.py models/CSServices.py`.

## 1. The algorithm

One interpreter, `isamp(Goals, Beliefs, World)`. Beliefs are
`atom=value` pairs; the world returned is the beliefs plus every
label the run committed to. Two calls, differing only in the
belief list:

    isamp(Q, [],              W)     % generate
    isamp(Q, [replay=on|Seed],W)     % replay / check

`replay=on` is itself a belief. Two interpreter rows fire only
when it is present: or-branches whose atoms are all already
believed are preferred over random branch choice, and
contribution links onto already-believed atoms are skipped
rather than re-drawn. Without those rows a partial seed is
shredded -- every helps/hurts edge onto a seeded atom re-rolls
its coin and, on mismatch, denies the clause (measured: three of
seven models then optimize not at all).

The pipeline:

    Q  = [h1, h1=t, ..., hn, hn=t, [and|Softs]]
         -- hard goals gated: derive each, insist on it, THEN
            engage every softgoal. Order matters: gating after
            soft engagement is infeasible (0/1000 worlds).

    GENERATE  Ws = N1=1000 x isamp(Q, [], W)
              score each: benefit  = qualities labeled t
                          footprint= leaves bought (labeled t)
              d2h = dist to (max benefit, min footprint),
                    normalized over these 1000
    BEST      W* = argmin d2h; d2h* is the reference optimum
    SEED0     controllable labels of W*: atoms that are leaves
              (not rule heads) or listed in an [or|Alts] body
    FILTER    drop from SEED0 every label present in ALL 1000
              worlds. Unanimity, not a percentage: a label the
              model forces everywhere carries zero information
              and replay re-derives it free. (A 90% threshold
              was tried and retired: a label at 95% is NOT
              guaranteed, and dropping it left replay re-winning
              it against a 1/3 coin -- measurable error.)
    DDMIN     Zeller ddmin over the filtered candidates
              test(S) = mean d2h of 30 x isamp(Q,[replay=on|S])
                        =< d2h* + 0.05
    ASSESS    reps=30 more x isamp(Q, [replay=on|Seed]) -> mu, sd
              (one reps constant serves tests and assessment; a
              separate bigger N2 bought only cosmetic error-bar)

Feature extraction here is three cuts, each removing a
different redundancy. SEED0 removes the UNACTIONABLE (labels a
stakeholder cannot set; seeding a consequence fakes benefit and
blocks its subtree -- measured, such seeds score worse than
random). FILTER removes what the MODEL makes redundant
(topology-forced labels; cheap, pure counting). DDMIN removes
what the OBJECTIVE makes redundant (settable, non-forced labels
that still do not move d2h; expensive, needs replays). None of
the three subsumes another, and running the cheap cuts first is
why the corpus runs in seconds, not minutes (prolog-era: 51s filtered vs 139s; the python port does the whole table in ~5s, the lisp port in ~1.2s).

Sanity anchor (run before trusting anything): seeding the WHOLE
best world replays it term-identically, 100/100, on the vanilla
interpreter -- generator and checker are provably one device;
prudence questions only arise for partial seeds.

## 2. The table

d2h x100; seed 1; python engine (`make keys S=1`, 2026-08-17):

    dataset          mu  sd  best muSeed sdSeed cands |seed| tests %seed
    Counselling      56  16   6    11      6     34    13    194    4
    CounsellingMgmt  43  20   0     7      5     22    10     89    5
    FDandMarketing   50  13   7    13      8     38    10    118    3
    ITDepartment     58  23   0     6      9     22     5     72    4
    SAProgram        47  16   8    19      9     15     6     63    5
    Services         49  12  10    17      8     35     8     42    2
    KidsandYouth     70  18  35    35      0      5     1      4    1
    small            49  10  35    40      3      6     2      8   15

Whole corpus: 4.7s python, 1.2s in the lisp port (`make
keys-lisp`, park-miller rng: stream-different, statistically
twin rows), most of it ddmin (cost = #tests x 30 replays; the
unanimity FILTER roughly halved #tests -- prolog-era
measurement of the same pipeline: 139s unfiltered vs 51s --
filter-first is strictly better on time, seed size, AND mu).
Every row: hard goals hold in 100% of sampled and replayed
worlds; on the seven case studies muSeed sits 1.8-2.8 baseline
standard deviations below the random mean. KidsandYouth: one
label reaches its structural floor exactly, sd zero.

FDandMarketing's gap (13 vs 7; Counselling shows the
same signature this draw) is not pipeline error:
its best worlds are partly luck. The model has 177 helps edges
against 1 hurt -- the corpus's most coin-driven -- and even
seeding ALL its controllable labels fails to reproduce its best
world's d2h. Fortune is not replayable; only choices are. The
(helps+hurts)/edges ratio predicts this replayability gap.

## 3. Comparison to SHORT (re17.pdf)

Same corpus (largest model 351 nodes there, 353 atoms here),
same three conclusions: keys exist; keys are easy to find; keys
set the rest of the model. SHORT reports "often, just 12%";
this pipeline lands at 1-5% on the case studies (median ~4%). Differences:

- Machinery: SHORT is a bespoke polynomial-time ranker built to
  summarize the whole trade space. Here the finder is 1000
  random worlds and the reducer is off-the-shelf ddmin; the
  interpreter never changes.
- Hard goals: SHORT scores %goals-satisfied as an objective
  (f2); here hard goals are a gate, all covered by
  construction, and the objective is soft coverage vs cost.
- Validation: SHORT compares against NSGA-II on accuracy;
  here the check is replay -- the seed must steer fresh
  samples back to the reference optimum, mu/sd reported.
- New observation: the luck/choice split. Some models' optima
  are partly unreplayable coin fortune, bounding what ANY key
  set can guarantee; SHORT has no analogous notion.

## 4. Is ddmin-as-feature-selection new?

ddmin is Zeller & Hildebrandt's failure-input minimizer
(TSE 2002). Its use as a *feature selector against a stochastic
objective* -- shrink an assumption set while a sampled quality
statistic stays within tolerance -- appears rare but not
unprecedented. Closest neighbors found:

- Prediction-preserving input minimization: delta-debug an
  input to the minimal fragment keeping an ML model's
  prediction (Suneja et al., "Probing Model Signal-Awareness
  via Prediction-Preserving Input Minimization", 2020,
  arXiv:2011.14934).
- DD-CAM: ddmin over a vision model's representational units
  for minimal sufficient explanations (arXiv:2602.19274).
- SkillReducer: ddmin over semantic clauses with routing
  correctness as the predicate (arXiv:2603.29919).
- Algorithmic descendants if #tests matters: ProbDD
  (arXiv:2408.04735) and WDD (ICSE 2025).

None target requirements/goal models, and none anchor the test
predicate to a sampled optimum with a replay device; that
combination seems to be this note's contribution. Classic
backward feature elimination (RFE) differs in assuming a
per-feature score; ddmin needs only the pass/fail test, which
is what a stochastic simulator can honestly provide.

## 5. Threats

- Single RNG seed for the headline table; seed-loop intervals
  not yet run (ddmin is path-dependent, |seed| wobbles a few
  labels across seeds).
- eps=0.05 slack is spent in full by ddmin; muSeed-best gaps sit
  near it by construction. All constants are named facts atop
  gen18.pl (n1, reps, tol, rseed). Anchoring Tol to the replayable
  floor (full-controllable-seed mu) would tighten FD-like rows.
- d2h normalization comes from the same 1000 worlds that supply
  the best; no holdout.
- One corpus, one dialect (nfr3-style `<--` models from a
  single research group).
