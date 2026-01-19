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

(defun setup-layout-test ()
  (setf lto-tui::*layout-root* nil)
  (setf lto-tui::*active-pane* nil))

(test split-pane-test
  "Tests splitting a pane."
  (setup-layout-test)
  ;; 1. Setup initial state
  (let* ((initial-pane (make-instance 'pane :id 1 :title "Initial Pane"))
         (initial-node (make-pane-node initial-pane)))
    (setf lto-tui::*layout-root* initial-node)
    (setf lto-tui::*active-pane* initial-pane)

    ;; 2. Perform the split
    (let ((new-pane (lto-tui::split-active-pane :vertical "new-command")))

      ;; 3. Verify the new layout structure
      (is (typep lto-tui::*layout-root* 'lto-tui::split-node)
          "The root should now be a split-node.")
      (is (eq :vertical (lto-tui::split-node-orientation lto-tui::*layout-root*))
          "The split orientation should be vertical.")

      ;; 4. Verify children
      (let ((child-a (lto-tui::split-node-child-a lto-tui::*layout-root*))
            (child-b (lto-tui::split-node-child-b lto-tui::*layout-root*)))
        (is (eq initial-node child-a)
            "Child A should be the original pane node.")
        (is (typep child-b 'lto-tui::pane-node)
            "Child B should be a new pane node.")
        (is (eq new-pane (pane-node-pane child-b))
            "Child B should contain the new pane.")

        ;; 5. Verify parent-child relationships
        (is (eq lto-tui::*layout-root* (layout-node-parent child-a)))
        (is (eq lto-tui::*layout-root* (layout-node-parent child-b))))

      ;; 6. Verify the new active pane
      (is (eq new-pane lto-tui::*active-pane*)))))
