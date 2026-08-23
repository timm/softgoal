;; 2 chain: a->b->c->d, tests derive recursion + nested undo
(<- a b) (<- b c) (<- c d) (<- d (and x (makes q)))
(defparameter *hard* (quote (a)))
(defparameter *soft* (quote (q)))
