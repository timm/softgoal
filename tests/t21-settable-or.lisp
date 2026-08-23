;; 21 same atom is a leaf AND an or-branch: settable must count once
(<- h (and x (or x y) (helps q)))
(defparameter *hard* (quote (h)))
(defparameter *soft* (quote (q)))
