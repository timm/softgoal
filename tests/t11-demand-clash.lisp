;; 11 demand clash under hard goal: unreachable
(<- h (and (= x t) (= x f)))
(defparameter *hard* (quote (h)))
(defparameter *soft* (quote (q)))
