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
;; $Id: pkg.lisp,v 2.7 2007/04/17 21:45:53 layer Exp $

(defpackage :tk
  ;;-- No we really need
  ;; to use the x11 package?
  (:use :common-lisp :ff #+ignore :x11)
  (:nicknames :xt)
  (:import-from :excl #:if*)
  (:import-from :clim-utils #:fintern #:package-fintern)
  (:export
   #:initialize-motif-toolkit
   #:widget-parent
   #:manage-child
   #:get-values
   #:top-level-shell
   #:popup
   #:popdown
   #:manage-child
   #:realize-widget
   #:card32
   #:card29
   #:card24
   #:card16
   #:card8
   #:int32
   #:int16
   #:int8
   #:with-server-grabbed
   #:window-property-list
   ))

(setf (package-definition-lock (find-package :tk)) t)

(in-package :tk)
