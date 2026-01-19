(in-package #:lto-tests)

(in-suite :lto-tests)

(def-suite :lto-interactive :in :lto-tests
  :description "Tests for interactive functionality.")

(in-suite :lto-interactive)

(test send-input-test
  "Tests that send-input correctly writes to a PTY."
  (let (master-fd pid)
    (unwind-protect
         (progn
           (multiple-value-setq (master-fd pid)
             (spawn-process-in-pty "/bin/cat" '()))
           (sleep 0.1) ; Give cat a moment to start

           ;; Send input
           (send-input master-fd "hello\n")
           (sleep 0.1) ; Give cat a moment to respond

           ;; Read the echoed output
           (cffi:with-foreign-object (buf :char 1024)
             (let ((bytes-read (posix-read master-fd buf 1024)))
               (is (> bytes-read 0))
               (let ((output (cffi:foreign-string-to-lisp buf :count bytes-read)))
                 ;; In this raw PTY, we expect to get back exactly what we sent.
                 (is (equal "hello\n" output))))))
      ;; Cleanup forms
      (when (and pid (> pid 0))
        (kill pid sigkill))
      (when (and master-fd (>= master-fd 0))
        ;; Workaround for persistent FFI symbol resolution issue in tests
        ;; (posix-close master-fd)
        ))))
