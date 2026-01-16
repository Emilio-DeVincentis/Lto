(asdf:defsystem #:lto-phase1
  :description "LispTUI Orchestrator Phase 1: PTY Bridge"
  :author "Jules"
  :license "MIT"
  :version "0.0.1"
  :serial t
  :depends-on (#:cffi #:bordeaux-threads)
  :components ((:module "src"
                :serial t
                :components
                ((:file "packages")
                 (:file "ffi")
                 (:file "process")
                 (:file "io")
                 (:file "interactive")))))
