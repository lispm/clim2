;;; -*- Mode: Lisp; Syntax: ANSI-Common-Lisp; Package: CLIM-DEMO; Base: 10; Lowercase: Yes -*-

;; $fiHeader: listener.lisp,v 1.4 91/03/26 12:37:34 cer Exp $

(in-package :clim-demo)

"Copyright (c) 1990, 1991 Symbolics, Inc.  All rights reserved."

(define-application-frame lisp-listener
			  ()
    ()
  #-Silica
  (:panes ((listener :application
		     :initial-cursor-visibility :off)
	   (documentation :pointer-documentation)))
  #+Silica
  (:pane (scrolling ()
           (realize-pane 'clim-internals::interactor-pane)))
  (:command-table (lisp-listener :inherit-from (user-command-table)))
  (:command-definer t)
  (:top-level (lisp-listener-top-level)))

(defmethod frame-maintain-presentation-histories ((frame lisp-listener)) t)

(defmacro condition-restart-loop ((conditions description . args) &body body)
  (let ((tag (clim-utils:gensymbol 'restart)))
    `(tagbody ,tag
       (restart-case
	   (progn ,@body)
	 (nil ()
	   #|| :test (lambda (condition)
		       (some #'(lambda (x) (typep condition x)) ',conditions)) ||#
	   :report (lambda (stream)
		     (format stream ,description ,@args))))
       (go ,tag))))

(defvar *listener-depth* -1)

(defun lisp-listener-top-level (frame)
  "Run a simple Lisp listener using the window provided."
  #+Silica (enable-frame frame)
  (let* ((window (frame-query-io frame))
	 (command-table (frame-command-table frame))
	 (presentation-type `(command-or-form :command-table ,command-table)))
    (with-input-focus (window)
      (terpri window)
      (let* ((*standard-input* window)
	     (*standard-output* window)
	     #+Minima (*error-output* window)
	     (*query-io* window)
	     #+Minima (*debug-io* window)
	     (*package* *package*)
	     (*listener-depth* (1+ *listener-depth*))
	     (*** nil) (** nil) (* nil)
	     (/// nil) (// nil) (/ nil)
	     (+++ nil) (++ nil) (+ nil)
	     (- nil))
	(with-command-table-keystrokes (keystrokes command-table)
	  (condition-restart-loop (#+Genera (sys:error sys:abort)
				   #-Genera (error)
				   "Restart CLIM lisp listener")
	    (lisp-listener-command-reader
	      frame command-table presentation-type
	      :keystrokes keystrokes
	      :listener-depth *listener-depth*
	      :prompt (concatenate 'string 
		        (make-string (1+ *listener-depth*) :initial-element #\=) "> "))))))))

(defun lisp-listener-command-reader (frame command-table presentation-type 
				     &key keystrokes listener-depth (prompt "=> "))
  (catch-abort-gestures ("Return to ~A command level ~D"
			 (frame-pretty-name frame) listener-depth)
    ;; Eat any abort characters that might be hanging around.
    ;; We need to do this because COMMAND-OR-FORM is wierd.
    (let* ((abort-chars *abort-gestures*)
	   (*abort-gestures* nil))
      (when (member (stream-read-gesture *standard-input* :timeout 0 :peek-p t) abort-chars)
	(stream-read-gesture *standard-input* :timeout 0)))
    (fresh-line *standard-input*)
    (multiple-value-bind (command-or-form type numeric-arg)
	(block keystroke
	  (handler-bind ((accelerator-gesture
			   #'(lambda (c)
			       ;; The COMMAND-OR-FORM type is peeking for the
			       ;; first character, looking for a ":", so we
			       ;; have to manually discard the accelerator
			       (stream-read-gesture *standard-input* :timeout 0)
			       (return-from keystroke
				 (values
				   (accelerator-gesture-event c)
				   :keystroke
				   (accelerator-gesture-numeric-argument c))))))
	    (let ((*accelerator-gestures* keystrokes))
	      (accept presentation-type
		      :stream *standard-input*
		      :prompt prompt :prompt-mode :raw
		      :additional-activation-gestures '(#+Genera #\End)))))
      (when (eql type :keystroke)
	(let ((command (lookup-keystroke-command-item command-or-form command-table 
						      :numeric-argument numeric-arg)))
	  (unless (characterp command)
	    (when (partial-command-p command)
	      (setq command (funcall *partial-command-parser*
				     command command-table *standard-input* nil
				     :for-accelerator t)))
	    (setq command-or-form command
		  type 'command))))
      (cond ((eql type ':keystroke)
	     (beep))
	    ((eql (presentation-type-name type) 'command)
	     (terpri)
	     (let ((*debugger-hook* #'listener-debugger-hook))
	       (apply (command-name command-or-form)
		      (command-arguments command-or-form)))
	     (terpri))
	    (t
	     (terpri)
	     (let ((values (multiple-value-list
			     (let ((*debugger-hook* #'listener-debugger-hook))
			       (eval command-or-form)))))
	       (fresh-line)
	       (dolist (value values)
		 (present value 'expression :single-box :highlighting)
		 (terpri))
	       (setq - command-or-form)
	       (shiftf +++ ++ + -)
	       (when values
		 ;; Don't change this stuff if no returned values
		 (shiftf /// // / values)
		 (shiftf *** ** * (first values)))))))))

(defun listener-debugger-hook (condition hook)
  (declare (ignore hook))
  (let ((*debug-io* (frame-query-io *application-frame*))
	(*error-output* (frame-query-io *application-frame*)))
    (describe-error condition *error-output*)
    (lisp-listener-top-level *application-frame*)))

(define-presentation-type restart-name ())

(define-presentation-method presentation-typep (object (type restart-name))
  (typep object 'restart))

(define-presentation-method present (object (type restart-name) stream (view textual-view)
				     &key)
  (prin1 (restart-name object) stream))

(define-presentation-translator invoke-restart
    (restart-name form lisp-listener
     :documentation ((object stream)
		     (format stream "Invoke the restart ~S" (restart-name object)))
     :pointer-documentation "Invoke this restart"
     :gesture :select)
    (object)
  `(invoke-restart ',object))

(defun describe-error (condition stream)
  (with-output-as-presentation (stream condition 'form
				:single-box t)
    (format stream "~2&Error: ~A" condition))
  (let ((process (clim-sys:current-process)))
    (when process
      (format stream "~&In process ~A." process)))
  (let ((restarts (compute-restarts condition)))
    (when restarts
      (let ((actions '(invoke-restart)))
	(dolist (restart (reverse restarts))
	  (let ((action (member (restart-name restart)
				'(abort continue muffle-warning store-value use-value))))
	    (when action
	      (pushnew (first action) actions))))
	(format stream "~&Use~?to resume~:[~; or abort~] execution:"
		       "~#[~; ~S~; ~S or ~S~:;~@{~#[~; or~] ~S~^,~}~] "
		       actions (member 'abort actions)))
      (fresh-line stream)
      (let ((i 0))
	(formatting-table (stream :x-spacing '(2 :character))
	  (dolist (restart restarts)
	    (with-output-as-presentation (stream restart 'restart-name
					  :single-box t)
	      (formatting-row (stream)
		(formatting-cell (stream)
		  (format stream "~D" i))
		(formatting-cell (stream)
		  (format stream "~S" (restart-name restart)))
		(formatting-cell (stream)
		  (format stream "~A" restart))))
	    (incf i))))))
  (force-output stream))


;;; Lisp-y stuff

(defun quotify-object-if-necessary (object)
  (if (or (consp object)
	  (and (symbolp object)
	       (not (keywordp object))
	       (not (eq object nil))
	       (not (eq object t))))
      (list 'quote object)
    object))

(define-presentation-translator describe-lisp-object
    (expression form lisp-listener
     :documentation
       ((object stream)
	(let ((*print-length* 3)
	      (*print-level* 3)
	      (*print-pretty* nil))
	  (present `(describe ,(quotify-object-if-necessary object)) 'expression
		   :stream stream :view +pointer-documentation-view+)))
     :gesture :describe)
    (object)
  `(describe ,(quotify-object-if-necessary object)))

(define-presentation-translator expression-identity
    (expression nil lisp-listener
     :tester
       ((object context-type)
	(if (and (eq (presentation-type-name context-type) 'sequence)
		 (or (vectorp object)
		     (listp object)))
	    (clim-utils:with-stack-list
	        (type 'sequence (reasonable-presentation-type (elt object 0)))
	      (presentation-subtypep type context-type))
	    (presentation-subtypep (reasonable-presentation-type object) context-type)))
     :tester-definitive t
     :documentation ((object stream)
		     (let ((*print-length* 3)
			   (*print-level* 3)
			   (*print-pretty* nil))
		       (present object 'expression 
				:stream stream :view +pointer-documentation-view+)))
     :gesture :select)
    (object)
  object)

(defun reasonable-presentation-type (object)
  (let* ((class (class-of object))
	 (class-name (class-name class)))
    (when (presentation-type-specifier-p class-name)
      ;; Don't compute precedence list if we don't need it
      (return-from reasonable-presentation-type class-name))
    (dolist (class (class-precedence-list class))
      (when (presentation-type-specifier-p (class-name class))
	(return-from reasonable-presentation-type (class-name class))))
    nil))

(define-lisp-listener-command (com-edit-function :name t)
    ((function 'expression :prompt "function name"))
  (ed function))

(define-presentation-to-command-translator edit-function
    (expression com-edit-function lisp-listener
     :tester ((object)
	      (functionp object))
     :gesture :edit)
    (object)
  (list object))


;;; Useful commands

(define-lisp-listener-command (com-clear-output-history :name t)
    ()
  (window-clear (frame-standard-output *application-frame*)))

#+Genera
(add-keystroke-to-command-table 'lisp-listener #\c-m-L :command 'com-clear-output-history)

#-Minima (progn

(define-lisp-listener-command (com-copy-output-history :name t)
    ((pathname 'pathname :prompt "file"))
  (with-open-file (stream pathname :direction :output)
    (copy-textual-output-history *standard-output* stream)))

(define-lisp-listener-command (com-show-homedir :name t)
    ()
  (show-directory (make-pathname :defaults (user-homedir-pathname)
				 :name :wild
				 :type :wild
				 :version :newest)))

(define-lisp-listener-command (com-show-directory :name t)
    ((directory '((pathname) :default-type :wild) :prompt "file"))
  (show-directory directory))

(defun show-directory (directory-pathname)
  (let ((stream *standard-output*)
	(pathnames #+Genera (rest (fs:directory-list directory-pathname))
		   #-Genera (directory directory-pathname)))
    (flet ((pathname-lessp (p1 p2)
	     (let ((name1 (pathname-name p1))
		   (name2 (pathname-name p2)))
	       (or (string-lessp name1 name2)
		   (and (string-equal name1 name2)
			(let ((type1 (pathname-type p1))
			      (type2 (pathname-type p2)))
			  (and type1 type2 (string-lessp type1 type2))))))))
      (setq pathnames (sort pathnames #'pathname-lessp 
			    :key #+Genera #'first #-Genera #'identity)))
    (fresh-line stream)
    (format stream "~A" (namestring directory-pathname))
    (fresh-line stream)
    (formatting-table (stream :x-spacing "   ")
      (dolist (pathname pathnames)
	(let* (#-Genera (file-stream (open pathname :direction :input))
	       (size #+Genera (getf (rest pathname) :length-in-bytes)
		     #-Genera (file-length file-stream))
	       (creation-date #+Genera (getf (rest pathname) :modification-date)
			      #-Genera (file-write-date file-stream))
	       (author #+Genera (getf (rest pathname) :author)
		       #-Genera (file-author file-stream))
	       #+Genera (pathname (first pathname)))
	(with-output-as-presentation (stream pathname 'pathname
				      :single-box t)
	  (formatting-row (stream)
	    (formatting-cell (stream)
	      (format stream "  ~A" (file-namestring pathname)))
	    (formatting-cell (stream :align-x :right)
	      (format stream "~D" size))
	    (formatting-cell (stream :align-x :right)
	      (when creation-date
		(multiple-value-bind (secs minutes hours day month year)
		    (decode-universal-time creation-date)
		  (format stream "~D/~2,'0D/~D ~2,'0D:~2,'0D:~2,'0D"
		    month day year hours minutes secs))))
	    (formatting-cell (stream)
	      (write-string author stream)))))))))

(define-lisp-listener-command (com-show-file :name t)
    ((pathname 'pathname :gesture :select :prompt "file"))
  (show-file pathname *standard-output*))

;;; I can't believe CL doesn't have this
(defun show-file (pathname stream)
  (with-temporary-string (line-buffer :length 100)
    (with-open-file (file pathname :if-does-not-exist nil)
      (when file
	(loop
	  (let ((ch (read-char file nil 'eof)))
	    (case ch
	      (eof
		(return-from show-file))
	      ((#\Return #\Newline)
	       (write-string line-buffer stream)
	       (write-char #\Newline stream)
	       (setf (fill-pointer line-buffer) 0))
	      (otherwise
		(vector-push-extend ch line-buffer)))))))))

(define-lisp-listener-command (com-edit-file :name t)
    ((pathname 'pathname :gesture :edit :prompt "file"))
  (ed pathname))

(define-lisp-listener-command (com-delete-file :name t)
    ((pathname 'pathname :prompt "file"))
  (delete-file pathname))

(define-presentation-to-command-translator delete-file
    (pathname com-delete-file lisp-listener
     :gesture nil)
    (object)
  (list object))

#+Genera
(define-lisp-listener-command (com-expunge-directory :name t)
    ((directory 'pathname :prompt "directory"))
  (fs:expunge-directory directory))

;;--- We can do better than this
(define-lisp-listener-command (com-copy-file :name t)
    ((from-file 'pathname :prompt "from file")
     (to-file 'pathname :default from-file :prompt "to file"))
  (write-string "Would copy ")
  (present from-file 'pathname)
  (write-string " to ")
  (present to-file 'pathname)
  (write-string "."))

(define-lisp-listener-command (com-compile-file :name t)
    ((pathname 'pathname :prompt "file"))
  (compile-file pathname))

(define-presentation-to-command-translator compile-file
    (pathname com-compile-file lisp-listener
     :gesture nil)
    (object)
  (list object))

(define-lisp-listener-command (com-load-file :name t)
    ((pathname 'pathname :prompt "file"))
  (load pathname))

(define-presentation-to-command-translator load-file
    (pathname com-load-file lisp-listener
     :gesture nil)
    (object)
  (list object))

)

(define-lisp-listener-command (com-quit :name t)
    ()
  (frame-exit *application-frame*))


;;; Just for demonstration...

(define-presentation-type printer ())

(defparameter *printer-names*
	      '(("The Next Thing" tnt)
		("Asahi Shimbun" asahi)
		("Santa Cruz Comic News" comic-news)
		("Le Figaro" figaro)
		("LautScribner" lautscribner)))
		
(define-presentation-method accept ((type printer) stream (view textual-view) &key)
  (completing-from-suggestions (stream)
    (dolist (printer *printer-names*)
      (suggest (first printer) (second printer)))))

(define-presentation-method present (printer (type printer) stream (view textual-view)
				     &key acceptably)
  (let ((name (or (first (find printer *printer-names* :key #'second))
		  (string printer))))
    (write-token name stream :acceptably acceptably)))

(define-presentation-method presentation-typep (object (type printer))
  (symbolp object))

#-Minima
(define-lisp-listener-command (com-hardcopy-file :name t)
    ((file 'pathname :gesture :describe)
     (printer 'printer :gesture :select)
     &key
     (orientation '(member normal sideways) :default 'normal
      :documentation "Orientation of the printed result")
     (query 'boolean :default nil :mentioned-default t
      :documentation "Ask whether the file should be printed")
     (reflect 'boolean :when (and file (equal (pathname-type file) "SPREADSHEET"))
      :default nil :mentioned-default t
      :documentation "Reflect the spreadsheet before printing it"))
  (format t "Would hardcopy ")
  (present file 'pathname)
  (format t " on ")
  (present printer 'printer)
  (format t " in ~A orientation." orientation)
  (when query
    (format t "~%With querying."))
  (when reflect
    (format t "~%Reflected.")))

;;--- Just for demonstration...
(define-lisp-listener-command (com-show-some-commands :name t)
    ()
  (let ((ptype `(command :command-table user-command-table)))
    (formatting-table ()
      #-Minima
      (formatting-row ()
	(formatting-cell ()
	  (present `(com-show-file ,(merge-pathnames "foo" (user-homedir-pathname)))
		   ptype)))
      #-Minima
      (formatting-row ()
	(formatting-cell ()
	  (present `(com-show-directory ,(merge-pathnames "*" (user-homedir-pathname)))
		   ptype)))
      #-Minima
      (formatting-row ()
	(formatting-cell ()
	  (present `(com-copy-file ,(merge-pathnames "source" (user-homedir-pathname))
				   ,(merge-pathnames "dest" (user-homedir-pathname)))
		   ptype)))
      #-Minima
      (formatting-row ()
	(formatting-cell ()
	  (present `(com-hardcopy-file ,(merge-pathnames "quux" (user-homedir-pathname))
				       asahi)
		   ptype)))
      (formatting-row ()
	(formatting-cell ()
	  (present '(com-quit) ptype))))))


(defvar *listeners* nil)

(defun do-lisp-listener (&key reinit root)
  (let* ((entry (assoc root *listeners*))
	 (ll (cdr entry)))
    (when (or (null ll) reinit)
      (multiple-value-bind (left top right bottom)
	  (size-demo-frame root 50 50 500 500)
	(setq ll (make-application-frame 'lisp-listener
					 :parent root
					 :left left :top top
					 :right right :bottom bottom)))
      (if entry
	  (setf (cdr entry) ll)
	  (push (cons root ll) *listeners*)))
    (let ((window (frame-query-io ll)))
      (clear-input window))
    (run-frame-top-level ll)))

(define-demo "Lisp Listener" (do-lisp-listener :root *demo-root*))

#+Genera
(define-genera-application lisp-listener :pretty-name "CLIM Lisp Listener" :select-key #\�)