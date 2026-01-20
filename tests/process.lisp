(in-package #:lto-tests)

(in-suite :lto-tests)

(def-suite :lto-process :in :lto-tests
  :description "Tests for process and PTY management.")

(in-suite :lto-process)

(test spawn-process-in-pty-test
  "Tests the successful spawning of a process in a PTY."
  (with-test-pty (master-fd pid)
    (is (and (integerp master-fd) (>= master-fd 0))
        "spawn-process-in-pty should return a valid file descriptor.")
    (is (and (integerp pid) (> pid 0))
        "spawn-process-in-pty should return a valid PID.")

    ;; Check if the process is alive
    (is (zerop (kill pid 0))
        "The spawned process should be alive.")))
