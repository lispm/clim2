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
;; $Id: present.lisp,v 2.7 2007/04/17 21:45:50 layer Exp $

(in-package :clim-internals)

;;;"Copyright (c) 1990, 1991, 1992 Symbolics, Inc.  All rights reserved."

(defun present (object &optional (presentation-type (presentation-type-of object))
                &rest present-args
                &key (stream *standard-output*) 
                     (view (stream-default-view stream))
                     (for-context-type presentation-type)
                     query-identifier
                &allow-other-keys)
  #-acl86win32
  (declare (dynamic-extent present-args))
  (declare (arglist object &optional (presentation-type (presentation-type-of object))
                    &rest present-args
                    &key (stream *standard-output*)
                         (view (stream-default-view stream))
                         (modifier nil) (acceptably nil)
                         (for-context-type presentation-type) (single-box nil)
                         (allow-sensitive-inferiors *allow-sensitive-inferiors*)
                         (sensitive *allow-sensitive-inferiors*)
                         prompt query-identifier
                         (record-type 'standard-presentation)
                    &allow-other-keys))
  (multiple-value-bind (expansion expanded)
      (expand-presentation-type-abbreviation presentation-type)
    (when expanded
      (when (eq for-context-type presentation-type)
        (setq for-context-type expansion))
      (setq presentation-type expansion)))
  (unless (eq for-context-type presentation-type)
    (multiple-value-bind (expansion expanded)
        (expand-presentation-type-abbreviation for-context-type)
      (when expanded
        (setq for-context-type expansion))))

  (typecase view
    (null)
    (symbol (setq view (make-instance view)))
    (cons   (setq view (apply #'make-instance view))))
  (setq view (decode-indirect-view presentation-type view (frame-manager stream)
                                   :query-identifier query-identifier
                                   :read-only t))

  (with-keywords-removed (present-args present-args '(:stream :view :for-context-type))
    (apply #'stream-present stream object presentation-type 
                            :view view :for-context-type for-context-type
                            present-args)))

;; Specialize on T since this method is good for all stream classes
(defmethod stream-present ((stream t) object presentation-type
                           &key (view (stream-default-view stream))
                                (modifier nil) (acceptably nil)
                                (for-context-type presentation-type) (single-box nil)
                                (allow-sensitive-inferiors *allow-sensitive-inferiors*) 
                                (sensitive *allow-sensitive-inferiors*)
                                (prompt nil prompt-p)
                                (record-type 'standard-presentation)
                           &allow-other-keys)

  ;; The arguments are allowed to be presentation type abbreviations
  (multiple-value-bind (expansion expanded)
      (expand-presentation-type-abbreviation presentation-type)
    (when expanded
      (when (eq for-context-type presentation-type)
        (setq for-context-type expansion))
      (setq presentation-type expansion)))
  (unless (eq for-context-type presentation-type)
    (multiple-value-bind (expansion expanded)
        (expand-presentation-type-abbreviation for-context-type)
      (when expanded
        (setq for-context-type expansion))))

  #+compulsive-type-checking
  (unless (presentation-typep object presentation-type)
    (cerror "Use the type ~*~*~S instead"
            "The object ~S is not of type ~S"
            object presentation-type (class-name (class-of object))))

  ;; Make a presentation if desired, and call the type's PRESENT method
  ;; to fill it in
  (if (and sensitive
           ;; The right way to fix this is probably to make all the
           ;; WITH-xxx macros turn into noops on non-window-streams, but
           ;; this is easier and less expensive.
           (extended-output-stream-p stream))
      (with-output-as-presentation (stream object presentation-type
                                    :modifier modifier
                                    :single-box single-box
                                    :allow-sensitive-inferiors allow-sensitive-inferiors
                                    :record-type record-type)
        (apply-presentation-generic-function present
          object presentation-type stream view
          :acceptably acceptably :for-context-type for-context-type
          (and prompt-p (list :prompt prompt))))
      (let ((*allow-sensitive-inferiors* allow-sensitive-inferiors))
        (apply-presentation-generic-function present
          object presentation-type stream view
          :acceptably acceptably :for-context-type for-context-type
          (and prompt-p (list :prompt prompt))))))

(defun present-to-string (object
                          &optional (presentation-type (presentation-type-of object))
                          &key (view +textual-view+) (acceptably nil)
                               (for-context-type presentation-type)
                               string index)
  (cond (string
         (when index
           (setf (fill-pointer string) index))
         (with-output-to-string (stream string)
           (present object presentation-type :stream stream :view view
                    :acceptably acceptably :for-context-type for-context-type))
         (values string (fill-pointer string)))
        (t
         (with-output-to-string (stream)
           (present object presentation-type :stream stream :view view
                    :acceptably acceptably :for-context-type for-context-type)))))

;; Like WITH-OUTPUT-TO-STRING, but stream is a full output-recording
;; protocol stream so all CLIM operations "just work", rather than having
;; to special-case them all for string streams.  Result is a string
;; representation of the output.  STREAM must be an actual window; the
;; formatting of the string will match the dimensions of the window.
(defmacro with-presentations-to-string 
          ((stream &optional string
                   &rest options
                   &key (element-type ''character)
                        (end-of-line-action ':allow) (end-of-page-action ':allow))
           &body body)
  (declare (ignore element-type end-of-line-action end-of-page-action))
  (default-output-stream stream with-presentations-to-string)
  `(flet ((with-presentations-to-string-body (,stream) ,@body))
     (declare (dynamic-extent #'with-presentations-to-string-body))
     (invoke-with-presentations-to-string 
       ,stream #'with-presentations-to-string-body ,string ,@options)))

(defun invoke-with-presentations-to-string 
       (stream continuation string
        &key (element-type 'character) 
             (end-of-line-action ':allow) (end-of-page-action ':allow))
  (let ((record
          (with-end-of-line-action (stream end-of-line-action)
            (with-end-of-page-action (stream end-of-page-action)
              (with-output-to-output-record (stream)
                (funcall continuation stream))))))
    (when (null string)
      (setq string (make-array 40 :fill-pointer 0 :element-type element-type)))
    (with-output-to-string (s string)
      (copy-textual-output-history stream s nil record)
      string)))
