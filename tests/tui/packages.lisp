(defpackage #:lto-tui-tests
  (:use #:cl #:fiveam #:lto-tui)
  (:export #:run-tui-tests))
(in-package :lto-tui-tests)

(def-suite :lto-tui
  :description "Test suite for the TUI components.")

(defun run-tui-tests ()
  (run! :lto-tui))
