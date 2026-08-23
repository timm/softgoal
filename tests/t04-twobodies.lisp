;; 4 two bodies: first body always fails; no retry of 2nd -> h denied ~half the time
(<- h (and (= x t) (= x f)))
(<- h (and y (makes q)))
(defparameter *hard* (quote (h)))
(defparameter *soft* (quote (q)))
