;; -*- mode: common-lisp; package: clim-user -*-
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
;; $fiHeader: plot.lisp,v 1.1 92/07/02 10:00:56 cer Exp Locker: cer $


(in-package :clim-user)

;;; Clim based plotting package


(defmacro plotting-data ((stream &rest  options) &body body)
  ;; For each X value we want to specify the Y values
  ;; Specify labels for each X value
  ;; Specify label for each set of Y values
  ;; Specify the size of the graph we want draw.
  ;; Range of values for the axiss
  (let ((point-plotting-continuation (gensym))
	(plot-data-continuation (gensym)))
    `(flet ((plotting-data-body (,point-plotting-continuation ,plot-data-continuation) 
				;; Perhaps we can also have a way of
				;; specify all the points in one go
				(flet ((plot-point (x &rest ys)
					 (apply ,point-plotting-continuation x ys))
				       (plot-data (array)
					 (funcall ,plot-data-continuation array)))
				  ,@body)))
	   (invoke-plotting-data ,stream #'plotting-data-body ,@options))))

;; We should make presentations of these types

(define-presentation-type graph-plot ())
(define-presentation-type graph-region ())

(define-presentation-method presentation-typep (object (type graph-region))
  (typep object 'standard-rectangle))

(define-command-table plot-command-table)

(define-presentation-translator select-graph-region
    (graph-plot graph-region plot-command-table :gesture :select)
  (x y window)
  (let ((nx x)
	(ny y)
	(ox x)
	(oy y))
    (with-output-recording-options (window :record nil)
      (flet ((draw-it ()
	       (draw-rectangle* window nx ny ox oy :filled nil :ink +flipping-ink+)))
	(draw-it)
	(tracking-pointer
	 (window)
	 (:pointer-motion
	  (x y)
	  (draw-it) 
	  (setq nx x ny y)
	  (draw-it))
	 (:pointer-button-press
	  (x y)
	  (draw-it)
	  (setq nx x ny y)
	  (return (make-rectangle* ox oy nx ny))))))))

;; Define a presentation translator from a graph-plot to a graph-region.
;; In that way we trivially write a command that will zoom into a
;; particular region of the graph.

(define-presentation-type graph-point ())
(define-presentation-type graph-line ())

(define-presentation-type graph-axis ())

(defun invoke-plotting-data (stream continuation 
			     &key x-labels 
				  y-labels 
				  y-labelling
				  x-min y-min
				  x-max y-max 
				  width
				  height
				  (type :plot))
  (let ((points nil))
	(flet ((point-collector (x &rest ys)
		 (push (list* x ys) points))
	       (plot-data-collector (data)
		 (setq points data)))
	  (funcall continuation #'point-collector #'plot-data-collector))

	(etypecase points
	  ((array t (* *)) nil)
	  (list
	   (setq points (make-array (list (length points) (length (car points)))
				    :initial-contents (nreverse points)))))

	(multiple-value-setq  (width height)
	  (default-width-and-height stream type points  width height))
    
	(multiple-value-setq (x-min y-min x-max y-max y-labelling)
	  (default-graph-axis type points x-min y-min x-max y-max y-labelling))

	(let ((transform
	       (and (not (eq type :pie))
	       (let ((scaling-transform
		      (make-scaling-transformation
		       (/ width (- x-max x-min))
		       (/ height (- y-max y-min)))))
		 (multiple-value-bind (ox oy)
		     (transform-position scaling-transform x-min y-min)
		   (compose-transformations
		    (make-translation-transformation (- ox) (- oy))
		    scaling-transform))))))
	  (with-output-as-presentation (stream nil 'graph-plot :single-box :position)
	      (formatting-item-list (stream :n-columns 2)
		  (formatting-cell (stream)
		      (with-room-for-graphics (stream)
			(draw-axis
			 stream 
			 type
			 width height
			 x-min y-min x-max y-max
			 x-labels 
			 y-labels
			 points
			 transform
			 y-labelling)
			(draw-data stream 
				   type
				   width height x-min y-min x-max
				   y-max points transform)))
		(formatting-cell (stream)
		    (draw-caption stream type y-labels)))))))

(defun draw-caption (stream type y-labels)
  (updating-output (stream :unique-id 'captions
			   :cache-value (cons type (copy-list y-labels))
			   :cache-test #'equalp)
      (let ((n-lines (length y-labels))
	    (ascent (text-style-ascent (medium-text-style stream) stream))
	    (descent (text-style-descent (medium-text-style stream) stream))
	    (i 0))
	(surrounding-output-with-border (stream)
	    (formatting-table (stream)
		(dolist (label y-labels)
		  (formatting-row (stream)
		      (formatting-cell (stream)
			  (if (eq type :plot)
			      (progn
				(draw-rectangle* stream 0 0 20 (+ ascent descent) :ink +background-ink+)
				(draw-line* stream 0 (/ ascent 2) 20 (/ ascent 2)
					    :ink (get-contrasting-inks stream n-lines i)
					    :line-dashes
					    (get-contrasting-dash-patterns stream n-lines i)))
			    (draw-rectangle* stream 0 0 20 (+ ascent descent) :ink (get-contrasting-inks stream n-lines i))))
		    (formatting-cell (stream)
			(write-string label stream)))
		  (incf i)))))))
	    

(defun draw-axis (stream type width height x-min y-min x-max y-max x-labels y-labels points transform y-labelling)
  ;; Y Axis

  (unless (eq type :pie)
    (updating-output (stream :unique-id 'y-axis
			     :cache-value (list width height x-min y-min
						x-max
						y-max y-labelling)
			     :cache-test #'equalp)
	(with-output-as-presentation (stream nil 'graph-axis)
	  (draw-line* stream 0 0 0 height)
	  (do ((y y-min (+ y-labelling y)))
	      ((> y y-max))
	    (multiple-value-bind (tx ty) 
		(transform-position transform x-min y)
	      (draw-line* stream (- tx 2) ty (+ tx 2) ty)
	      (let ((label (format nil "~3d" y)))
		(multiple-value-bind (width height ignore-x ignore-y baseline)
		    (text-size stream label)
		  (declare (ignore ignore-x ignore-y))
		  (draw-text* stream label (- tx width 2) ty)))))))

    ;; X Axis labelling
    (updating-output (stream :unique-id 'x-axis
			     :cache-value (list width height x-min y-min
						x-max
						y-max (copy-list x-labels))
			     :cache-test #'equalp)
	(with-output-as-presentation (stream nil 'graph-axis)
	  (draw-line* stream 0 0 width 0)
	  (let ((i 0))
	    (dolist (label x-labels)
	      (multiple-value-bind (tx ty) 
		  (transform-position transform (if (eq type :bar) (1+ i) (aref points i 0)) y-min)
		(draw-line* stream tx (- ty 2) tx (+ ty 2))
		(multiple-value-bind (width height ignore-x ignore-y baseline)
		    (text-size stream label)
		  (declare (ignore ignore-x ignore-y))
		  (draw-text* stream label (- tx (/ width 2)) (- ty height 3))
		  (incf i)))))))))

(defmethod draw-data (stream (type (eql :pie)) width height x-min y-min x-max y-max points transform)
  (destructuring-bind
      (rows columns) (array-dimensions points)
    (let ((totals (make-array rows :initial-element 0))
	  (start-angles (make-array rows :initial-element 0)))
      (dotimes (i rows) (dotimes (j (1- columns)) (incf (aref totals i) (aref points i (1+ j)))))
      
      (dotimes (j (1- columns))
	(updating-output (stream :unique-id `(pie ,j)
				 :id-test #'equal
				 :cache-value (let ((r nil))
						(dotimes (i rows (nreverse r))
						  (push (aref points i (1+ j)) r))))
	    (with-output-as-presentation (stream (1+ j) 'graph-line)
	      (dotimes (i rows)
		(let ((angle (* 2 pi (/ (aref points i (1+ j)) (aref totals i)))))
		  (draw-circle* stream (+ 100 (* 125 i)) 100 50 
				:filled t
				:start-angle (aref start-angles i)
				:end-angle (incf (aref start-angles i) angle)
				:ink (get-contrasting-inks stream (1- columns)  j))))))))))


(defmethod draw-data (stream (type (eql :bar))  width height x-min y-min x-max y-max points transform)
  (destructuring-bind
      (rows columns) (array-dimensions points)
    (let* ((n-lines (1- columns))
	   (thickness 30)
	   (offset (- (* thickness n-lines 0.5))))
      (dotimes (i n-lines)
	(updating-output (stream :unique-id `(bar ,i)
				 :id-test #'equal
				 :cache-value (list x-min y-min x-max y-max width height
						    (let ((r nil))
						      (dotimes (j rows
								 (nreverse r))
							(push (aref points j 0) r)
							(push (aref
							       points j (1+ i)) r)))))
	    (with-output-as-presentation (stream (1+ i) 'graph-line)
	      (dotimes (j rows)
		(let ((x (1+ j))
		      (y (aref points j (1+ i))))
		  (multiple-value-bind (base-tx base-ty) (transform-position transform x y-min)
		    (multiple-value-bind (top-tx top-ty) (transform-position transform x y)
		      (let ((rx (+ base-tx offset (* thickness i))))
			(draw-rectangle* stream rx base-ty (+ rx thickness) top-ty 
					 :filled t :ink (get-contrasting-inks stream n-lines i)))))))))))))
				 
				 
(defmethod draw-data (stream (type (eql :plot))  width height x-min y-min x-max y-max points transform)
  (destructuring-bind
      (rows columns) (array-dimensions points)
    (let* (
	   (n-lines (1- columns)))
    
      (dotimes (i n-lines)

	(updating-output (stream :unique-id `(plot-line ,i)
				 :id-test #'equal
				 :cache-value (list x-min y-min x-max y-max width height
						    (let ((r nil))
						      (dotimes (j rows
								 (nreverse r))
							(push (aref points j 0) r)
							(push (aref points j (1+ i)) r)))))
	    (let (last-tx last-ty)
	      (with-output-as-presentation (stream (1+ i) 'graph-line)
		(draw-lines*
		 stream 
		 (let ((r nil)) 
		   (dotimes (j rows (nreverse r))
		     (let ((x (aref points j 0))
			   (y (aref points j (1+ i))))
		       (multiple-value-bind
			   (tx ty)
			   (transform-position transform x y)
			 (when last-tx 
			   (push last-tx r) 
			   (push last-ty r)
			   (push tx r)
			   (push ty r))
			 (setq last-tx tx last-ty ty)))))
		 :ink (get-contrasting-inks stream n-lines i)
		 :line-dashes (get-contrasting-dash-patterns stream n-lines i))))
      
	  (dotimes (j rows)
	    (let ((x (aref points j 0))
		  (y (aref points j (1+ i))))
	      (multiple-value-bind
		  (tx ty)
		  (transform-position transform x y)
		(with-output-as-presentation (stream (list (1+ i) j) 'graph-point)
		  (draw-circle* stream tx ty 4 :filled t :ink
				(get-contrasting-inks stream  n-lines i)))))))))))

(defun get-contrasting-dash-patterns (stream i j)
  (if (< i 2) (line-style-dashes (medium-line-style stream))
    (make-contrasting-dash-patterns i j)))

(defun get-contrasting-inks (stream i j)
  (if (< i 2) (medium-foreground stream)
    (make-contrasting-inks i j)))
      
(defmethod default-width-and-height (stream (type (eql :plot)) points width height)
  (values 400 300))

(defmethod default-width-and-height (stream (type (eql :pie)) points width height)
  (values nil nil))

(defmethod default-width-and-height (stream (type (eql :bar)) points width height)
  (destructuring-bind (rows columns) (array-dimensions points)
    (values (+ (* rows 10) (* columns rows 30))
	    300)))

(defmethod default-graph-axis ((type (eql :pie)) points supplied-x-min supplied-y-min 
						 supplied-x-max
						 supplied-y-max y-labelling)
  (declare (ignore points supplied-x-min supplied-y-min supplied-x-max
		   supplied-y-max y-labelling))
  (values))

(defmethod default-graph-axis ((type (eql :plot)) points supplied-x-min supplied-y-min 
					      supplied-x-max supplied-y-max y-labelling)
  (let ((x-min supplied-x-min)
	(y-min supplied-y-min)
	(x-max supplied-x-max)
	(y-max supplied-y-max))
    (unless (and x-min y-min x-max y-max)
      (destructuring-bind
	  (rows columns) (array-dimensions points)
	(setq x-min (aref points 0 0) x-max x-min)
	(setq y-min (aref points 0 1) y-max y-min)
	(dotimes (i rows)
	  (let ((x (aref points i 0)))
	    (clim-utils::minf x-min x)
	    (clim-utils::maxf x-max x)
	    (dotimes (j (1- columns))
	      (let ((y (aref points i (1+ j))))
		(clim-utils::minf y-min y)
		(clim-utils::maxf y-max y)))))))
    (values (or supplied-x-min x-min)
	    (or supplied-y-min y-min)
	    (or supplied-x-max x-max) 
	    (or supplied-y-max y-max)
	    (or y-labelling 
		(float (/ (- (or supplied-y-max y-max) (or
							supplied-y-min y-min)) 10))))))

(defmethod default-graph-axis ((type (eql :bar)) points supplied-x-min supplied-y-min 
						 supplied-x-max supplied-y-max y-labelling)
  (declare (ignore supplied-x-min supplied-x-max))
  (destructuring-bind 
      (rows columns) (array-dimensions points)
    (let* ((supplied-x-min 0)
	   (supplied-x-max (1+ rows))
	   (x-min supplied-x-min)
	   (y-min supplied-y-min)
	   (x-max supplied-x-max)
	   (y-max supplied-y-max))
      (unless (and x-min y-min x-max y-max)
	(destructuring-bind
	    (rows columns) (array-dimensions points)
	  (setq x-min (aref points 0 0) x-max x-min)
	  (setq y-min (aref points 0 1) y-max y-min)
	  (dotimes (i rows)
	    (let ((x (aref points i 0)))
	      (clim-utils::minf x-min x)
	      (clim-utils::maxf x-max x)
	      (dotimes (j (1- columns))
		(let ((y (aref points i (1+ j))))
		  (clim-utils::minf y-min y)
		  (clim-utils::maxf y-max y)))))))
      (values supplied-x-min
	      (or supplied-y-min y-min)
	      supplied-x-max 
	      (or supplied-y-max y-max)
	      (or y-labelling 
		  (float (/ (- (or supplied-y-max y-max) (or supplied-y-min y-min)) 10)))))))


;; Actual demo code.

(define-application-frame plot-demo ()
			  (
			   (y-labelling :initform 5)
			   (plot-data :initform (let ((x #2a((1960 5 11 14)
							     (1970 8 15 16)
							     (1980 14 18 15.5)
							     (1990 19 21 15.2)
							     (2000 24 22
								   15.4))))
						  (let ((n (make-array
							    (array-dimensions x))))
						    (destructuring-bind (rows columns)
							(array-dimensions x)
						      (dotimes (i rows)
							(dotimes (j columns)
							  (setf (aref n i j) (aref x i j))))
						      n))))
			   (graph-type :initform :plot)
			   (x-min :initform nil)
			   (y-min :initform nil)
			   (x-max :initform nil)
			   (y-max :initform nil)
			   (x-labels :initform (copy-list '("60" "70" "80" "90" "2000")))
			   (y-labels :initform  (copy-list '("Mexico City" "Tokyo" "New York")))
			   )
  (:command-table (plot-demo :inherit-from (plot-command-table accept-values-pane)))
  (:panes 
   (graph-window :application :display-function 'display-graph
		:incremental-redisplay t
		 :scroll-bars :both
		 :width :compute :height :compute)
   (data-window :application :display-function 'display-data
		:incremental-redisplay t
		:scroll-bars :both
		:width :compute :height :compute)
   (options :accept-values
	    :scroll-bars :both
	    :display-function `(accept-values-pane-displayer
				:resynchronize-every-pass t
				:displayer display-options)
	    :width :compute
	    :height :compute)
   (command :interactor :height '(5 :line)))
  (:pointer-documentation t)
  (:layouts
   (:default (vertically () graph-window options data-window command))))

(defmethod display-options ((frame plot-demo) stream &key &allow-other-keys)
  (with-slots (x-min y-min x-max y-max graph-type) frame

    (setf graph-type (accept '(member :plot :bar :pie)
			     :default graph-type 
			     :stream stream
			     :prompt "Graph type"))
    (terpri stream)
    (unless (eq graph-type :pie)
      (unless (eq graph-type :bar)
	(setf x-min (accept '(null-or-type number)
			    :default x-min
			    :stream stream
			    :prompt "Min X"))
	(terpri stream))
      (setf y-min (accept '(null-or-type number)
			  :default y-min
			  :stream stream
			  :prompt "Min Y"))
      (terpri stream)
      (unless (eq graph-type :bar)
	(setf x-max (accept '(null-or-type number)
			    :default x-max
			    :stream stream
			    :prompt "Max X"))
	(terpri stream))
      (setf y-max (accept '(null-or-type number)
			  :default y-max
			  :stream stream
			  :prompt "Max Y"))
      (terpri stream))))
    
(defmethod frame-standard-output ((fr plot-demo))
  (get-frame-pane fr 'command))

(define-presentation-type data-point ())
(define-presentation-type x-label ())
(define-presentation-type y-label ())

(defmethod display-data ((frame plot-demo) stream &key &allow-other-keys)
  (updating-output (stream)
      (with-slots (y-labels x-labels plot-data) frame
	(formatting-table (stream :x-spacing '(3 :character))
	    ;; Headers
	    (formatting-row (stream)
		(updating-output (stream :unique-id `(-1 ,-1)
					 :id-test #'equal
					 :cache-value nil
					 :cache-test #'equalp)

		    (formatting-cell (stream) stream)) ; Dummy corner

	      (updating-output (stream :unique-id `(-1 ,0)
				       :id-test #'equal
				       :cache-value nil
				       :cache-test #'equalp)
		  (formatting-cell (stream) stream )) ; Over the X values

	      (let ((i 0))
		(dolist (label y-labels)
		  (updating-output (stream :unique-id `(-1 ,(+ 2 i))
					   :id-test #'equal
					   :cache-value label
					   :cache-test #'equalp)
		      (formatting-cell (stream) 
			  (with-output-as-presentation (stream i 'y-label)
			    (with-text-style (stream '(nil :bold-italic :large))
			      (write-string label stream)))))
		  (incf i))))
	  (destructuring-bind (rows columns)
	      (array-dimensions plot-data)
	    (dotimes (i rows)
	      (let ((label (nth i x-labels)))
		(formatting-row (stream)
		    (updating-output (stream :unique-id `(,i -1)
					     :id-test #'equal
					     :cache-value label
					     :cache-test #'equalp)
			(formatting-cell (stream)
			    (with-output-as-presentation (stream i 'x-label)
			      (with-text-style (stream '(nil :bold-italic :large))
				(write-string label stream)))))
		  (dotimes (j columns)
		    (let ((n  (aref plot-data i j)))
		      (updating-output (stream :unique-id `(,i ,j)
					       :id-test #'equal
					       :cache-value n
					       :cache-test #'equal)
			  (formatting-cell (stream :align-x :center)
			      (with-output-as-presentation (stream (list i j) 'data-point)
				(with-output-as-presentation (stream n 'number)
				  (format stream "~2D" n)))))))))))))))

(define-plot-demo-command (com-edit-x-label :name t :menu t)
    ((i 'x-label :gesture :select))
  (with-application-frame (frame)
    (setf (nth i (slot-value frame 'x-labels))
      (accept 'string
	      :default (nth i (slot-value frame 'x-labels))))))

(define-plot-demo-command (com-edit-y-label :name t :menu t)
    ((i 'y-label :gesture :select))
  (with-application-frame (frame)
    (setf (nth i (slot-value frame 'y-labels))
      (accept 'string
	      :default (nth i (slot-value frame 'y-labels))))))

(define-plot-demo-command (com-edit-data-point :name t :menu t)
    ((point 'data-point :gesture :select))
  (with-application-frame (frame)
    (destructuring-bind (i j) point
      (setf (aref (slot-value frame 'plot-data) i j)
	(accept 'number
		:default (aref (slot-value frame 'plot-data) i j))))))

(defmethod display-graph ((frame plot-demo) stream &key &allow-other-keys)
  (updating-output (stream)
      (with-slots (y-labelling graph-type plot-data x-labels y-labels  x-min y-min x-max y-max) frame
	(plotting-data (stream :y-labelling y-labelling :x-labels
			       x-labels :y-labels y-labels
			       :x-min x-min :y-min y-min :x-max x-max
			       :y-max y-max
			       :type graph-type)
		       (plot-data plot-data)))))

(define-plot-demo-command com-describe-graph-line 
    ((line 'graph-line :gesture :select))
  (describe line))

(define-plot-demo-command com-describe-graph-point
    ((point 'graph-point :gesture :select))
  (describe point))


(define-plot-demo-command (com-describe-region :name t) 
    ((region 'graph-region))
  (describe region))

(define-plot-demo-command (com-redisplay :name t) 
    ()
  (window-clear (get-frame-pane *application-frame* 'graph-window))
  (window-clear (get-frame-pane *application-frame* 'data-window)))



(define-plot-demo-command (com-add-new-column :name t)
    ()
  (with-slots (plot-data y-labels) *application-frame*
    (destructuring-bind (rows columns) 
	(array-dimensions plot-data)
      (let ((new-data (make-array (list rows (1+ columns)))))
	(dotimes (i rows)
	  (dotimes (j columns) (setf (aref new-data i j) (aref plot-data i j)))
	  (setf (aref new-data i columns) (aref plot-data i (1- columns))))
	(setf plot-data new-data))
      (setf y-labels (append y-labels (last y-labels))))))

(define-plot-demo-command (com-add-new-row :name t)
    ()
  (with-slots (plot-data x-labels) *application-frame*
    (destructuring-bind (rows columns) 
	(array-dimensions plot-data)
      (let ((new-data (make-array (list (1+ rows) columns))))
	(dotimes (i rows)
	  (dotimes (j columns) (setf (aref new-data i j) (aref plot-data i j))))
	(dotimes (j columns) (setf (aref new-data rows j) (aref plot-data (1- rows) j)))
	(setf plot-data new-data))
      (setf x-labels (append x-labels (last x-labels))))))


(define-plot-demo-command (com-delete-line :name t)
    ((line 'graph-line :gesture :delete))
  (with-slots (plot-data y-labels) *application-frame*
    (destructuring-bind (rows columns) 
	(array-dimensions plot-data)
      (let ((new-data (make-array (list rows (1- columns)))))
	(dotimes (i rows)
	  (dotimes (j (1- columns) )
	    (setf (aref new-data i j) 
	      (aref plot-data i (if (>= j line) (1+ j) j)))))
	(setf plot-data new-data))
      (setf y-labels (append (subseq y-labels 0 (1- line))
			     (subseq y-labels line))))))

(define-plot-demo-command (com-random-update :name t)
    ()
  (with-application-frame (frame)
    (with-slots (plot-data) frame
      (dotimes (i 10)
	(destructuring-bind (rows columns) 
	    (array-dimensions plot-data)
	  (let ((i (random rows))
		(j (+ 1 (random (1- columns)))))
	    (setf (aref plot-data i j)
	      (max (+ (aref plot-data i j) (- (random 10) 5))
		   0))))
	(redisplay-frame-pane frame (get-frame-pane frame 'graph-window))
	(silica:medium-force-output (sheet-medium  (get-frame-pane frame 'graph-window)))))))
	

;;; 

(clim-demo::define-demo "Plotting demo" (do-plot-demo))

(defvar *plot-demo* nil)

(defun do-plot-demo ()
  (run-frame-top-level 
   (or *plot-demo*
       (setq *plot-demo* (make-application-frame 'plot-demo)))))
