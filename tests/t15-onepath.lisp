;; 15 hard reachable only via one of 4 or-branches
(<- h (or bad1 bad2 bad3 good))
(<- bad1 (and (= x t) (= x f)))
(<- bad2 (and (= y t) (= y f)))
(<- bad3 (and (= z t) (= z f)))
(<- good (and ok (helps q)))
(defparameter *hard* (quote (h)))
(defparameter *soft* (quote (q)))
