;; -*- mode: common-lisp; package: clim-demo -*-
;;
;;				-[]-
;; 
;; copyright (c) 1985, 1986 Franz Inc, Alameda, CA  All rights reserved.
;; copyright (c) 1986-1992 Franz Inc, Berkeley, CA  All rights reserved.
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
;; $fiHeader: bitmap-editor.lisp,v 1.1 92/09/08 10:39:09 cer Exp Locker: cer $


(in-package :clim-demo)

(define-application-frame bitmap-editor ()
			  ((rows :initarg :rows :initform 8)
			   (cell-size :initarg :cell-size :initform 10)
			   (columns :initarg :columns :initform 8)
			   (array :initarg :array :initform nil)
			   (current-color :initarg :current-color :initform 0)
			   (colors :initarg :colors :initform 
				   (list +background-ink+ +foreground-ink+)))
  (:panes
   (palette :accept-values :scroll-bars  :vertical :width :compute :height :compute
	    :display-function '(accept-values-pane-displayer 
				:displayer display-palette))
   (edit-pane :application :scroll-bars  :both :width :compute :height :compute)
   (pattern-pane :application  :scroll-bars nil :width :compute :height :compute))
  (:layouts (default (horizontally () palette edit-pane pattern-pane))))

(defun display-palette (frame stream)
  (with-slots (colors current-color) frame
    (flet ((display-color (object stream)
	     (with-room-for-graphics (stream)
	       (draw-rectangle* stream 0 0 30 10 :ink object))))
      (formatting-item-list (stream :n-columns 2)
	  (formatting-cell (stream)
	      (setf current-color
		(position
		 (accept `((completion ,colors)
			   :name-key ,#'identity
			   :printer ,#'display-color)
			 :view '(clim-internals::radio-box-view 
				 :orientation :vertical
				 :toggle-button-options (:indicator-type nil))
			 :stream stream
			 :default (nth current-color colors)
			 :prompt "Colors")
		 colors)))
	(formatting-cell (stream)
	    (formatting-item-list (stream :n-columns 1)
		(formatting-cell (stream)
		    (accept-values-command-button (stream)
		      "Add Color"
		      (add-color-to-palette frame)))
	      (formatting-cell (stream)
		  (accept-values-command-button (stream)
		    "Edit Color"
		    (replace-current-color frame)))
	      (formatting-cell (stream)
		  (accept-values-command-button (stream)
		    "Delete Color"
		    (delete-current-color frame)))))))))

(defun replace-current-color (frame)
  ;;--- Exercise for the reader
  )

(defun delete-current-color (frame)
  ;;--- Exercise for the reader
  )

(defun add-color-to-palette (frame)
  (let ((fr (make-application-frame 'color-chooser)))
    (run-frame-top-level fr)
    (with-slots (colors) frame
      (setq colors (append colors (list (color fr)))))))


(define-bitmap-editor-command (com-display-options :menu t)
    ()
  (let* ((frame *application-frame*)
	 (rows (slot-value frame 'rows))
	 (columns (slot-value frame 'columns))
	 (cell-size (slot-value frame 'cell-size))
	 (view '(clim-internals::slider-view :show-value-p t)))
    (accepting-values (*query-io* :own-window t :label "Editor options")
	(setq rows (accept '(integer 1 256) 
			   :view view
			   :default rows
			   :prompt "Rows"
			   :stream *query-io*))
      (terpri *query-io*)
      (setq columns (accept '(integer 1 256) 
			   :view view
			    :default columns
			    :prompt "Columns"
			    :stream *query-io*))
      (terpri *query-io*)
      (setq cell-size (accept '(integer 10 100) 
			   :view view
			      :default cell-size
			      :prompt "Cell Size"
			      :stream *query-io*))
      (terpri *query-io*))
    (setf (slot-value frame 'rows) rows
	  (slot-value frame 'columns) columns
	  (slot-value frame 'cell-size) cell-size
	  (slot-value frame 'array)
	  (adjust-array (slot-value frame 'array) (list rows columns)
			:initial-element 0))
    (display-everything frame)))
    
(defmethod initialize-instance :after ((frame bitmap-editor) &key)
  (with-slots (rows columns array) frame
    (setf array (make-array (list rows columns) :initial-element 0))))
    
(defmethod display-grid (frame pane)
  (with-slots (rows columns cell-size) frame
    (let ((maxx (* rows (1+ cell-size)))
	  (maxy (* columns (1+ cell-size))))
      (dotimes (i (1+ rows))
	(draw-line* pane 0 (* i (1+ cell-size)) maxx (* i (1+ cell-size))))
      (dotimes (i (1+ columns))
	(draw-line* pane (* i (1+ cell-size)) 0 (* i (1+ cell-size)) maxy)))))

(defmethod display-cells (frame pane)
  (with-slots (rows columns cell-size) frame
    (dotimes (i rows)
	(dotimes (j columns)
	  (display-cell frame pane i j)))))

(define-presentation-type bitmap-editor-cell ())

(define-presentation-method presentation-typep (object (type bitmap-editor-cell))
  (and (listp object) (= 2 (length object))))

(defun display-cell (frame pane i j)
  (with-slots (cell-size array colors) frame
    (let ((x (* j (1+ cell-size)))
	  (y (* i (1+ cell-size))))
      (with-output-as-presentation (pane (list i j) 'bitmap-editor-cell)
	(draw-rectangle* pane (+ x 2) 
			 (+ y 2)
			 (+ x (- cell-size 2))
			 (+ y (- cell-size 2))
			 :ink (nth  (aref array i j) colors)
			 :filled t)))))

(defun display-pattern (frame)
  (let ((stream (get-frame-pane frame 'pattern-pane)))
    (with-slots (array rows columns colors) frame
      (window-clear stream)
      (surrounding-output-with-border (stream)
	  (draw-rectangle* stream 10 10 (+ 10 rows) (+ 10 columns)
			   :ink 
			   (make-pattern array colors))))))

(defmethod run-frame-top-level :before ((frame bitmap-editor))
  (display-everything frame))

(defun display-everything (frame)
  (let ((stream (get-frame-pane frame 'edit-pane)))
    (window-clear stream)
    (display-grid frame stream)
    (display-cells frame stream)
    (display-pattern frame)))

(define-presentation-to-command-translator toggle-cell
    (bitmap-editor-cell com-toggle-cell bitmap-editor :gesture :select)
  (presentation object)
  (list presentation object))

(define-bitmap-editor-command com-toggle-cell
    ((presentation 'presentation)
     (cell 'bitmap-editor-cell))
  (let ((frame *application-frame*))
    (destructuring-bind (i j) cell
      (with-slots (array current-color) frame
	(setf (aref array i j) current-color))
      (let ((stream (get-frame-pane frame 'edit-pane)))
	(erase-output-record presentation stream)
	(display-cell frame stream i j)
	(display-pattern frame)))))


(defvar *bitmap-editors* nil)

(defun do-bitmap-editor (&key (port (find-port)) (force nil))
  (let* ((framem (find-frame-manager :port port))
	 (frame 
	   (let* ((entry (assoc port *bitmap-editors*))
		  (frame (cdr entry)))
	     (when (or force (null frame))
	       (setq frame (make-application-frame 'bitmap-editor
						   :frame-manager framem)))
	     (if entry 
		 (setf (cdr entry) frame)
		 (push (cons port frame) *bitmap-editors*))
	     frame)))
    (run-frame-top-level frame)))

(define-demo "Bitmap Editor" do-bitmap-editor)





  