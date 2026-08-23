;; 24 low-yield hard: 6 independent 50/50 helps q demanded t ~1/64
(<- h (seq (helps q) (= q t) (helps r) (= r t) (helps s) (= s t) (helps u) (= u t) (helps v) (= v t) (helps z) (= z t)))
(defparameter *hard* (quote (h)))
(defparameter *soft* (quote (q r s u v z)))
