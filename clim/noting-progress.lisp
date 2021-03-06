;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; Package: CLIM-INTERNALS; Base: 10; Lowercase: Yes -*-
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
;; $Id: noting-progress.lisp,v 2.7 2007/04/17 21:45:50 layer Exp $

(in-package :clim-internals)

;;;"Copyright (c) 1991, 1992 Symbolics, Inc.  All rights reserved."


(defvar *progress-notes* ())
(defvar *current-progress-note*)

(defclass progress-note ()
    ((name   :accessor progress-note-name :initarg :name)
     (stream :initarg :stream)
     (frame  :initarg :frame)
     (numerator   :initform 0)
     (denominator :initform 1)
     ;; Keep the flicker down as much as possible
     (name-displayed :initform nil)
     (bar-length :initform 0)))
    
(define-constructor make-progress-note progress-note (name stream frame)
  :name name :stream stream :frame frame)

(defmethod (setf progress-note-name) :after (name (note progress-note))
  (declare (ignore name))
  (with-slots (name-displayed bar-length frame) note
    (setq name-displayed nil
          bar-length 0)
    (frame-manager-display-progress-note (frame-manager frame) note)))

(defun add-progress-note (name stream)
  (check-type name string)
  (when (or (null stream) (eq stream 't))
    (setq stream (frame-pointer-documentation-output *application-frame*)))
  (let ((note (make-progress-note name stream *application-frame*)))
    (without-scheduling
      (push note *progress-notes*))
    note))

(defun remove-progress-note (note)
  (without-scheduling
    (setq *progress-notes* (delete note *progress-notes*))))

(defmethod progress-note-fraction-done ((note progress-note))
  (with-slots (numerator denominator) note
    (/ numerator denominator)))

(defmacro noting-progress ((stream name &optional (note-var '*current-progress-note*))
                           &body body)
  (check-type note-var symbol)
  `(invoke-with-noting-progress
    ,stream ,name #'(lambda (,note-var) ,@body)))

(defun invoke-with-noting-progress (stream name continuation)
  (let ((note (add-progress-note name stream)))
    (frame-manager-invoke-with-noting-progress 
     (frame-manager (if (typep stream '(or basic-pane standard-encapsulating-stream))
                        (pane-frame stream) *application-frame*))
     note continuation)))

(defmethod frame-manager-invoke-with-noting-progress ((framem standard-frame-manager)
                                                      note continuation)
  (unwind-protect (funcall continuation note)
    (with-slots (stream) note
      (when stream
        (window-clear stream)))))

(defmethod frame-manager-invoke-with-noting-progress ((framem null)
                                                      note continuation)
  (funcall continuation note))

(defun note-progress (numerator &optional (denominator 1) (note *current-progress-note*))
  (when note
    (when (and (= denominator 1) (rationalp numerator))
      (let ((num   (numerator   numerator))
            (denom (denominator numerator)))
        (setq numerator   num 
              denominator denom)))
    (setf (slot-value note 'numerator) numerator
          (slot-value note 'denominator) denominator)
    (frame-manager-display-progress-note (frame-manager (slot-value note 'frame)) note))
  nil)

(defun note-progress-in-phases (numerator
                                &optional (denominator 1)
                                          (phase-number 1) (n-phases 1)
                                          (note *current-progress-note*))
  (note-progress (+ (* denominator (1- phase-number)) numerator)
                 (* denominator n-phases)
                 note)
  nil)

(defmacro dolist-noting-progress ((var listform name
                                   &optional stream (note-var '*current-progress-note*))
                                  &body body)
  (let ((count-var '#:count)
        (total-var '#:total)
        (list-var '#:list))
    `(noting-progress (,stream ,name ,note-var)
       (let* ((,list-var ,listform)
              (,total-var (length ,list-var))
              (,count-var 0))
         (dolist (,var ,list-var)
           ,@body
           (incf ,count-var)
           (note-progress ,count-var ,total-var ,note-var))))))

(defmacro dotimes-noting-progress ((var countform name
                                    &optional stream (note-var '*current-progress-note*))
                                   &body body)
  (let ((count-var '#:count))
    `(let ((,count-var ,countform))
       (noting-progress (,stream ,name ,note-var)
         (dotimes (,var ,count-var)
           ,@body
           ;; We want the progress bar to advance after the first iteration
           ;; even though DOTIMES is zero-based, so add one to the numerator.
           (note-progress (1+ ,var) ,count-var ,note-var))))))

(defmethod frame-manager-display-progress-note
    ((framem standard-frame-manager) (note progress-note))
  (with-slots (name stream numerator denominator name-displayed bar-length) note
    (when stream
      (window-clear stream)
      (with-output-recording-options (stream :record nil)
        (with-end-of-line-action (stream :allow)
          (with-end-of-page-action (stream :allow)
            (format stream "~A: ~3d%" name (round (* 100 numerator) denominator)))))
      (force-output stream))))

(defmethod frame-manager-display-progress-note
    ((framem null) (note progress-note))
  nil)

