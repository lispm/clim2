;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; Package: CLIM-UTILS; Base: 10; Lowercase: Yes -*-
;; copyright (c) 1985,1986 Franz Inc, Alameda, Ca.
;; copyright (c) 1986-2005 Franz Inc, Berkeley, CA  - All rights reserved.
;; copyright (c) 2002-2007 Franz Inc, Oakland, CA - All rights reserved.
;;
;; The software, data and information contained herein are proprietary
;; to, and comprise valuable trade secrets of, Franz, Inc.  They are
;; given in confidence by Franz, Inc. pursuant to a written license
;; agreement, and may be stored and used only in accordance with the terms
;; of such license.
;;
;; Restricted Rights Legend
;; ------------------------
;; Use, duplication, and disclosure of the software, data and information
;; contained herein by any agency, department or entity of the U.S.
;; Government are subject to restrictions of Restricted Rights for
;; Commercial Software developed at private expense as specified in
;; DOD FAR Supplement 52.227-7013 (c) (1) (ii), as applicable.
;;
;; $Id: condpat.lisp,v 2.7 2007/04/17 21:45:54 layer Exp $

(in-package :clim-utils)

;;;"Copyright (c) 1990 International Lisp Associates.  All rights reserved."

;;; Lucid and Franz have an old syntax for defining conditions.  We define
;;; a macro here which supports [a subset of] the ANSI syntax and which
;;; forwards to their syntax.  Then we can just write DEFINE-CONDITION
;;; with [relative] impunity.  I suppose there is some question about
;;; whether this macro should be in all implementations so that we can
;;; detect the non-portable cases more easily.  I'll think about it.
(defmacro define-condition (name parent-types &optional slots &rest options)
  (let ((readers nil)
	(real-slots slots)
	(trampoline-define-condition
	  (intern (symbol-name 'define-condition)
		  (find-package #+Lucid :lucid-common-lisp
				#-Lucid :conditions)))
	(conc-name (format nil "~A-~A-" name 'accessor-for)))
    (unless parent-types
      (setq parent-types '(condition)))
    (unless (keywordp (first slots))
      (setq real-slots nil)
      (dolist (slot slots)
	(let ((reader (getf (rest slot) ':reader)))
	  (when reader
	    (let ((trampoline (intern (format nil "~A~A" conc-name (first slot))
				      (symbol-package name))))
	      ;; Not likely to be EQL, but can causes an infinite loop
	      ;; in Lucid if it is...
	      (unless (eq trampoline reader)
		(push `(eval-when (compile load eval)
			 (proclaim '(inline ,reader))) readers)
		(push `(defun ,reader (condition)
			 (,trampoline condition)) readers)))))
	(let ((initarg (getf (rest slot) ':initarg)))
	  (unless (eq initarg (intern (symbol-name (first slot)) *keyword-package*))
	    (error "We can't support initargs to DEFINE-CONDITION that ~
                    don't match the slot name.")))
	(let ((initform (getf (rest slot) ':initform)))
	  (if initform
	      (push `(,(first slot) ,initform) real-slots)
	      (push `(,(first slot)) real-slots)))))
    `(progn (,trampoline-define-condition ,name ,parent-types ,(nreverse real-slots)
	     (:conc-name ,conc-name)
	     ,@options)
	    ,@(nreverse readers))))
