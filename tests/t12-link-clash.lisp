;; 12 makes+breaks same qual, always clash -> h always denied -> unreachable
(<- h (and (makes q) (breaks q)))
(defparameter *hard* (quote (h)))
(defparameter *soft* (quote (q)))
