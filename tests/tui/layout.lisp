(in-package #:lto-tui-tests)

(def-suite :lto-tui-layout
  :description "Tests for the TUI layout management.")

(in-suite :lto-tui-layout)

(defun run-tui-tests ()
  (run! :lto-tui-layout))

(test initial-layout-creation
  "Tests that the initial layout root is created correctly."
  (let* ((initial-pane (make-instance 'pane :id 1 :title "Test Pane"))
         (layout-root (make-pane-node initial-pane)))
    (is (typep layout-root 'pane-node)
        "The layout root should be a pane-node.")
    (is (eq initial-pane (pane-node-pane layout-root))
        "The layout root should contain the initial pane.")
    (is (null (layout-node-parent layout-root))
        "The initial layout root should have no parent.")))
