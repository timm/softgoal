% nfr6.pl : back to basic prolog. Two-valued world sampler for goal
% models; ISAMP style -- one guess per choice point, a failed proof
% kills the world and we try again (patience-bounded).
%   swipl -g main nfr6.pl [seed]
%
% A model is  Head <= Body  clauses; bodies written literally as
% and([...]), or([...]), links makes/x, breaks/x, helps/x, hurts/x,
% not(x), or a bare atom. No goal expansion. One clause per head:
% more get a load-time warning (combine into  h <= or([s1,s2])).
%
% Proofs carry a sense, usually t; not(x) flips it. A goal with no
% clause concludes goal=sense. Unlike the lisp/python engines, a
% bare atom in an and([...]) is DEMANDED: if its proof settles on
% the other value, the world dies (denial propagates).
% 
% 1. Seed beliefs into the world — world must assert the seed's val/2 facts after the wipe, before proving. Without this there's nothing to replay.
% 2. Or prefers settled branch (your line 47) — lisp: (some believed (cdr g)) → whole or succeeds outright if any branch already labeled:
% prove(S, or(L)) :- replay, member(G,L), val(G,_), !.   % settled branch = done
% prove(S, or(L)) :- !, shuffle(L,[G|_]), prove(S,G).
% 
% 3. Links leave settled targets alone — python: if replay and g[2] in w: return True. Otherwise every replay re-rolls the link dice and clash-kills worlds that disagree with the seed — turns prudent replay into rejection sampling:
% prove(_, _/X)  :- replay, val(X,_), !.
% prove(S, Op/X) :- !, link(Op,S,V), assume(X,V).
% 
% 4. Believed-goal short-circuit (lisp's first isamp line): any goal whose atoms are all labeled succeeds untouched. In nfr6 the memo clause val(G,V), V=S half-covers this — but note the difference: lisp replay accepts any label (believed = known), nfr6 memo demands label = sense. Yours is stricter — a seed saying g=f fails a sense-t proof rather than sliding by. In demand-semantics nfr6, I'd keep the strict memo and skip this piece; it's arguably the more honest replay.
% 

:- op(1200, xfx, <=).
:- op(900,  fy, not).
:- dynamic (<=)/2, val/2.
:- discontiguous (<=)/2.

%% ---- working memory: assert(val(X,V)), wiped per world -------
assume(X,V) :- val(X,W), !, W = V.
assume(X,V) :- assert(val(X,V)).

shuffle(L,R) :- random_permutation(L,R).

%% ---- links: ++(Op, Sense, Value) -----------------------------
plus(makes,  t, [t]).
plus(makes,  f, [f]).
plus(breaks, t, [f]).
plus(breaks, f, [t]).
plus(helps,  t, [t,t,f]). % weight by repetition:
plus(helps,  f, [f,f,t]). % the lisp's (helps t t f)
plus(hurts,  t, [f,f,t]).
plus(hurts,  f, [t,t,f]).

flip(t,f).
flip(f,t).

link(Op,S,V) :- plus(Op,S,Vs), shuffle(Vs,[V|_]).

%% ---- prove(Sense, Replay, Goal); R = fresh | replay ----------
prove(G) :- prove(t, fresh, G).

prove(_, replay, G     ) :- believed(G), !.        % (4) settled = done
prove(S, R,      not G ) :- !, flip(S,S1), prove(S1,R,G).
prove(S, R,      and(L)) :- !, shuffle(L,L1), maplist(prove(S,R),L1).
prove(S, replay, or(L) ) :- member(G,L), believed(G),
                            !, prove(S,replay,G).  % (2) prefer settled branch
prove(S, R,      or(L) ) :- !, shuffle(L,[G|_]), prove(S,R,G).
prove(_, replay, _/X   ) :- val(X,_), !.           % (3) seeded qual stands
prove(S, _,      Op/X  ) :- !, link(Op,S,V), assume(X,V).
prove(S, _,      G     ) :- val(G,V), !, V = S.
prove(S, R,      G     ) :- (G <= Body), !, assume(G,S), prove(S,R,Body).
prove(S, _,      G     ) :- assume(G,S).

believed(not G ) :- !, believed(G).
believed(and(L)) :- !, forall(member(G,L), believed(G)).
believed(or(L) ) :- !, forall(member(G,L), believed(G)).
believed(_/X   ) :- !, val(X,_).
believed(G     ) :- val(G,_).

%% ---- worlds --------------------------------------------------
world(R, Seed, Goals, W) :- retractall(val(_,_)),
                            forall(member(X=V,Seed), assert(val(X,V))),  % (1)
                            prove(t, R, and(Goals)),
                            findall(X=V, val(X,V), W).

one(R, Seed, Goals, Patience, W) :- Patience > 0,
                                    ( world(R,Seed,Goals,W) -> true
                                    ; P is Patience-1, one(R,Seed,Goals,P,W) ).

sample(Goals, N, Ws)  :- sample(fresh, [], Goals, N, Ws).
replays(Seed, Goals, N, Ws) :- sample(replay, Seed, Goals, N, Ws).

sample(_, _,    _,     0, []) :- !.
sample(R, Seed, Goals, N, [W|Ws]) :- one(R,Seed,Goals,1000,W),
                                     N1 is N-1, sample(R,Seed,Goals,N1,Ws).

%% ---- scoring: d2h = distance to heaven (lower = better) ------
atoms([],     []) :- !.
atoms([G|Gs], As) :- !, atoms(G,A1), atoms(Gs,A2), append(A1,A2,As).
atoms(not G,  As) :- !, atoms(G,As).
atoms(and(L), As) :- !, atoms(L,As).
atoms(or(L),  As) :- !, atoms(L,As).
atoms(_/X,   [X]) :- !.
atoms(X,     [X]).

leaves(Ls) :- soft(Qs),
              findall(A, (clause(H <= B,true), atoms([H,B],A0), member(A,A0)), L0),
              sort(L0, As),
              findall(A, (member(A,As), \+ (A <= _), \+ memberchk(A,Qs)), Ls).

wons(Xs, W, N) :- findall(X, (member(X,Xs), memberchk(X=t,W)), Ts), length(Ts,N).

score(Qs, Ls, W, B-F) :- wons(Qs,W,B), wons(Ls,W,F).   % benefit-footprint

nrm(Lo, Hi, _, 0.5) :- Hi =:= Lo, !.
nrm(Lo, Hi, X, N)   :- N is (X-Lo)/(Hi-Lo).

d2hs(Ws, Ds) :- soft(Qs), leaves(Ls),
                maplist(score(Qs,Ls), Ws, BFs),
                pairs_keys_values(BFs, Bs, Fs),
                min_list(Bs,B0), max_list(Bs,B1),
                min_list(Fs,F0), max_list(Fs,F1),
                maplist(d2h(B0-B1, F0-F1), BFs, Ds).

d2h(B0-B1, F0-F1, B-F, D) :- nrm(B0,B1,B,NB), nrm(F0,F1,F,NF),
                             D is sqrt(((1-NB)^2 + NF^2)/2).

best(Ws, D, W) :- d2hs(Ws,Ds), pairs_keys_values(Ps,Ds,Ws),
                  msort(Ps, [D-W|_]).

load(W) :- retractall(val(_,_)), forall(member(X=V,W), assert(val(X,V))).

%% ---- show: model painted by current world --------------------
portray(X) :- atom(X), val(X,t), !, format('~w:T',[X]).
portray(X) :- atom(X), val(X,f), !, format('~w:F',[X]).
% unlabeled (ignored) atoms print bare

show :- forall((H <= B), (print(H <= B), nl)),
        hard(Hs), soft(Qs),
        format('hard: ~p~nsoft: ~p~n', [Hs,Qs]).

%% ---- lint: one clause per head -------------------------------
lint :- clause(G <= _, true, M), clause(G <= _, true, N), M @< N,
        print_message(warning, format(
	  "~w has 2+ clauses; join to ~w <= or([x1,x2])", [G,G])),
        fail.
lint.

%% ================ demo model: buy vs build ====================
built    <= or([buy, diy]).
buy      <= and([vendor, breaks/cheap, helps/fast]).
diy      <= and([coders, helps/cheap, hurts/fast]).
deployed <= or([cloud, onprem]).
cloud    <= and([helps/fast, hurts/private]).
onprem   <= and([makes/private, hurts/fast]).
usable   <= and([tested, helps/fast]).

hard([built, deployed]).
soft([cheap, fast, private]).

%% ---- top -----------------------------------------------------
main :- 
  lint,
  ( current_prolog_flag(argv,[A|_]), atom_number(A,Seed)
  -> set_random(seed(Seed)) ; true ),
     hard(H), soft(Q),
     findall(or([X, not X]), member(X,Q), EQ), % engage softs: either value
     sample([and(H), and(EQ)], 100, Ws),
     best(Ws, D, Best),
     format('100 worlds; best d2h = ~2f~n~w~n~n', [D, Best]),
     load(Best), show.                         % painted by the BEST world
