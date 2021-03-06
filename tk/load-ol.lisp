;; -*- mode: common-lisp; package: user -*-
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
;; $Id: load-ol.lisp,v 2.7 2007/04/17 21:45:53 layer Exp $

(in-package :user)

(require :climg)

#+dlfcn
(progn
  (defvar sys::*toolkit-shared* nil)

  (unless (ff:get-entry-point (ff:convert-foreign-name "ol_appl_add_item")
			      #-(version>= 5 0) :note-shared-library-references
			      #-(version>= 5 0) nil)
    (load "clim2:;climol.so")
    (setq sys::*toolkit-shared* t)))

#-dlfcn
(progn
  (defvar sys::*libtk-pathname* "Ol")
  (defvar sys::*libxt-pathname* "Xt")

  (unless (ff:get-entry-point (ff:convert-foreign-name "XtToolkitInitialize"))
    (load "stub-olit.o"
	  :system-libraries (list sys::*libtk-pathname*
				  sys::*libxt-pathname*
				  sys::*libx11-pathname*)
	  :print t)
    (load "stub-xt.o"
	  :system-libraries (list sys::*libxt-pathname*
				  sys::*libx11-pathname*)
	  :print t))

  (unless (ff:get-entry-point (ff:convert-foreign-name "ol_appl_add_item"))
    (load "olsupport.o"
	  :system-libraries (list sys::*libtk-pathname*
				  sys::*libxt-pathname*
				  sys::*libx11-pathname*)
	  :print t))

  (unless (ff:get-entry-point (ff:convert-foreign-name "XtAppIntervalNextTimer"))
    (load "xtsupport.o"
	  :system-libraries (list sys::*libxt-pathname*
				  sys::*libx11-pathname*)
	  :print t)))

(pushnew :clim-openlook *features*)
