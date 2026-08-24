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

:- op(1200, xfx, <=).
:- op(900,  fy, not).
:- dynamic (<=)/2, val/2.
:- discontiguous (<=)/2.

%% ---- working memory: assert(val(X,V)), wiped per world ----------
assume(X,V) :- val(X,W), !, W = V.
assume(X,V) :- assert(val(X,V)).

flip(t,f).
flip(f,t).

prove_all([],_).
prove_all([G|Gs],S) :- prove(G,S), prove_all(Gs,S).

shuffle(L,R) :- random_permutation(L,R).

%% ---- links: ++(Op, Sense, Value) --------------------------------
plus(makes, S,S).
plus(breaks,S,V) :- flip(S,V).
plus(helps,S,V) :- plus(makes,S,V).      % first solution favoured 2:1,
plus(helps,S,V) :- plus(breaks,S,V).     % so helps ~ (t t f) of the lisp
plus(hurts,S,V) :- plus(breaks,S,V).
plus(hurts,S,V) :- plus(makes,S,V).

link(Op,S,V) :- findall(W, plus(Op,S,W), [W0|Ws]),
                ( Ws = [] -> V = W0                  % makes, breaks
                ; maybe(2,3) -> V = W0               % helps, hurts: biased pick
                ; shuffle(Ws,[V|_]) ).

%% ---- prove(Goal, Sense) ------------------------------------------
prove(G) :- prove(G, t).

prove(not G,   S) :- !, flip(S,S1), prove(G,S1).
prove(and(L),  S) :- !, shuffle(L,R), prove_all(R,S).
prove(or(L),   S) :- !, shuffle(L,[G|_]), prove(G,S).
prove(Op/X,    S) :- !, link(Op,S,V), assume(X,V).
prove(G,       S) :- val(G,V), !, V = S.             % memo: must match sense
prove(G,       S) :- (G <= Body), !,
                     assume(G,S), prove(Body,S).     % head first: loops close
prove(G,       S) :- assume(G,S).                    % no clause: goal = sense

%% ---- worlds ------------------------------------------------------
world(Goals, W) :- retractall(val(_,_)),
                   prove(and(Goals)),
                   findall(X=V, val(X,V), W).

one(Goals, Patience, W) :- Patience > 0,
                           ( world(Goals,W) -> true
                           ; P is Patience-1, one(Goals,P,W) ).

sample(_,     0, []) :- !.
sample(Goals, N, [W|Ws]) :- one(Goals,1000,W),
                            N1 is N-1, sample(Goals,N1,Ws).

%% ---- lint: one clause per head -----------------------------------
lint :- clause(G <= _, true, M), clause(G <= _, true, N), M @< N,
        print_message(warning, format("~w has 2+ clauses; combine into  ~w <= or([sub1,sub2])", [G,G])),
        fail.
lint.

%% ================= demo model: buy vs build ======================
built    <= or([buy, diy]).
buy      <= and([vendor, breaks/cheap, helps/fast]).
diy      <= and([coders, helps/cheap, hurts/fast]).
deployed <= or([cloud, onprem]).
cloud    <= and([helps/fast, hurts/private]).
onprem   <= and([makes/private, hurts/fast]).
usable   <= and([tested, helps/fast]).

hard([built, deployed]).
soft([cheap, fast, private]).

%% ---- top ---------------------------------------------------------
main :- lint,
        ( current_prolog_flag(argv,[A|_]), atom_number(A,Seed)
        -> set_random(seed(Seed)) ; true ),
        hard(H), soft(Q),
        findall(or([X, not X]), member(X,Q), EQ),  % engage softs: either value
        sample([and(H), and(EQ)], 5, Ws),
        forall(member(W,Ws), (print(W), nl)).
