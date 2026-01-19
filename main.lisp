;;; main.lisp

;; This file is now the main entry point for the LTO TUI application.

;; Load Quicklisp and the local project system
(load "~/quicklisp/setup.lisp")
(push *default-pathname-defaults* asdf:*central-registry*)
(ql:quickload :lto-tui)

;; Activate our watchers
(lto-phase1:activate-watcher 'lto-phase1:lisp-error-jumper)

;; Start the TUI
(lto-tui:start-tui)
