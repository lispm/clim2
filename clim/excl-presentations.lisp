;; -*- mode: common-lisp; package: clim-internals -*-
;;
;;				-[]-
;; 
;; copyright (c) 1985, 1986 Franz Inc, Alameda, CA  All rights reserved.
;; copyright (c) 1986-1991 Franz Inc, Berkeley, CA  All rights reserved.
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
;; Commercial Software developed at private expense as specified in FAR
;; 52.227-19 or DOD FAR Supplement 252.227-7013 (c) (1) (ii), as
;; applicable.
;;
;; $fiHeader: excl-streams.cl,v 1.2 92/02/05 21:52:04 cer Exp $


(in-package :clim-internals)

(defmethod excl::stream-recording-p ((stream output-recording-mixin))
  (stream-recording-p stream))

(defmethod excl::stream-io-record-type ((stream output-recording-mixin))
  nil)

(defclass standard-excl-presentation (standard-presentation) 
	  ()
  (:default-initargs :single-box nil))

(defmethod initialize-instance :around ((rec standard-excl-presentation)
					&rest args
					&key (type nil type-p)
					     object)
  (unless (and type-p
	       (find-presentation-type-class type nil))
    (setf (getf args :type) (presentation-type-of object)))
  (apply #'call-next-method rec args))

(defmethod excl::stream-presentation-record-type ((stream output-recording-mixin))
  (find-class 'standard-excl-presentation))

;; Record initialized with :object, :type maybe

(defvar *gross-output-history-stack* nil)

(defmethod excl::set-io-record-pos1 ((stream output-recording-mixin) record)
  (let ((current-output-position 
	 (stream-output-history-position stream)))
    (multiple-value-bind (px py)
	(point-position* current-output-position)
      (declare (type coordinate px py))
      (multiple-value-bind (cursor-x cursor-y)
	  (stream-cursor-position* stream)
	(declare (type coordinate cursor-x cursor-y))
	(multiple-value-bind (x y)
	    (position-difference* cursor-x cursor-y px py)
	  (output-record-set-start-cursor-position* record x y)
	  (stream-close-text-output-record stream)
	  (push (list (stream-current-output-record stream)
		      px py)
		*gross-output-history-stack*)
	  (setf (point-x current-output-position) cursor-x
		(point-y current-output-position) cursor-y
		(stream-current-output-record stream) record))))))

(defmethod excl::set-io-record-pos2 ((stream output-recording-mixin) record)
  (stream-close-text-output-record stream)
  (let ((current-output-position 
	 (stream-output-history-position stream))) 
    (destructuring-bind
	(parent abs-x abs-y) (pop *gross-output-history-stack*)
      
      (unless parent 
	(setq parent (stream-output-history stream)))

      (multiple-value-bind (end-x end-y)
	  (stream-cursor-position* stream)
	(declare (type coordinate end-x end-y))
	(output-record-set-end-cursor-position*
	 record (- end-x abs-x) (- end-y abs-y)))
      (setf (point-x current-output-position) abs-x
	    (point-y current-output-position) abs-y
	    (stream-current-output-record stream) parent)
      #+ignore(print (list parent abs-x abs-y) excl:*initial-terminal-io*)
      (when parent
	(add-output-record record parent)))))