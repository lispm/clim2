;; -*- mode: common-lisp; package: tk -*-
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
;; $fiHeader: ol-funs.lisp,v 1.9 93/03/31 10:40:00 cer Exp $

;;
;; This file contains compile time only code -- put in clim-debug.fasl.
;;

(in-package :tk)

(defforeign 'ol_toolkit_initialize
    :entry-point (ff:convert-to-lang "OlToolkitInitialize")
    :call-direct t
    :arguments nil 
    :arg-checking nil
    :return-type :void)

(defforeign 'ol_set_warning_handler 
    :entry-point (ff:convert-to-lang "OlSetWarningHandler")
    :call-direct t
    :arguments '(integer)
    :arg-checking nil
    :return-type :unsigned-integer)

(defforeign 'ol_set_error_handler 
    :entry-point (ff:convert-to-lang "OlSetErrorHandler")
    :call-direct t
    :arguments '(integer)
    :arg-checking nil
    :return-type :unsigned-integer)

(defforeign 'ol_set_va_display_error_msg_handler
    :entry-point (ff:convert-to-lang "OlSetVaDisplayErrorMsgHandler")
    :call-direct t
    :arguments '(integer)
    :arg-checking nil
    :return-type :unsigned-integer)

(defforeign 'ol_set_va_display_warning_msg_handler
    :entry-point (ff:convert-to-lang "OlSetVaDisplayWarningMsgHandler")
    :call-direct t
    :arguments '(integer)
    :arg-checking nil
    :return-type :unsigned-integer)
    
(defforeign 'ol_add_callback
    :entry-point (ff:convert-to-lang "OlAddCallback")
    :call-direct t
    :arguments '(foreign-address foreign-address foreign-address foreign-address)
    :arg-checking nil
    :return-type :void)

(defforeign 'ol_call_accept_focus
    :entry-point (ff:convert-to-lang "OlCallAcceptFocus")
    :call-direct t
    :arguments '(foreign-address integer)
    :arg-checking nil
    :return-type :unsigned-integer)

(defforeign 'ol_can_accept_focus
    :entry-point (ff:convert-to-lang "OlCanAcceptFocus")
    :call-direct t
    :arguments '(foreign-address integer)
    :arg-checking nil
    :return-type :unsigned-integer)

(defforeign 'ol_set_input_focus
    :entry-point (ff:convert-to-lang "OlSetInputFocus")
    :call-direct t
    :arguments '(foreign-address fixnum integer)
    :arg-checking nil
    :return-type :void)

(defforeign 'ol_move_focus
    :entry-point (ff:convert-to-lang "OlMoveFocus")
    :call-direct t
    :arguments '(foreign-address fixnum integer)
    :arg-checking nil
    :return-type :void)

(defforeign 'ol_get_current_focus_widget
    :entry-point (ff:convert-to-lang "OlGetCurrentFocusWidget")
    :call-direct t
    :arguments '(foreign-address)
    :arg-checking nil
    :return-type :unsigned-integer)

(defforeign 'ol_menu_post
    :entry-point (ff:convert-to-lang "OlMenuPost")
    :call-direct t
    :arguments '(foreign-address)
    :arg-checking nil
    :return-type :void)
    
(defforeign 'ol_menu_popdown
    :entry-point (ff:convert-to-lang "OlMenuPopdown")
    :call-direct t
    :arguments '(foreign-address fixnum)
    :arg-checking nil
    :return-type :void)
    
(defforeign 'ol_text_edit_clear_buffer
    :entry-point (ff:convert-to-lang "OlTextEditClearBuffer")
    :call-direct t
    :arguments '(foreign-address)
    :arg-checking nil
    :return-type :fixnum)

(defforeign 'ol_text_edit_read_substring
    :entry-point (ff:convert-to-lang "OlTextEditReadSubString")
    :call-direct t
    :arguments '(foreign-address foreign-address fixnum fixnum)
    :arg-checking nil
    :return-type :fixnum)

(defforeign 'ol_text_edit_insert
    :entry-point (ff:convert-to-lang "OlTextEditInsert")
    :call-direct t
    :arguments '(foreign-address foreign-address fixnum)
    :arg-checking nil
    :return-type :fixnum)
    
(defforeign 'ol_text_edit_get_last_position
    :entry-point (ff:convert-to-lang "OlTextEditGetLastPosition")
    :call-direct t
    :arguments '(foreign-address foreign-address)
    :arg-checking nil
    :return-type :fixnum)
    
(defforeign 'ol_register_help
    :entry-point (ff:convert-to-lang "OlRegisterHelp")
    :call-direct t
    :arguments '(fixnum foreign-address foreign-address fixnum foreign-address)
    :arg-checking nil
    :return-type :void)

(defforeign 'ol_appl_add_item
    :entry-point (ff:convert-to-lang "ol_appl_add_item")
    :call-direct t
    :arguments '(integer foreign-address foreign-address foreign-address
		 foreign-address)
    :arg-checking nil
    :return-type :unsigned-integer)

(defforeign 'ol_appl_delete_item
    :entry-point (ff:convert-to-lang "ol_appl_delete_item")
    :call-direct t
    :arguments '(integer foreign-address integer)
    :arg-checking nil
    :return-type :unsigned-integer)

    
(defforeign 'ol_list_item_pointer
    :entry-point (ff:convert-to-lang "ol_list_item_pointer")
    :call-direct t
    :arguments '(integer)
    :arg-checking nil
    :return-type :unsigned-integer)

(defforeign 'ol_appl_touch_item
    :entry-point (ff:convert-to-lang "ol_appl_touch_item")
    :call-direct t
    :arguments '(integer foreign-address integer)
    :arg-checking nil
    :return-type :void)
