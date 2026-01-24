;;; src/tui/tui-main.lisp

(in-package #:lto-tui)

(defvar *layout-root* nil "The root of the layout tree.")
(defvar *active-pane* nil "The currently focused pane.")
(defvar *command-mode-p* nil "Is the TUI currently in command mode (post-prefix)?")

;;; --- NEW: Threading and Event Handling ---

(defvar *event-queue* '() "A list serving as a thread-safe event queue.")
(defvar *event-queue-lock* (make-lock "event-queue-lock") "Lock for the event queue.")
(defvar *io-thread* nil "The thread dedicated to asynchronous I/O.")
(defvar *panes-by-fd* (make-hash-table) "Maps PTY file descriptors to pane objects.")
(defvar *panes-by-fd-lock* (make-lock "panes-by-fd-lock"))
(defvar *running* t "A flag to signal threads to exit.")

(defun push-event (event)
  "Safely adds an event to the event queue."
  (with-lock-held (*event-queue-lock*)
    (setf *event-queue* (append *event-queue* (list event)))))

(defun pop-event ()
  "Safely pops an event from the event queue. Returns NIL if empty."
  (with-lock-held (*event-queue-lock*)
    (pop *event-queue*)))

(defun register-pane-fd (pane)
  (with-lock-held (*panes-by-fd-lock*)
    (setf (gethash (pane-pty-master-fd pane) *panes-by-fd*) pane)))

(defun get-pane-by-fd (fd)
  (with-lock-held (*panes-by-fd-lock*)
    (gethash fd *panes-by-fd*)))

(defun io-loop ()
  "The main loop for the I/O thread. Monitors all FDs using iolib."
  (with-event-base (event-base)
    (loop while *running*
          do (progn
               (let ((fds-to-watch '()))
                 (with-lock-held (*panes-by-fd-lock*)
                   (maphash (lambda (fd pane) (declare (ignore pane)) (push fd fds-to-watch)) *panes-by-fd*))

                 (dolist (fd fds-to-watch)
                   (set-io-handler event-base fd :read
                                         (lambda (fd event error)
                                           (declare (ignore event error))
                                           (cffi:with-foreign-object (buf :char 4096)
                                             (let ((bytes-read (lto-phase1::posix-read fd buf 4096)))
                                               (if (> bytes-read 0)
                                                   (let* ((output (cffi:foreign-string-to-lisp buf :count bytes-read))
                                                          (pane (get-pane-by-fd fd)))
                                                     (when pane
                                                       (push-event `(:pty-output ,pane ,output))))
                                                   (progn
                                                     (remove-fd-handlers event-base fd)
                                                     (let ((pane (get-pane-by-fd fd)))
                                                       (when pane
                                                         (push-event `(:pane-closed ,pane))))))))))))
               (event-dispatch event-base :timeout 1)))))

(defun run-watchers (pane output)
  "Runs all applicable watchers against the given output for a pane."
  (let ((all-watchers (with-lock-held (*watchers-lock*)
                        (append *global-watchers* (pane-watchers pane)))))
    (dolist (watcher all-watchers)
      (do-scans (match-start match-end reg-starts reg-ends
                         (watcher-compiled-regex watcher) output)
        (let ((matches (map 'list
                            (lambda (start end) (subseq output start end))
                            reg-starts reg-ends)))
          (funcall (watcher-callback watcher) pane matches))))))

(defun process-event-queue ()
  "Process all pending events from the I/O thread."
  (loop for event = (pop-event)
        while event
        do (let ((type (first event))
                 (pane (second event)))
             (case type
               (:pty-output
                (let ((output (third event)))
                  (run-watchers pane output)
                  (with-lock-held ((pane-lock pane))
                    (process-output-stream (pane-vbuffer pane) output)
                    (setf (pane-dirty-p pane) t))))
               (:pane-closed
                (close-pane pane))))))

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
    (#\% (let* ((command "kak")
                (new-pane (split-active-pane :vertical command)))
           (when new-pane
             (let* ((pane-id (pane-id new-pane))
                    (session (format nil "LTO-~A" pane-id))
                    (args (list "-s" session)))
               (multiple-value-bind (fd pid)
                   (spawn-process-in-pty command args `(("LTO_PANE_ID" . ,(princ-to-string pane-id))
                                                                    ("KAKOUNE_SESSION" . ,session)))
                 (setf (pane-pty-master-fd new-pane) fd
                       (pane-child-pid new-pane) pid)
                 (register-pane-fd new-pane)
                 (notify-panes-of-resize *layout-root*))))))
    (#\" (let ((new-pane (split-active-pane :horizontal "/bin/sh")))
           (when new-pane
             (multiple-value-bind (fd pid)
                 (spawn-process-in-pty "/bin/sh" '())
               (setf (pane-pty-master-fd new-pane) fd
                     (pane-child-pid new-pane) pid)
               (register-pane-fd new-pane)
               (notify-panes-of-resize *layout-root*)))))
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
    (charms:enable-non-blocking-mode charms:*standard-window*)

    (when (charms/ll:has-colors)
      (charms/ll:start-color)
      (charms/ll:init-pair 1 charms/ll:color_blue charms/ll:color_black)
      (charms/ll:init-pair 2 charms/ll:color_green charms/ll:color_black))

    (when (uiop:getenv "LTO_TEST_MODE")
      (start-rpc-server))

    ;; Start the I/O thread
    (setf *running* t)
    (setf *io-thread* (make-thread #'io-loop :name "io-loop"))

    ;; Create the first pane
    (multiple-value-bind (cols rows) (charms:window-dimensions charms:*standard-window*)
      (let ((command "/bin/sh"))
        (multiple-value-bind (fd pid)
            (spawn-process-in-pty command '())
          (let* ((vbuffer (make-vbuffer (- rows 2) (- cols 2)))
                 (pane (make-pane 1 "Pane 1" command vbuffer charms:*standard-window* fd pid)))
            (setf *layout-root* (make-pane-node pane))
            (setf *active-pane* pane)
            (register-pane-fd pane))))))

    (loop
      (process-event-queue)

      (let ((ch (charms:get-char charms:*standard-window* :ignore-error t :blocking nil)))
        (when ch
         (cond
           ((eql ch #\q) (return))
           ((eql ch charms/ll:key_resize)
            (multiple-value-bind (cols rows) (charms:window-dimensions charms:*standard-window*)
              (recalculate-layout *layout-root* 0 0 rows cols)
              (notify-panes-of-resize *layout-root*)))
           (*command-mode-p*
            (handle-command-input ch)
            (setf *command-mode-p* nil))
           ((eql ch (code-char 2))
            (setf *command-mode-p* t))
           ((characterp ch)
            (when *active-pane*
              (send-input (pane-pty-master-fd *active-pane*) (string ch))))))

      (unless *layout-root* (return))

      (render-layout *layout-root*)
      (sleep 0.01))

    (setf *running* nil)
    (join-thread *io-thread*)))

(defun start-tui ()
  (main-loop))
