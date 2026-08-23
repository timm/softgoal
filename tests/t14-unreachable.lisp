;; 14 hard goal whose only body needs another unreachable head
(<- h g)
(<- g (and (= x t) (= x f)))
(defparameter *hard* (quote (h)))
(defparameter *soft* (quote (q)))
