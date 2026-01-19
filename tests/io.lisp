(in-package #:lto-tests)

(in-suite :lto-tests)

(def-suite :lto-io :in :lto-tests
  :description "Tests for I/O functionality.")

(in-suite :lto-io)

(test start-reader-thread-test
  "Tests that the reader thread correctly reads from a PTY and updates the vbuffer."
  (let (master-fd pid reader-thread)
    (unwind-protect
         (let ((vbuffer (make-vbuffer 80 24)))
           ;; 1. Spawn PTY and start reader thread
           (multiple-value-setq (master-fd pid) (spawn-process-in-pty "/bin/cat" '()))
           (setf reader-thread (start-reader-thread master-fd vbuffer))
           (sleep 0.2) ; Give threads time to start

           ;; 2. Write to the PTY
           (send-input master-fd "testing io\n")
           (sleep 0.2) ; Give the reader thread time to process the input

           ;; 3. Verify the vbuffer content
           (let ((line-text (get-line-text vbuffer 0)))
             (is (equal "testing io" (subseq line-text 0 (length "testing io"))))))
      ;; Cleanup forms
      (when (and reader-thread (bt:thread-alive-p reader-thread))
        (bt:destroy-thread reader-thread))
      (when (and pid (> pid 0))
        (kill pid sigkill))
      (when (and master-fd (>= master-fd 0))
        ;; Workaround for persistent FFI symbol resolution issue in tests
        ;; (posix-close master-fd)
        ))))
