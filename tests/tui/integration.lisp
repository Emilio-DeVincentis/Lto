(in-package #:lto-tui-tests)

(def-suite integration-suite :description "TUI integration tests")
(in-suite integration-suite)

(test test-tui-startup-and-rpc-connection
  "Tests if the TUI application starts, enables RPC, and responds to a ping."
  (let ((app-pid nil)
        (master-fd nil)
        (test-passed nil))
    (unwind-protect
         (progn
           ;; Spawn the application in a PTY
           ;; NOTE: We're spawning the current Lisp image itself as a subprocess.
           ;; We pass command-line arguments to make it execute our test entry point.
           (multiple-value-bind (fd pid)
               (lto-phase1::spawn-process-in-raw-pty
                (first (uiop:raw-command-line-arguments))
                '("--eval" "(lto-tui:start-tui)")
                '(("LTO_TEST_MODE" . "true")))
             (setf master-fd fd)
             (setf app-pid pid))

           (is-true app-pid "The application process should have a PID.")

           ;; Give the app a moment to start the RPC server
           (sleep 2)

           ;; Attempt to connect and ping
           (let ((response (lto-phase1::rpc-request :ping)))
             (is (equal '(:pong) response) "RPC ping should return :pong.")
             (when (equal '(:pong) response)
               (setf test-passed t))))
      ;; Cleanup: ensure the process is terminated
      (when app-pid
        (lto-phase1::kill-process app-pid)
        ;; Short wait to allow the OS to clean up
        (sleep 0.5)
        (let ((status (multiple-value-list (uiop:wait-process app-pid :timeout 1))))
          (is-true (or (not (car status)) ; Process already gone
                       (eq :terminated (second status)))
                   "Process should be terminated after the test."))))))
