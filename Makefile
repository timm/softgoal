include .dot/Makefile

S  ?= 1
PY ?= python3

keys: ## REPORT_keys table; make keys S=3 FLAGS="-n1 256"
	@( echo "dataset,mu,sd,best,muSeed,sdSeed,n_filt,seed,tests,pct"; \
	   for m in models/*.py small.py; do \
	     $(PY) run.py -seed $(S) $(FLAGS) $$m; done \
	 ) | column -s, -t

keys-lisp: ## same table via nfr5.lisp + rig.lisp (park-miller rng)
	@$(PY) to-lisp.py >/dev/null
	@( echo "dataset,mu,sd,best,muSeed,sdSeed,n_filt,seed,tests,pct"; \
	   for m in models/*.lisp small.lisp; do \
	     n=$$(basename $$m .lisp | sed 's/^CS//'); \
	     sbcl --script rig.lisp $$m $$n 2>/dev/null | tail -1; done \
	 ) | column -s, -t

.PHONY: tests
tests: ## run tests/t*.lisp (2 dozen small models) through rig.lisp
	@tests/run.sh

~/tmp/tests.html: tests/* rig.lisp nfr5.lisp ## paint tests/run.sh results as an html strip chart
	@mkdir -p ~/tmp; tests/run.sh | tests/paint.py > $@ && echo $@
