;; 6 seq derive-then-insist: x derived from rule, then demanded t
(<- h (seq x (= x t)))
(<- x (or (makes q) (breaks q)))
(defparameter *hard* (quote (h)))
(defparameter *soft* (quote (q)))
