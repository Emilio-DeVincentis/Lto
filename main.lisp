;;; Load Quicklisp setup
(load "~/quicklisp/setup.lisp")

;;; Add the current directory to ASDF's source registry
(push *default-pathname-defaults* asdf:*central-registry*)

;;; Load the system
(ql:quickload :lto-phase1)

;;; Spawn the PTY and start the reader thread
(let ((master-fd (lto-phase1:spawn-pty-shell)))
  (lto-phase1::start-reader-thread master-fd))

;;; Wait for the shell to initialize
(sleep 2)

;;; Send the 'ls' command and wait for output
(lto-phase1:send-input "ls")
(sleep 1)

;;; Send the 'exit' command to terminate the shell
(lto-phase1:send-input "exit")
(sleep 1)
