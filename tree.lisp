;;;; -*- Lisp -*-
;;;;
;;;; Copyright (c) 2012, Georgia Tech Research Corporation
;;;; All rights reserved.
;;;;
;;;; Author(s): Neil T. Dantam <ntd@gatech.edu>
;;;; Georgia Tech Humanoid Robotics Lab
;;;; Under Direction of Prof. Mike Stilman
;;;;
;;;; This file is provided under the following "BSD-style" License:
;;;;
;;;;   Redistribution and use in source and binary forms, with or
;;;;   without modification, are permitted provided that the following
;;;;   conditions are met:
;;;;   * Redistributions of source code must retain the above
;;;;     copyright notice, this list of conditions and the following
;;;;     disclaimer.
;;;;   * Redistributions in binary form must reproduce the above
;;;;     copyright notice, this list of conditions and the following
;;;;     disclaimer in the documentation and/or other materials
;;;;     provided with the distribution.
;;;;
;;;;   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
;;;;   CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
;;;;   INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
;;;;   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
;;;;   DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
;;;;   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;;;;   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
;;;;   NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
;;;;   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
;;;;   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
;;;;   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
;;;;   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
;;;;   EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


(in-package :motion-grammar)


;;;;;;;;;;;;;;;;;;;;;;;;
;; BASIC BINARY TREES ;;
;;;;;;;;;;;;;;;;;;;;;;;;


(defstruct (binary-tree (:constructor make-binary-tree (left value right)))
  left
  value
  right)

(defun map-binary-tree-inorder (function tree)
  (when tree
    (map-binary-tree-inorder function (binary-tree-left tree))
    (funcall function (binary-tree-value tree))
    (map-binary-tree-inorder function (binary-tree-right tree))))

(defun map-binary-tree-preorder (function tree)
  (when tree
    (funcall function (binary-tree-value tree))
    (map-binary-tree-preorder function (binary-tree-left tree))
    (map-binary-tree-preorder function (binary-tree-right tree))))

(defun map-binary-tree-postorder (function tree)
  (when tree
    (map-binary-tree-postorder function (binary-tree-left tree))
    (map-binary-tree-postorder function (binary-tree-right tree))
    (funcall function (binary-tree-value tree))))

(defun map-binary-tree-nil (order function tree)
  (ecase order
    (:inorder (map-binary-tree-inorder function tree))
    (:postorder (map-binary-tree-postorder function tree))
    (:preorder (map-binary-tree-preorder function tree))))

(defun map-binary-tree-list (order function tree)
  (let* ((c (cons nil nil))
         (k c))
    (map-binary-tree-nil order (lambda (x)
                                 (rplacd k (cons (funcall function x) nil))
                                 (setq k (cdr k)))
                         tree)
    (cdr c)))

(defun map-binary-tree (order result-type function tree)
  "Map elements of tree.
ORDER: (or :inorder :preorder :postorder)
RESULT-TYPE: (or 'list nil)"
  (cond
    ((null result-type)
     (map-binary-tree-nil order function tree))
    ((eq 'list result-type)
     (map-binary-tree-list order function tree))
    (t (error "Unknown result-type: ~A" result-type))))

(defun fold-binary-tree (order function initial-value tree)
  (let ((v initial-value))
    (map-binary-tree-nil order
                         (lambda (x) (setq v (funcall function v x)))
                         tree)))

(defun binary-tree-search-node (tree value compare)
  "Return the node of TREE containing VALUE or NIL of not present."
  (when tree
    (let ((c (funcall compare value (binary-tree-value tree))))
      (cond ((< c 0)
             (binary-tree-search-node (binary-tree-left tree) value compare))
            ((> c 0)
             (binary-tree-search-node (binary-tree-right tree) value compare))
            (t tree)))))

(defun binary-tree-member-p (tree value compare)
  (when (binary-tree-search-node tree value compare)
    t))

(defun binary-tree-left-left (tree)
  (binary-tree-left (binary-tree-left tree)))

(defun binary-tree-left-right (tree)
  (binary-tree-left (binary-tree-right tree)))

(defun binary-tree-right-left (tree)
  (binary-tree-right (binary-tree-left tree)))

(defun binary-tree-right-right (tree)
  (binary-tree-right (binary-tree-right tree)))

(defun binary-tree-value-left (tree)
  (binary-tree-value (binary-tree-left tree)))

(defun binary-tree-value-right (tree)
  (binary-tree-value (binary-tree-right tree)))

(defun binary-tree-dot (tree &key output)
  (output-dot output
              (lambda (s)
                (let ((i -1))
                  (labels ((helper (parent tree)
                             (let ((x (incf i)))
                               (format s "~&  ~A[label=\"~A\"~:[shape=none~;~]];~&"
                                       x (if tree
                                             (binary-tree-value tree)
                                             nil)
                                       tree)
                               (when parent
                                 (format s "~&  ~A -> ~A;~&"
                                         parent x))
                               (when tree
                                 (helper x (binary-tree-left tree))
                                 (helper x (binary-tree-right tree))))))
                    (format s "~&digraph {  ~&")
                    (helper nil tree)
                    (format s "~&}~&"))))))

(defun binary-tree-min (tree)
  "Return minimum (leftmost) value of TREE."
  (do ((tree tree (binary-tree-left tree)))
      ((null (binary-tree-left tree)) (binary-tree-value tree))))

(defun binary-tree-max (tree)
  "Return maximum (rightmost) value of TREE."
  (do ((tree tree (binary-tree-right tree)))
      ((null (binary-tree-right tree)) (binary-tree-value tree))))

(defun binary-tree-count (tree)
  "Number of elements in TREE."
  (if tree
      (+ 1
         (binary-tree-count (binary-tree-left tree))
         (binary-tree-count (binary-tree-right tree)))
      0))

(defun binary-tree-subset (tree-1 tree-2 compare)
  (labels ((rec (tree-1 tree-2)
             (cond
               ((null tree-1) t)
               ((null tree-2) nil)
               (t
                (let ((c (funcall compare (binary-tree-value tree-1) (binary-tree-value tree-2))))
                  (cond
                    ((< c 0) ; v1 < v2
                     (and (rec (make-binary-tree (binary-tree-left tree-1)
                                                 (binary-tree-value tree-1)
                                                 nil)
                               (binary-tree-left tree-2))
                          (rec (binary-tree-right tree-1)
                               tree-2)))
                    ((> c 0) ; v1 > v2
                     (and (rec (make-binary-tree nil
                                                 (binary-tree-value tree-1)
                                                 (binary-tree-right tree-1))
                               (binary-tree-right tree-2))
                          (rec (binary-tree-left tree-1)
                               tree-2)))
                    (t (and (rec (binary-tree-left tree-1)
                                 (binary-tree-left tree-2))
                            (rec (binary-tree-right tree-1)
                                 (binary-tree-right tree-2))))))))))
    (rec tree-1 tree-2)))



(defun binary-tree-equal (tree-1 tree-2 compare)
  ;; O(log(n)) space, O(min(m,n)) time
  (let ((stack))
    (labels ((push-left (k)
               (do ((x k (binary-tree-left x)))
                   ((null x))
                 (push x stack))))
      (push-left tree-1)
      (map-binary-tree-inorder (lambda (x)
                                 (if (or (null stack)
                                         (not (zerop (funcall compare x (binary-tree-value (car stack))))))
                                     (return-from binary-tree-equal
                                       nil)
                                     (push-left (binary-tree-right (pop stack)))))
                               tree-2))
    (not stack)))


  ;;   (labels ((collect-left (k list)
  ;;              (if k
  ;;                  (collect-left (binary-tree-left k) (cons k list))
  ;;                  list))
  ;;            (rec (tree list)
  ;;              (if (null tree)
  ;;                  list
  ;;                  (let ((list (rec (binary-tree-left tree) list))) ; left
  ;;                    (if (and list
  ;;                             (zerop (funcall compare (binary-tree-value tree)
  ;;                                             (binary-tree-value (car list))))) ; root
  ;;                        (rec (binary-tree-right tree) ;right
  ;;                             (collect-left (binary-tree-right (car list)) (cdr list)))
  ;;                        t)))))
  ;;     (not (rec tree-1 (collect-left tree-2 nil))))


(defun binary-tree-from-list (list)
  (when list
    (destructuring-bind (value &optional left right) list
      (make-binary-tree (binary-tree-from-list left)
                        value
                        (binary-tree-from-list right)))))


;;;;;;;;;;;
;;  AVL  ;;
;;;;;;;;;;;

;; SEE: Adams, Stephen. Implementing Sets Efficiantly in a Functional Language

(defstruct (avl-tree
             (:include binary-tree)
             (:constructor %make-avl-tree (height left value right)))
  (height 0 :type fixnum))

(defun make-avl-tree (left value right)
  (%make-avl-tree (1+ (max (if left (avl-tree-height left) 0)
                           (if right (avl-tree-height right) 0)))
                  left value right))


(defun right-avl-tree (left value right)
  "Right rotation"
  (make-avl-tree (binary-tree-left left)
                 (binary-tree-value left)
                 (make-avl-tree (binary-tree-right left)
                                value
                                right)))

(defun left-avl-tree (left value right)
  "Left rotation"
  (make-avl-tree (make-avl-tree left
                                value
                                (binary-tree-left right))
                 (binary-tree-value right)
                 (binary-tree-right right)))

(defun left-right-avl-tree (left value right)
  "Right rotation then left rotation"
  (make-avl-tree (make-avl-tree left
                                value
                                (binary-tree-left-left right))
                 (binary-tree-value-left right)
                 (make-avl-tree (binary-tree-right-left right)
                                (binary-tree-value right)
                                (binary-tree-right right))))
(defun right-left-avl-tree (left value right)
  "Left rotation then right rotation"
  (make-avl-tree (make-avl-tree (binary-tree-left left)
                                (binary-tree-value left)
                                (binary-tree-left-right left))
                 (binary-tree-value-right left)
                 (make-avl-tree (binary-tree-right-right left)
                                value
                                right)))

(defun avl-tree-balance (tree)
  (balance-avl-tree (binary-tree-left tree)
                    (binary-tree-value tree)
                    (binary-tree-right tree)))

(defun balance-avl-tree (left value right)
                                        ;(format t "~&Balance-avl-tree~&")
  (labels ((height (tree) (if tree (avl-tree-height tree) 0)))
    (let ((d (- (height right) (height left))))
      (cond
        ;; just right
        ((or (= 0 d)
             (= -1 d)
             (= 1 d))
         (make-avl-tree left value right))
        ;; left too tall
        ((= -2 d)
         (let ((d (- (height (binary-tree-right left))
                     (height (binary-tree-left left)))))
           (cond
             ((= 1 d)
              (right-left-avl-tree left value right))
             ((= -1 d)
              (right-avl-tree left value right))
             (t
              (avl-tree-balance (right-avl-tree left value right))))))
        ;; right too tall
        ((= 2 d)
         (let ((d (- (height (binary-tree-right right))
                     (height (binary-tree-left right)))))
           (cond
             ((= 1 d)
              (left-avl-tree left value right))
             ((= -1 d)
              (left-right-avl-tree left value right))
             (t
              (avl-tree-balance (left-avl-tree left value right))))))
        ;; left much too tall
        ((> -2 d)
         (balance-avl-tree (binary-tree-left left)
                           (binary-tree-value left)
                           (balance-avl-tree (binary-tree-right left)
                                             value
                                             right)))
        ;; right much too tall
        ((< 2 d)
         (balance-avl-tree (balance-avl-tree left value (binary-tree-left right))
                           (binary-tree-value right)
                           (binary-tree-right right)))
        (t (error "Unbalanceble tree: ~A ~A" left right))))))


(defmacro with-avl-tree-compare ((value tree compare)
                                 null-case less-case equal-case greater-case)
  "Compare VALUE to value of TREE and execute the corresponding case."
  (alexandria:with-gensyms (c tree-sym)
    `(let ((,tree-sym ,tree))
       (if (null ,tree-sym)
           ,null-case
           (let ((,c (funcall ,compare ,value (binary-tree-value ,tree-sym))))
             (declare (type fixnum ,c))
             (cond
               ((< ,c 0) ,less-case)
               ((> ,c 0) ,greater-case)
               (t ,equal-case)))))))

(defun avl-tree-insert (tree value compare)
  "Insert VALUE into TREE, returning new tree."
  (with-avl-tree-compare (value tree compare)
    (make-avl-tree nil value nil)
    (balance-avl-tree (avl-tree-insert (avl-tree-left tree) value compare)
                      (binary-tree-value tree)
                      (binary-tree-right tree))
    tree
    (balance-avl-tree (binary-tree-left tree)
                      (binary-tree-value tree)
                      (avl-tree-insert (avl-tree-right tree) value compare))))


(defun avl-tree-remove-min (tree)
  "Insert minimum element of TREE, returning new tree."
  (let ((left (binary-tree-left tree)))
    (if left
        (balance-avl-tree (avl-tree-remove-min left)
                          (binary-tree-value tree)
                          (binary-tree-right tree))
        (binary-tree-right tree))))

(defun avl-tree-concatenate (tree-1 tree-2)
  "Concatenate TREE-1 and TREE-2."
  (cond
    ((null tree-1) tree-2)
    ((null tree-2) tree-1)
    (t (balance-avl-tree tree-1 (binary-tree-min tree-2) (avl-tree-remove-min tree-2)))))

(defun avl-tree-split (tree x compare)
  (with-avl-tree-compare (x tree compare)
    (values nil nil nil)
    (multiple-value-bind (left-left present right-left)
        (avl-tree-split (binary-tree-left tree) x compare)
      (values left-left present (balance-avl-tree right-left
                                                  (binary-tree-value tree)
                                                  (binary-tree-right tree))))
    (values (binary-tree-left tree) t (binary-tree-right tree))
    (multiple-value-bind (left-right present right-right)
        (avl-tree-split (binary-tree-right tree) x compare)
      (values (balance-avl-tree (binary-tree-left tree)
                                (binary-tree-value tree)
                                left-right)
              present
              right-right))))

(defun avl-tree-remove (tree x compare)
  "Remove X from TREE, returning new tree."
  (with-avl-tree-compare (x tree compare)
    nil
    (balance-avl-tree (avl-tree-remove (avl-tree-left tree) x compare)
                      (binary-tree-value tree)
                      (binary-tree-right tree))
    (avl-tree-concatenate (avl-tree-left tree)
                          (avl-tree-right tree))
    (balance-avl-tree (avl-tree-left tree)
                      (avl-tree-value tree)
                      (avl-tree-remove (avl-tree-right tree) x compare))))


(defun avl-tree-union (tree-1 tree-2 compare)
  (cond
    ((null tree-1) tree-2)
    ((null tree-2) tree-1)
    ((= 1 (avl-tree-height tree-2))
     (avl-tree-insert tree-1 (avl-tree-value tree-2) compare))
    ((= 1 (avl-tree-height tree-1))
     (avl-tree-insert tree-2 (avl-tree-value tree-1) compare))
    ((>= (avl-tree-height tree-2)
         (avl-tree-height tree-1))
     (multiple-value-bind (left-2 p-2 right-2) (avl-tree-split tree-2 (avl-tree-value tree-1) compare)
       (declare (ignore p-2))
       (balance-avl-tree (avl-tree-union (binary-tree-left tree-1) left-2 compare)
                         (avl-tree-value tree-1)
                         (avl-tree-union (binary-tree-right tree-1) right-2 compare))))
    (t
     (multiple-value-bind (left-1 p-1 right-1) (avl-tree-split tree-1 (avl-tree-value tree-2) compare)
       (declare (ignore p-1))
       (balance-avl-tree (avl-tree-union left-1 (binary-tree-left tree-2) compare)
                         (avl-tree-value tree-2)
                         (avl-tree-union right-1 (binary-tree-right tree-2) compare))))))

(defun avl-tree-intersection (tree-1 tree-2 compare)
  (cond
    ((or (null tree-1)
         (null tree-2))
     nil)
    ;; next two cases are a premature optimization
    ((= 1 (avl-tree-height tree-1))
     (when (binary-tree-search-node tree-2 (binary-tree-value tree-1) compare)
       (make-avl-tree nil (binary-tree-value tree-1) nil)))
    ((= 1 (avl-tree-height tree-2))
     (when (binary-tree-search-node tree-1 (binary-tree-value tree-2) compare)
       (make-avl-tree nil (binary-tree-value tree-2) nil)))
    ;; general case
    (t (multiple-value-bind (left-2 present right-2)
           (avl-tree-split tree-2 (avl-tree-value tree-1) compare)
         (let ((i-left (avl-tree-intersection (avl-tree-left tree-1) left-2 compare))
               (i-right (avl-tree-intersection (avl-tree-right tree-1) right-2 compare)))
           (if present
               (balance-avl-tree i-left (avl-tree-value tree-1) i-right)
               (avl-tree-concatenate i-left i-right)))))))

(defun avl-tree-difference (tree-1 tree-2 compare)
  (cond
    ((null tree-1) nil)
    ((null tree-2) tree-1)
    ;; next cases is a premature optimization
    ((= 1 (avl-tree-height tree-2))
     (avl-tree-remove tree-1 (binary-tree-value tree-2) compare))
    ;; general case
    (t (multiple-value-bind (left-2 present right-2)
           (avl-tree-split tree-2 (binary-tree-value tree-1) compare)
         (let ((left (avl-tree-difference (binary-tree-left tree-1) left-2 compare))
               (right (avl-tree-difference (binary-tree-right tree-1) right-2 compare)))
           (if present
               (avl-tree-concatenate left right)
               (balance-avl-tree left (binary-tree-value tree-1) right)))))))

;;;;;;;;;;;;;;;
;; TREE-MAPS ;;
;;;;;;;;;;;;;;;

(defstruct (tree-map (:constructor %make-tree-map (compare root)))
  compare
  (root nil))

(defun make-tree-map (compare)
  "Create a new tree-map."
    (%make-tree-map (lambda (pair-1 pair-2)
                      (funcall compare (car pair-1) (car pair-2)))
                    nil))

(defun tree-map-insert (tree-map key value)
  "Insert KEY=>VALUE into TREE-MAP, returning the new tree-map."
  (%make-tree-map (tree-map-compare tree-map)
                  (avl-tree-insert (tree-map-root tree-map)
                                   (cons key value)
                                   (tree-map-compare tree-map))))

(defun tree-map-remove (tree-map key)
  "Insert KEY from TREE-MAP, returning the new tree-map."
  (%make-tree-map (tree-map-compare tree-map)
                  (avl-tree-remove (tree-map-root tree-map)
                                   (cons key nil)
                                   (tree-map-compare tree-map))))

(defun tree-map-find (tree-map key)
  (let ((node (binary-tree-search-node (tree-map-root tree-map)
                                       (cons key nil)
                                       (tree-map-compare tree-map))))
    (if node
        (values (binary-tree-value node) t)
        (values nil nil))))


(defun map-tree-map (order result-type function tree-map)
  "Apply FUNCTION to all elements in TREE-MAP.
ORDER: (or :inorder :preorder :postorder
RESULT-TYPE: (or nil 'list)
FUNCTION: (lambda (key value))"
  (%make-tree-map (tree-map-compare tree-map)
  (map-binary-tree order result-type
                   (lambda (pair) (funcall function (car pair) (cdr pair)))
                   (tree-map-root tree-map))))

;;;;;;;;;;;;;;;
;; TREE-SET ;;
;;;;;;;;;;;;;;;

(defstruct (tree-set (:constructor %make-tree-set (compare root)))
  compare
  root)

(defun make-tree-set (compare)
  "Create a new tree-set."
    (%make-tree-set compare nil))

(defun tree-set (compare &rest args)
  (%make-tree-set compare
                  (fold (lambda (tree x) (avl-tree-insert tree x compare))
                        nil
                        args)))

(defun map-tree-set (result-type function set)
  (map-binary-tree :inorder result-type function (tree-set-root set)))

(defmacro def-tree-set-item-op (name implementation-name)
  `(defun ,name (set item)
     (%make-tree-set (tree-set-compare set)
                     (,implementation-name (tree-set-root set)
                                           item
                                           (tree-set-compare set)))))

(def-tree-set-item-op tree-set-insert avl-tree-insert)
(def-tree-set-item-op tree-set-remove avl-tree-remove)

(defun tree-set-member-p (set item)
  (binary-tree-member-p (tree-set-root set) item (tree-set-compare set)))

(defmacro def-tree-set-binop (name implementation-name)
  `(defun ,name (set-1 set-2)
     (%make-tree-set (tree-set-compare set-1)
                     (,implementation-name (tree-set-root set-1)
                                           (tree-set-root set-2)
                                           (tree-set-compare set-1)))))

(def-tree-set-binop tree-set-union avl-tree-union)
(def-tree-set-binop tree-set-intersection avl-tree-intersection)
(def-tree-set-binop tree-set-difference avl-tree-difference)

(defun tree-set-equal (set-1 set-2)
  (binary-tree-equal (tree-set-root set-1)
                     (tree-set-root set-2)
                     (tree-set-compare set-1)))

(defun tree-set-subset (set-1 set-2)
  (binary-tree-subset (tree-set-root set-1)
                     (tree-set-root set-2)
                     (tree-set-compare set-1)))



;;;;;;;;;;;;;;;
;; RED-BLACK ;;
;;;;;;;;;;;;;;;

;; Based on Chris Okasaki's Functional red-black trees
;; (defstruct (red-black
;;              (:include binary-tree)
;;              (:constructor make-red-black (red left value right)))
;;   (red nil :type boolean))

;; (defun red-black-redp (tree)
;;   (red-black-red tree))

;; (defun red-black-blackp (tree)
;;   (not (red-black-redp tree)))

;; (defun red-black-color (red tree)
;;   (make-red-black red
;;                   (red-black-left tree)
;;                   (red-black-value tree)
;;                   (red-black-right tree)))

;; (defun balance-red-black (red left value right)
;;   (labels ((when-red (tree)
;;              (when (red-black-p tree) (red-black-redp tree)))
;;            (balanced-tree (a x b y c z d)
;;              ;(declare (type red-black a b c d))
;;              (make-red-black t
;;                              (make-red-black nil a x b)
;;                              y
;;                              (make-red-black nil c z d))))
;;     (let* ((b (null red))
;;            (l (when-red left))
;;            (r (when-red right))
;;            (ll (when-red (when (red-black-p left)  (red-black-left left ))))
;;            (lr (when-red (when (red-black-p left)  (red-black-right left))))
;;            (rl (when-red (when (red-black-p right) (red-black-left right))))
;;            (rr (when-red (when (red-black-p right) (red-black-right right)))))
;;       (declare (type boolean b l r ll lr rl rr))
;;       (cond
;;         ((and b l ll)
;;          (balanced-tree (binary-tree-left-left left)
;;                         (binary-tree-value-left left)
;;                         (binary-tree-right-left left)
;;                         (binary-tree-value left)
;;                         (binary-tree-right left)
;;                         value
;;                         right))
;;         ((and b l lr)
;;          (balanced-tree (binary-tree-left left)
;;                         (binary-tree-value left)
;;                         (binary-tree-left-right left)
;;                         (binary-tree-value-right left)
;;                         (binary-tree-right-right left)
;;                         value
;;                         right ))
;;         ((and b r rl)
;;          (balanced-tree left
;;                         value
;;                         (binary-tree-left-left right)
;;                         (binary-tree-value-left right)
;;                         (binary-tree-right-left right)
;;                         (binary-tree-value right)
;;                         (binary-tree-right right)))
;;         ((and b r rr)
;;          (balanced-tree left
;;                         value
;;                         (binary-tree-left right)
;;                         (binary-tree-value right)
;;                         (binary-tree-left-right right)
;;                         (binary-tree-value-right right)
;;                         (binary-tree-right-right right)))
;;         (t
;;          (make-red-black red left value right))))))

;; (defun red-black-insert (value tree compare test)
;;   (labels ((ins (tree)
;;              (cond
;;                ((null tree) (make-red-black t nil value nil))
;;                ((funcall compare value (red-black-value tree))
;;                 (balance-red-black (red-black-red tree)
;;                                    (ins (red-black-left tree))
;;                                    (red-black-value tree)
;;                                    (red-black-right tree)))
;;                ((funcall test value (red-black-value tree))
;;                 tree)
;;                (t (balance-red-black (red-black-red tree)
;;                                      (red-black-left tree)
;;                                      (red-black-value tree)
;;                                      (ins (red-black-right tree)))))))
;;     (red-black-color nil (ins tree))))
