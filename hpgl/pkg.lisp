;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; Package: CL-USER; Base: 10; Lowercase: Yes -*-

;; $Id: pkg.lisp,v 2.5 2004/01/16 19:15:43 layer Exp $

;; Copyright (c) 1991 by International Lisp Associates.  All rights reserved.
;; copyright (c) 1992 Franz Inc, Berkeley, CA - All rights reserved.
;; copyright (c) 1992-2004 Franz Inc, Oakland, CA - All rights reserved.

(in-package :common-lisp-user)

(provide :climhpgl)

(defpackage :hpgl-clim
  (:export #:with-output-to-hpgl-stream)
  (:use clim-lisp clim-sys clim clim-utils clim-silica))

#+allegro
(setf (package-definition-lock (find-package :hpgl-clim)) t)
