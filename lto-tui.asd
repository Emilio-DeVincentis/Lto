(asdf:defsystem #:lto-tui
  :description "LispTUI Orchestrator - TUI component"
  :author "Jules"
  :license "MIT"
  :version "0.1.0"
  :serial t
  :depends-on (#:lto-phase1 #:iolib #:bordeaux-threads #:cl-ppcre #:cl-json)
  :components ((:module "src/tui"
                :serial t
                :components
                ((:file "packages")
                 (:file "pane")
                 (:file "layout-manager")
                 (:file "renderer")
                 (:file "tui-main")
                 (:file "snapshot")))))
