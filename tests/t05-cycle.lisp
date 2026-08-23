;; 5 cycle a<-b, b<-a; terminates by memo, label is fiat
(<- a (and b (helps q))) (<- b (and a (helps q)))
(defparameter *hard* (quote (a)))
(defparameter *soft* (quote (q)))
