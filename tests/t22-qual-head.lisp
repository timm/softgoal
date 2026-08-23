;; 22 link target has its own rules: quals must exclude heads
(<- h (and a (helps q)))
(<- q (and r (makes q2)))
(defparameter *hard* (quote (h)))
(defparameter *soft* (quote (q q2)))
