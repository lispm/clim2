;; -*- mode: common-lisp; package: postscript-clim -*-
;;
;;
;; copyright (c) 1985, 1986 Franz Inc, Alameda, CA  All rights reserved.
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
;; $Id: postscript-s.lisp,v 2.7 2007/04/17 21:45:52 layer Exp $


(in-package :postscript-clim)

(macrolet ((def-ps-stubs (functions macros)
	       `(progn
		  ,@(mapcar #'(lambda (fn)
				`(excl::def-autoload-function ,fn "climps.fasl"))
			    functions)
		  ,@(mapcar #'(lambda (macro)
				`(excl::def-autoload-macro ,macro "climps.fasl"))
			    macros))))
  (def-ps-stubs
      ;;-- We have to do this because its not exported.
      ;;-- if it were we could make the package autoloaded too
      (invoke-with-output-to-postscript-stream)
      (with-output-to-postscript-stream)))

