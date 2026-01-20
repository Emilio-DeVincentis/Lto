(asdf:defsystem #:lto-tui-tests
  :description "Test suite for the LTO TUI."
  :author "Jules"
  :license "MIT"
  :pathname "tests/tui/"
  :depends-on (#:lto-tui #:fiveam)
  :serial t
  :components ((:file "packages")
               (:file "layout"))
  :perform (test-op (o c) (symbol-call '#:lto-tui-tests '#:run-tui-tests)))
