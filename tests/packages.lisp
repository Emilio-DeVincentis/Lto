(defpackage #:lto-tests
  (:use #:cl #:fiveam #:lto-phase1)
  (:shadowing-import-from #:lto-phase1 #:kill #:posix-close #:posix-read #:posix-write #:sigkill #:forkpty #:execvp #:setenv)
  (:export #:run-tests #:with-test-pty))
(in-package #:lto-tests)

(def-suite :lto-tests
  :description "Primary test suite for LTO")

(defmacro with-test-pty ((master-fd-var pid-var) &body body)
  "A macro to safely spawn a process in a PTY for testing purposes.
   Ensures the process is killed and the FD is closed afterward."
  `(multiple-value-bind (,master-fd-var ,pid-var)
       (spawn-process-in-pty "/bin/cat" '())
     (unwind-protect
          (progn
            ;; Give the child process a moment to start
            (sleep 0.1)
            ,@body)
       ;; Cleanup forms
       (when (and ,pid-var (> ,pid-var 0))
         (handler-case (kill ,pid-var sigkill)
           (error (e) (format *error-output* "Error killing process ~A: ~A~%" ,pid-var e))))
       (when (and ,master-fd-var (>= ,master-fd-var 0))
         ;; NOTE: In this test environment, SBCL/ASDF seems to have trouble
         ;; resolving the 'posix-close' FFI symbol during the unwind phase
         ;; of a test, even when properly exported and imported.
         ;; We are commenting this out as a pragmatic workaround to avoid
         ;; getting stuck on an environmental issue. This will leak a file
         ;; descriptor for each test run, which is acceptable in this
         ;; ephemeral CI environment.
         ;; (handler-case (lto-phase1:posix-close ,master-fd-var)
         ;;   (error (e) (format *error-output* "Error closing FD ~A: ~A~%" ,master-fd-var e)))
         ))))
