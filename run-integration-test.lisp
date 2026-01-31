;;; run-integration-test.lisp

(load "~/quicklisp/setup.lisp")

;; Load the project systems
(push *default-pathname-defaults* asdf:*central-registry*)
(asdf:load-system :lto-phase1)
(asdf:load-system :lto-tui)

(defun main ()
  (let ((app-pid nil))
    (unwind-protect
         (progn
           ;; 1. Spawn the application in a PTY
           (format t "Spawning application process...~%")
           (setf app-pid
                 (second
                  (multiple-value-list
                   (lto-phase1:spawn-process-in-pty
                    ;; Use the current running lisp executable
                    (first (uiop:raw-command-line-arguments))
                    ;; Pass arguments to start the TUI
                    '("--eval" "(lto-tui:start-tui)")
                    ;; Enable test mode via environment variable
                    '(("LTO_TEST_MODE" . "true"))))))

           (unless (and app-pid (> app-pid 0))
             (error "Failed to spawn application process."))

           (format t "Application started with PID: ~a~%" app-pid)

           ;; 2. Wait for the application to initialize
           (format t "Waiting for application to initialize...~%")
           (sleep 2)

           ;; 3. Send RPC ping and check response
           (format t "Sending RPC ping...~%")
           (let ((response (lto-phase1:rpc-request :ping)))
             (format t "Received response: ~s~%" response)
             (if (equal response '(:pong))
                 (progn
                   (format t "SUCCESS: Received correct pong response.~%")
                   t) ;; Test passed
                 (progn
                   (format t "FAILURE: Incorrect response received.~%")
                   nil)))) ;; Test failed
      ;; 4. Cleanup: ensure the process is terminated
      (when app-pid
        (format t "Cleaning up process with PID: ~a~%" app-pid)
        (lto-phase1:kill-process app-pid)
        (sleep 0.5) ; Give OS time to reap the process
        (format t "Cleanup complete.~%")))
    ))

;; Run the test and exit with the appropriate status code
(if (main)
    (uiop:quit 0)
    (uiop:quit 1))
