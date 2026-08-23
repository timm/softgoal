;; 20 every leaf matters: 8 independent or-leaves each helps/hurts q
(<- h (and (or a1 b1) (or a2 b2) (or a3 b3) (or a4 b4) (or a5 b5) (or a6 b6) (or a7 b7) (or a8 b8)))
(<- a1 (helps q)) (<- b1 (hurts q)) (<- a2 (helps q)) (<- b2 (hurts q))
(<- a3 (helps q)) (<- b3 (hurts q)) (<- a4 (helps q)) (<- b4 (hurts q))
(<- a5 (helps q)) (<- b5 (hurts q)) (<- a6 (helps q)) (<- b6 (hurts q))
(<- a7 (helps q)) (<- b7 (hurts q)) (<- a8 (helps q)) (<- b8 (hurts q))
(defparameter *hard* (quote (h)))
(defparameter *soft* (quote (q)))
