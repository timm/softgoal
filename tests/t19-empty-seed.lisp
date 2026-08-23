;; 19 everything forced by hard goals: zero settable candidates
(<- h (and (= a t) (= b t) (makes q)))
(defparameter *hard* (quote (h)))
(defparameter *soft* (quote (q)))
