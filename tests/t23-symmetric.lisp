;; 23 symmetric or: a,b identical; expect ~50/50 and seed reproducible
(<- h (or a b))
(<- a (and x (helps q)))
(<- b (and y (helps q)))
(defparameter *hard* (quote (h)))
(defparameter *soft* (quote (q)))
