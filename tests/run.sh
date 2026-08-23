#!/usr/bin/env bash
# run every tests/t*.lisp through rig.lisp as CSV. Two lines per model:
#   best,NAME,a=t,b=f,...   the best sampled world
#   NAME,mu,sd,...          the keys row        (crash => NAME,CRASH)
cd "$(dirname "$0")/.."
echo "model,mu,sd,best,muSeed,sdSeed,n_filt,seed,tests,pct"
for m in tests/t*.lisp; do
  n=$(basename $m .lisp)
  out=$(sbcl --script rig.lisp $m $n 2>&1)
  echo "$out" | grep -E "^(best,)?$n," || echo "$n,CRASH,,,,,,,,"
done
