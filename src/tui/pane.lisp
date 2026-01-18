;;; src/tui/pane.lisp

(in-package #:lto-tui)

(defclass pane ()
  ((id :initarg :id :reader pane-id)
   (title :initarg :title :accessor pane-title)
   (command :initarg :command :accessor pane-command)
   (vbuffer :initarg :vbuffer :reader pane-vbuffer)
   (window :initarg :window :reader pane-window)
   (lock :initform (make-lock) :reader pane-lock)
   (dirty-p :initform t :accessor pane-dirty-p)
   (pty-master-fd :initarg :pty-master-fd :accessor pane-pty-master-fd)
   (child-pid :initarg :child-pid :accessor pane-child-pid)
   (watchers :initform '() :accessor pane-watchers))
  (:documentation "Represents a single pane in the TUI, containing a virtual buffer and an ncurses window."))

(defun make-pane (id title command vbuffer window pty-master-fd child-pid)
  "Create a new pane instance."
  (make-instance 'pane :id id
                       :title title
                       :command command
                       :vbuffer vbuffer
                       :window window
                       :pty-master-fd pty-master-fd
                       :child-pid child-pid))
