; vim: set lispwords+=loop :
;;;; nfr5.lisp : world sampler for goal models; port of infer.py.
;;;; Bodies are plain sexprs -- the reader is the parser:
;;;;   (and ...) shuffled conjunction   (or ...)  commit to one
;;;;   (= x t)   demand (chk or add)    (helps x) weighted link
;;;;   (seq ...) ordered: (seq x (= x t)) derives then insists
;;;;   bare atom label it, never a demand
;;;; (<- head body) records a clause on the head symbol plist.
;;;; Worlds are hash tables; undo is a trail. (An alist world
;;;; was tried and retired: free snapshots, but O(n) reads made
;;;; the replay-heavy keys pipeline 6x slower.) RNG is the
;;;; house park-miller 16807, seedable via *seed*.
(defvar *links* '((makes t) (breaks f) (helps t t f) (hurts f f t)))
(defvar *replay* nil)
(defvar *heads* nil)
(defvar *seed*  1)

(defmacro <- (head body)
  `(progn (pushnew ',head *heads*)
          (setf (get ',head 'rules)
                (append (get ',head 'rules) (list ',body)))))

(defun prand () (/ (setf *seed* (mod (* 16807 *seed*) 2147483647)) 2147483647d0))
(defun rint (n) (floor (* n (prand))))
(defun pick (xs) (nth (rint (length xs)) xs))

(defun shuffled (xs &aux (v (coerce xs 'vector)))
  (loop for i from (1- (length v)) downto 1
        do (rotatef (aref v i) (aref v (rint (1+ i)))))
  (coerce v 'list))

(defun syms (g)
  (cond ((symbolp g)                    (list g))
        ((member (car g) '(and or seq)) (mapcan #'syms (copy-list (cdr g))))
        (t                              (list (second g)))))

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

(defun derive (g w)
  "try one body under g=t; on failure undo and deny: g=f"
  (let ((mark (mark)))
    (add g 't w)
    (unless (isamp (pick (get g 'rules)) w)
      (undo mark w)
      (add g 'f w))
    t))

(defun isamp (g w)
  (cond
    ((and *replay* (or (symbolp g) (not (eq (car g) '=))) (believed g w)) t)
    ((symbolp g)
     (cond ((known g w)     t)                   ; memo
           ((get g 'rules)  (derive g w))
           (t               (add g 't w))))      ; fiat: abduce to t
    ((eq (car g) '=)   (believe (second g) (third g) w))
    ((eq (car g) 'seq) (every (lambda (x) (isamp x w)) (cdr g)))
    ((eq (car g) 'and) (every (lambda (x) (isamp x w)) (shuffled (cdr g))))
    ((eq (car g) 'or)  (or (and *replay*         ; a settled branch = done
                                (some (lambda (x) (believed x w)) (cdr g)))
                           (isamp (pick (cdr g)) w)))
    ((assoc (car g) *links*)
     (believe (second g) (pick (cdr (assoc (car g) *links*))) w))
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
