;; 17 head fixed by hard-gate demand, leaf x contradicts clause in half the worlds
(<- h (or (and x (makes q)) (and (= x f) (breaks q))))
(defparameter *hard* (quote (h)))
(defparameter *soft* (quote (q)))
