;; 3 diamond: x shared under a and b; memo must reuse label
(<- h (and a b)) (<- a (and x (helps q))) (<- b (and x (helps q)))
(defparameter *hard* (quote (h)))
(defparameter *soft* (quote (q)))
