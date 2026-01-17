;;; main.lisp

;; This file is now the main entry point for the LTO TUI application.

;; Load Quicklisp and the local project system
(load "~/quicklisp/setup.lisp")
(push *default-pathname-defaults* asdf:*central-registry*)
(ql:quickload :lto-phase1)

;; Start the TUI
(lto-tui:start-tui)
