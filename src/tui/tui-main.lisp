;;; src/tui/tui-main.lisp

(in-package #:lto-tui)

(defvar *layout-root* nil "The root of the layout tree.")
(defvar *active-pane* nil "The currently focused pane.")
(defvar *command-mode-p* nil "Is the TUI currently in command mode (post-prefix)?")

(defun start-pane-reader-thread (pane)
  "Starts a thread that reads from the pane's PTY and updates its vbuffer."
  (let ((fd (pane-pty-master-fd pane))
        (vbuffer (pane-vbuffer pane))
        (lock (pane-lock pane)))
    (bt:make-thread
     (lambda ()
       (cffi:with-foreign-object (buf :char 1024)
         (loop
           (let ((bytes-read (lto-phase1::posix-read fd buf 1024)))
             (if (> bytes-read 0)
                 (let ((output (cffi:foreign-string-to-lisp buf :count bytes-read)))
                   (bt:with-lock-held (lock)
                     (process-output-stream vbuffer output)
                     (setf (pane-dirty-p pane) t)))
                 (return))))))
     :name (format nil "pty-reader-for-pane-~A" (pane-id pane)))))

(defun render-layout (node)
  "Recursively renders the layout tree."
  (typecase node
    (pane-node
     (let ((pane (pane-node-pane node)))
       (render-pane pane :is-active? (eq pane *active-pane*))))
    (split-node
     (render-layout (split-node-child-a node))
     (render-layout (split-node-child-b node)))))

(defun handle-command-input (ch)
  "Handles input when in command mode."
  (case ch
    (#\% (split-active-pane :vertical))
    (#\" (split-active-pane :horizontal))
    (#\x (close-active-pane))
    ((charms/ll:key_up) (move-focus :up))
    ((charms/ll:key_down) (move-focus :down))
    ((charms/ll:key_left) (move-focus :left))
    ((charms/ll:key_right) (move-focus :right))
    (otherwise
     ;; Unknown command, just ignore for now
     ))
  (setf *command-mode-p* nil))

(defun main-loop ()
  "The main rendering and input loop for the TUI."
  (charms:with-curses ()
    (charms:disable-echoing)
    (charms:enable-raw-input)
    (charms:enable-extra-keys charms:*standard-window*)
    (charms/ll:curs-set 0)

    (when (charms/ll:has-colors)
      (charms/ll:start-color)
      (charms/ll:init-pair 1 charms/ll:color_blue charms/ll:color_black)
      (charms/ll:init-pair 2 charms/ll:color_green charms/ll:color_black))

    (multiple-value-bind (cols rows) (charms:window-dimensions charms:*standard-window*)
      (multiple-value-bind (fd pid) (spawn-pty-shell)
        (let* ((vbuffer (make-vbuffer (- rows 2) (- cols 2)))
               (pane (make-pane 1 "Pane 1" vbuffer charms:*standard-window* fd pid)))
          (setf *layout-root* (make-pane-node pane))
          (setf *active-pane* pane)
          (start-pane-reader-thread pane))))

    (loop
      (let ((ch (charms:get-char charms:*standard-window* :ignore-error t)))
        (cond
          ((eql ch #\q) (return))
          ((eql ch charms/ll:key_resize)
           (multiple-value-bind (cols rows) (charms:window-dimensions charms:*standard-window*)
             (recalculate-layout *layout-root* 0 0 rows cols)
             (notify-panes-of-resize *layout-root*)))
          (*command-mode-p*
           (handle-command-input ch)
           (setf *command-mode-p* nil))
          ((eql ch (code-char 2)) ; Ctrl-b
           (setf *command-mode-p* t))
          ((characterp ch)
           (when *active-pane*
             (send-input (pane-pty-master-fd *active-pane*) (string ch)))))

        (unless *layout-root* (return)) ; Exit if last pane was closed

        (render-layout *layout-root*))
      (sleep 0.01))))

(defun start-tui ()
  (main-loop))
