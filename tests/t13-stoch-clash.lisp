;; 13 helps+hurts: clash sometimes (t t f vs f f t), got/miss ratio ~4/9
(<- h (and (helps q) (hurts q)))
(defparameter *hard* (quote (h)))
(defparameter *soft* (quote (q)))
