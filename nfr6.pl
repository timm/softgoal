% nfr6.pl : back to basic prolog. Two-valued world sampler for goal
% models; ISAMP style -- one guess per choice point, a failed proof
% kills the world and we try again (patience-bounded).
%   swipl -g main nfr6.pl [seed]
%
% A model is  Head <= Body  clauses; bodies written literally as
% and([...]), or([...]), links makes(x)/breaks(x)/helps(x)/hurts(x),
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

%% ---- links: ++(Op, Sense, Value) --------------------------------
++(makes,t,t).      ++(makes,f,f).
++(breaks,t,f).     ++(breaks,f,t).
++(helps,S,V) :- ++(makes,S,V).      % first solution favoured 2:1,
++(helps,S,V) :- ++(breaks,S,V).     % so helps ~ (t t f) of the lisp
++(hurts,S,V) :- ++(breaks,S,V).
++(hurts,S,V) :- ++(makes,S,V).

link(Op,S,V) :- findall(W, ++(Op,S,W), [W0|Ws]),
                ( Ws = [] -> V = W0                  % makes, breaks
                ; maybe(2,3) -> V = W0               % helps, hurts: biased pick
                ; random_member(V,Ws) ).

%% ---- prove(Goal, Sense) ------------------------------------------
prove(G) :- prove(G, t).

prove(not G,   S) :- !, flip(S,S1), prove(G,S1).
prove(and(L),  S) :- !, random_permutation(L,R), maplist([G]>>prove(G,S), R).
prove(or(L),   S) :- !, random_member(G,L), prove(G,S).
prove(Lnk,     S) :- Lnk =.. [Op,X], memberchk(Op,[makes,breaks,helps,hurts]),
                     !, link(Op,S,V), assume(X,V).
prove(G,       S) :- val(G,V), !, V = S.             % memo: must match sense
prove(G,       S) :- (G <= Body), !,
                     assume(G,S), prove(Body,S).     % head first: loops close
prove(G,       S) :- assume(G,S).                    % no clause: goal = sense

flip(t,f).
flip(f,t).

%% ---- worlds ------------------------------------------------------
world(Goals, W) :- retractall(val(_,_)),
                   \+ \+ maplist(prove, Goals),      % all or nothing
                   findall(X=V, val(X,V), W).

one(Goals, Patience, W) :- Patience > 0,
                           ( world(Goals,W) -> true
                           ; P is Patience-1, one(Goals,P,W) ).

sample(Goals, N, Ws) :- length(Ws, N),
                        maplist([W]>>one(Goals,1000,W), Ws).

%% ---- lint: one clause per head -----------------------------------
lint :- setof(G, B^(G <= B), Gs), member(G,Gs),
        aggregate_all(count, (G <= _), N), N > 1,
        print_message(warning, format("~w has ~d clauses; combine into  ~w <= or([sub1,sub2])", [G,N,G])),
        fail.
lint.

%% ================= demo model: buy vs build ======================
built    <= or([buy, diy]).
buy      <= and([vendor, breaks(cheap), helps(fast)]).
diy      <= and([coders, helps(cheap), hurts(fast)]).
deployed <= or([cloud, onprem]).
cloud    <= and([helps(fast), hurts(private)]).
onprem   <= and([makes(private), hurts(fast)]).
usable   <= and([tested, helps(fast)]).

hard([built, deployed]).
soft([cheap, fast, private]).

%% ---- top ---------------------------------------------------------
main :- lint,
        ( current_prolog_flag(argv,[A|_]), atom_number(A,Seed)
        -> set_random(seed(Seed)) ; true ),
        hard(H), soft(Q),
        maplist([X,or([X, not X])]>>true, Q, EQ),  % engage softs: either value
        sample([and(H), and(EQ)], 5, Ws),
        forall(member(W,Ws), (print(W), nl)).
