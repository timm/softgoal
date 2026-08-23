;; 16 soft never t: q broken by every path; nrm hi<=lo branch
(<- h (and a (breaks q)))
(<- q (and (= q f)))
(defparameter *hard* (quote (h)))
(defparameter *soft* (quote (q)))
