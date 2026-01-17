(asdf:defsystem #:lto-phase1
  :description "LispTUI Orchestrator Phase 1: PTY Bridge"
  :author "Jules"
  :license "MIT"
  :version "0.1.0"
  :serial t
  :depends-on (#:cffi #:bordeaux-threads #:cl-charms)
  :components ((:module "src"
                :serial t
                :components
                ((:file "packages")
                 (:file "ffi")
                 (:file "vte")
                 (:file "parser")
                 (:file "process")
                 (:file "io")
                 (:file "interactive")
                 (:module "tui"
                  :serial t
                  :components
                  ((:file "packages")
                   (:file "pane")
                   (:file "layout-manager")
                   (:file "renderer")
                   (:file "tui-main")))))))
