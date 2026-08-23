# REPORT_extend.md : nfr5.pl and iStar 2.0

(2026-08-15: the prolog engine this note analyses moved to
branch `prolog1`; main now carries the python port nfr5.py,
same semantics, algebra surface syntax. The analysis below
still holds of the design.)

nfr5.pl is a 30-line world sampler for goal models. This note
records (a) the rules of iStar 2.0, (b) the semantics of this
interpreter, (c) the argument that the interpreter extends to
iStar 2.0 at near-zero cost, and (d) a demonstration that the
soft-link machinery obeys Zadeh's extension principle: with the
fuzz removed, the interpreter is classical logic again.
All numbers below are from runs of 2026-08-14 (SWI-Prolog,
Apple Silicon).

## 1. The rules of iStar 2.0

iStar 2.0 (Dalpiaz, Franch, Horkoff 2016, arXiv:1605.07767;
restated with a fuller example as a chapter of the Yu
festschrift, doi:10.1007/978-3-031-72107-6_5, cross-checked
against this note 2026-08-16) is the community-standard cleanup
of Yu's i* goal-modeling language. Its vocabulary:

- **Intentional elements**: goal, task, quality (nee softgoal),
  resource -- things an actor wants, does, values, or uses.
- **Refinement**: AND (all children) and OR (any child), goals
  and tasks only; a parent is AND- or OR-refined, never both,
  and is parent in at most one refinement -- exactly the
  one-rule-per-head, one-or-form discipline of this dialect.
- **Contribution links**: make, help, hurt, break -- from any
  element onto a *quality*. Contributions argue about a
  quality's label; they never derive it the way refinement does.
- **Other links**: neededBy (task needs resource),
  qualification (quality qualifies an element).
- **Actors** own elements inside a boundary; **dependencies**
  (depender, dependum, dependee) cross boundaries, and a
  depender is *vulnerable* to its dependee's failure.
- **Labels**: satisfied / denied, with evaluation (how labels
  propagate) deliberately left outside the core spec.

## 2. Semantics of this interpreter

One query: `isamp(Goal, Inits, World)`. `Inits` is a list of
`atom=Value` beliefs (learned assumptions plug in here); `World`
comes back as `Inits` plus every label the run committed to.

The interpreter is two tables. `todo/3` characterizes one surface
goal as one of five kernel forms; `do/3` interprets kernel
forms. The cut in `isamp/3` makes the first `todo` row that
fires the only row, which also commits every random draw
(ISAMP: one guess per choice point, no backtracking into
alternatives -- Crawford & Baker, AAAI 1994).

Kernel forms:

    []          nothing to do
    [H|T]       do H, then T
    chk(Z,V)    a believed value exists; it must unify with the
                demanded one, or the world dies
    add(X=V)    record a fresh label
    (X <-- Bs)  derive: pick one body at random, believe X=t,
                run the body; if it fails and X is an atom,
                label X=f instead (denial, not death)

Surface forms, via `todo`:

    X=V         demand: chk if believed, add if fresh
    [and|Xs]    shuffled conjunction; bare lists run in order
    [or|Xs]     commit to one random element
    makes(X)    X=t          breaks(X)   X=f
    helps(X)    X=V, V drawn from [t,t,f]
    hurts(X)    X=V, V drawn from [f,f,t]
    atom        if believed: done. else if it has clauses:
                derive. else: abduce to t.

One belief is special: `replay=on`. With it in the belief list,
two extra todo rows fire (added 2026-08-15, see
REPORT_keys.md): a goal whose atoms are ALL believed is done
without work, and an or prefers a fully-believed branch. This
turns the same interpreter into a prudent replayer of decision
seeds; without the belief, both rows are inert and sampling is
untouched. Seeding the WHOLE best world needs neither row --
memoization alone replays it term-identically.

Doctrine ("B" in the lab notebook): a bare atom is a *label*,
never a demand. Only an explicit `X=V` (and hence `makes`,
`breaks`) can kill a world. Failed derivations are
denials (`X=f`), recorded and lived with. Leaves are
abducibles: no clauses means "you told me no other way, so
assume true". A shared subgoal or a cyclic one is computed
once and its label reused (the `memberchk` row), which both
terminates cycles and stops diamonds from being resampled
into spurious contradiction.

Every world therefore reads three-valued: t (satisfied),
f (denied -- argued against and lost), and unseen (never on
the committed path). Denied and unseen are different facts;
label-propagation schemes that share one "unknown" value
conflate them.

There is no hard-goal form. An earlier draft had one --
`must(X)`, expanding to `[X, X=t]` (derive, then insist) -- and
a corpus experiment killed it (2026-08-14): over
models/CSServices.pl with all 186 softgoals engaged,
must-wrapped hard goals survived 0 of 1000 worlds, while bare
atoms survived 1000/1000 carrying ~40 denials each. The corpus
holds contradictory hard pairs (anonymous AND non-anonymous
technology), so denial-is-fatal starves the sampler; denial-as-
data keeps it alive and lets the score sort worlds instead.
Where gating is really wanted, write the expansion directly --
a bare `X` to derive, then `X=t` to insist -- and put it in the
QUERY, not a clause body: inside a body the deny branch catches
the failed demand and labels the head f instead (checked live:
`isamp([start,start=t], [x=f], W)` dies; `isamp(start, ...)`
survives as `start=f`).

Model shape convention:

    start <-- [[and, hard1, hard2],
               [and, soft1, soft2, soft3]].

    ?- isamp([start, start=t, hard1=t, hard2=t], Inits, W).

Hard goals gate by demands in the query; the
soft list guarantees every quality is labeled in every world,
so worlds are comparable column-for-column and the "unseen"
count drops to zero for the qualities that matter.

## 3. The extension argument

Every iStar 2.0 construct lands in one of three buckets:
already a form, one new `todo` row, or a naming convention.
None require touching the kernel, because the kernel knows
nothing about goal modeling -- it checks, records, steps, and
derives, and every iStar notion is a characterization on top.

| iStar 2.0                    | nfr5                          | cost       |
|------------------------------|-------------------------------|------------|
| goal / task / resource       | atom                          | have       |
| AND-refinement               | body list, `[and|..]`         | have       |
| OR-refinement                | body `[or|Alts]`              | have       |
| make / help / hurt / break   | the four link rows            | have       |
| quality                      | atom labeled by links         | have       |
| satisfied / denied / unlabeled | t / f / unseen              | have       |
| neededBy                     | `resource, resource=t` in body | idiom     |
| qualification                | bare quality atom in body     | idiom      |
| actor boundary               | name prefix (`buyer/pay`)     | convention |
| dependency                   | cross-actor edge (see below)  | convention |

The dependency row was checked live: with `:- op(200,xfx,/)`,
`buyer/shop <-- [buyer/pay, seller/deliver]` gates end-to-end
across two actors, no demand needed. The reason is a wrinkle
worth knowing: slash-named heads are compounds, so the
`atom(X)` guards (deny branch, fiat leaf) skip them and a
failed dependum fails *hard* rather than labeling f. For
dependencies this is accidentally correct -- it is exactly
iStar's vulnerability reading -- but it is implicit; widen the
guards if soft dependencies are wanted.

What iStar 2.0 leaves open (evaluation), sampling supplies:
run N worlds, histogram each quality as t / f / unseen. On the
"shipped" toy model in the lab notebook, 2000 worlds take about
0.26s and reproduce the link weights to two digits.

Precedent for the two demand-vs-`makes` readings: nfr2 already
distinguished derived hard demands from assumed ones ("a hard
demand on an edge node is assumed, not derived").

## 4. The extension principle, demonstrated

Zadeh's extension principle (Zadeh, "Fuzzy Sets", Information
and Control 8(3) 1965, DOI 10.1016/S0019-9958(65)90241-X;
elaborated 1975) requires that any fuzzy extension of a crisp
operation reproduce the crisp operation on crisp inputs. Here
the fuzz lives in exactly two constants -- the draw bags,
now named facts at the top of nfr5.pl:

    bag(helps, [t,t,f]).
    bag(hurts, [f,f,t]).

Fuzz=0 means shrinking each bag to its majority ([t,t,f] -> [t],
[f,f,t] -> [f]). Measured, 3000 worlds per condition, model
`g <-- [helps(cost), hurts(risk)]`:

    fuzzy bags:  cost=t in 1986/3000, risk=f in 1986/3000  (2/3 each)
    crisp bags:  cost=t, risk=f in 3000/3000

and, world-for-world against `h <-- [makes(cost), breaks(risk)]`
under crisp bags: 3000/3000 identical label sets. helps collapses
to makes, hurts to breaks, every draw is deterministic, and what
remains is classical propositional refinement with abduction.
The collapse is a data edit; no interpreter line changes.

The same knob runs the other way: nine `t`s and one `f` is a
0.9 helps; the bag *is* the calibrated link strength, so learned
link weights (or learned assumptions, passed as `Inits`) drop in
without new machinery.

## 5. Scale

Biggest model in this directory: models/CSServices.pl
(Kids Help Phone; 842 lines, 352 `<--` clauses, nfr3 dialect --
loads unchanged). Measured:

    100 worlds:     17 ms   (~0.17 ms/world)
    10,000 worlds:  1.4 s   (~140 us/world)

A million-world Monte Carlo over the largest model we have is
minutes, not hours.

Caveat for the nfr3-era models: they were written for nfr3's
edge semantics, where all bodies of a soft head *combine*
(amin/amax arithmetic over contributions). nfr5's `<--` kernel
form or-commits to one body per world; across many worlds the
sample approximates the mix, but any single world reads one
argument, not the merged verdict. If merged-per-world verdicts
are wanted, that is one more kernel row (walk all bodies,
combine labels), not a redesign.
