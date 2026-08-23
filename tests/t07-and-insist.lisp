;; 7 and derive-then-insist: shuffled, demand may run first -> fiat x=t w/o deriving
(<- h (and x (= x t)))
(<- x (or (makes q) (breaks q)))
(defparameter *hard* (quote (h)))
(defparameter *soft* (quote (q)))
