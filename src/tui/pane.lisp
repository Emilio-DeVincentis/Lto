;;; src/tui/pane.lisp

(in-package #:lto-tui)

(defclass pane ()
  ((id :initarg :id :reader pane-id)
   (title :initarg :title :accessor pane-title)
   (vbuffer :initarg :vbuffer :reader pane-vbuffer)
   (window :initarg :window :reader pane-window)
   (lock :initform (bt:make-lock) :reader pane-lock)
   (dirty-p :initform t :accessor pane-dirty-p)
   (pty-master-fd :initarg :pty-master-fd :reader pane-pty-master-fd)
   (child-pid :initarg :child-pid :reader pane-child-pid))
  (:documentation "Represents a single pane in the TUI, containing a virtual buffer and an ncurses window."))

(defun make-pane (id title vbuffer window pty-master-fd child-pid)
  "Create a new pane instance."
  (make-instance 'pane :id id
                       :title title
                       :vbuffer vbuffer
                       :window window
                       :pty-master-fd pty-master-fd
                       :child-pid child-pid))
