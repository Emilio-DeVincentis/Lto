(asdf:defsystem #:lto-tests
  :description "Test suite for lto."
  :author "Jules"
  :license "MIT"
  :pathname "tests/"
  :depends-on (#:lto-phase1 #:fiveam)
  :serial t
  :components ((:file "packages")
               (:file "tests")
               (:file "context")
               (:file "parser")
               (:file "watchers")
               (:file "vte"))
  :perform (test-op (o c) (symbol-call '#:lto-tests '#:run-tests)))
