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

;;; Clear the vbuffer, then run 'ls -l'
(lto-phase1::clear-buffer lto-phase1::*vbuffer*)
(lto-phase1:send-input "ls -l")
(sleep 1)

;;; Inspect the vbuffer
(format t "~&--- VTE Inspection ---~%")
(format t "Line 2: ~S~%" (lto-phase1::get-line-text lto-phase1::*vbuffer* 2))
(format t "Found 'src' at: ~A~%" (lto-phase1::find-string-in-buffer lto-phase1::*vbuffer* "src"))
(format t "--------------------~%")

;;; Send the 'exit' command to terminate the shell
(lto-phase1:send-input "exit")
(sleep 1)
