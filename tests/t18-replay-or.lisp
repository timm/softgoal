;; 18 or with branch settled by earlier goal: replay shortcut
(<- h (and a (or a b)))
(<- a (and x (helps q)))
(<- b (and y (hurts q)))
(defparameter *hard* (quote (h)))
(defparameter *soft* (quote (q)))
