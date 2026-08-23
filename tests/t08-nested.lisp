;; 8 nested or/and/or
(<- h (or (and a (or b (and c (helps q)))) (and d (or e (hurts q)))))
(defparameter *hard* (quote (h)))
(defparameter *soft* (quote (q)))
