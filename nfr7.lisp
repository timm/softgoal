; vim: set lispwords+=loop :
;;;; nfr7.lisp : nfr5 plus what the prolog port taught it.
;;;; A world sampler for goal models. Bodies are plain sexprs:
;;;;   (and ...)  shuffled conjunction    (or ...) try branches till
;;;;   (= x v)    demand (chk or add)              one ENDS labeled s
;;;;   (seq ...)  ordered and             (not g)  argue the reverse
;;;;   (helps x)  weighted link           atom     label it via rules,
;;;;                                              else fiat to sense
;;;; Proofs carry a sense s (usually t); (not g) flips it. Links draw
;;;; from per-sense bags -- the bag IS the link strength, both flips
;;;; are data. Denial is not death: a failed body denies its head and
;;;; the walk goes on; worlds die only at (= ...) demands. Replay
;;;; (*replay*) treats believed goals as settled. RNG is park-miller.
(defvar *links* '((makes  (t)     (f))       ; op, bag under t, under f
                  (breaks (f)     (t))
                  (helps  (t t f) (f f t))
                  (hurts  (f f t) (t t f))))
(defvar *replay* nil)
(defvar *heads* nil)
(defvar *seed*  1)

(defmacro <- (head body)
  `(progn (pushnew ',head *heads*)
          (setf (get ',head 'rules)
                (append (get ',head 'rules) (list ',body)))))

(defun flip (s) (if (eq s 't) 'f 't))

(defun prand () (/ (setf *seed* (mod (* 16807 *seed*) 2147483647)) 2147483647d0))
(defun rint (n) (floor (* n (prand))))
(defun pick (xs) (nth (rint (length xs)) xs))

(defun shuffled (xs &aux (v (coerce xs 'vector)))
  (loop for i from (1- (length v)) downto 1
        do (rotatef (aref v i) (aref v (rint (1+ i)))))
  (coerce v 'list))

(defun syms (g)
  (cond ((symbolp g)                        (list g))
        ((member (car g) '(and or seq not)) (mapcan #'syms (copy-list (cdr g))))
        (t                                  (list (second g)))))

(defun known (x w)    (nth-value 1 (gethash x w)))
(defun believed (g w) (every (lambda (a) (known a w)) (syms g)))

(let (trail)   ; the undo trail, reachable ONLY via these verbs
  (defun add (x v w)
    "record x=v on the world and the trail; always true"
    (setf (gethash x w) v) (push x trail) t)
  (defun mark ()      trail)
  (defun undo (mark w)
    (loop until (eq trail mark) do (remhash (pop trail) w)))
  (defun wipe ()      (setf trail nil)))

(defun believe (x v w)
  (if (known x w) (eq (gethash x w) v) (add x v w)))

(defun derive (g w s)
  "try one body under g=s; on failure undo and deny: g=(flip s)"
  (let ((mark (mark)))
    (add g s w)
    (unless (isamp (pick (get g 'rules)) w s)
      (undo mark w)
      (add g (flip s) w))
    t))

(defun won (g w s)
  "isamp g; a symbol branch must also END labeled s"
  (and (isamp g w s)
       (or (not (symbolp g)) (eq (gethash g w) s))))

(defun isamp (g w &optional (s 't))
  (cond
    ((and *replay* (or (symbolp g) (not (eq (car g) '=))) (believed g w)) t)
    ((symbolp g)
     (cond ((known g w)     t)                   ; memo
           ((get g 'rules)  (derive g w s))
           (t               (add g s w))))       ; fiat: abduce to sense
    ((eq (car g) 'not) (isamp (second g) w (flip s)))
    ((eq (car g) '=)   (believe (second g) (third g) w))
    ((eq (car g) 'seq) (every (lambda (x) (isamp x w s)) (cdr g)))
    ((eq (car g) 'and) (every (lambda (x) (isamp x w s)) (shuffled (cdr g))))
    ((eq (car g) 'or)  (or (and *replay*         ; a settled branch = done
                                (some (lambda (x) (believed x w)) (cdr g)))
                           (some (lambda (x) (won x w s)) (shuffled (cdr g)))))
    ((assoc (car g) *links*)
     (believe (second g)
              (pick (nth (if (eq s 't) 1 2) (assoc (car g) *links*)))
              w))
    (t nil)))

(defun sample (query &key beliefs replay (n 20) (patience 1000))
  (let ((*replay* replay) worlds (got 0) (miss 0))
    (loop while (and (< got n) (< miss patience))
          do (let ((w (make-hash-table :test 'eq)))
               (wipe)
               (loop for (x . v) in beliefs do (setf (gethash x w) v))
               (cond ((every (lambda (g) (isamp g w)) query)
                      (setf miss 0) (incf got) (push w worlds))
                     (t (incf miss)))))
    (nreverse worlds)))

;;; ---- show: the model, each atom tagged by one world ---------
(defun tag (x w)
  (if (known x w)
      (format nil "~(~a~):~:[F~;T~]" x (eq (gethash x w) 't))
      (format nil "~(~a~)" x)))

(defun pretty (g w)
  (cond ((symbolp g) (tag g w))
        ((member (car g) '(and or seq))
         (format nil "(~(~a~)~{ ~a~})" (car g)
                 (mapcar (lambda (x) (pretty x w)) (cdr g))))
        ((eq (car g) 'not) (format nil "(not ~a)" (pretty (second g) w)))
        ((eq (car g) '=)
         (format nil "(= ~a ~(~a~))" (tag (second g) w) (third g)))
        (t (format nil "(~(~a~) ~a)" (car g) (tag (second g) w)))))

(defun show (w)
  (dolist (h (reverse *heads*))
    (dolist (b (get h 'rules))
      (format t "(<- ~a ~a)~%" (tag h w) (pretty b w)))))
