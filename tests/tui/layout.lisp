(in-package :lto-tui-tests)
(in-suite :lto-tui)

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
  "Tests splitting a pane and updating the layout."
  (setup-layout-test)
  (let ((original-get-id (symbol-function 'lto-tui::get-next-pane-id)))
    (unwind-protect
         (progn
           ;; Mock get-next-pane-id to return a predictable value
           (setf (symbol-function 'lto-tui::get-next-pane-id) (lambda () 2))

           ;; 1. Setup initial state with a single pane
           (let* ((pane1 (make-instance 'pane :id 1 :title "Pane 1" :command "bash"))
                  (node1 (make-pane-node pane1)))
             (setf lto-tui::*layout-root* node1)
             (setf lto-tui::*active-pane* pane1)

             ;; 2. Perform the split operation
             (let ((new-pane (split-active-pane :vertical "top")))
               ;; 3. Verify the new pane
               (is (not (null new-pane)))
               (is (= 2 (pane-id new-pane)))
               (is (string= "top" (pane-command new-pane)))
               (is (eq new-pane lto-tui::*active-pane*) "The new pane should be active.")

               ;; 4. Verify the new layout structure
               (let ((root lto-tui::*layout-root*))
                 (is (typep root 'split-node) "Root should now be a split-node.")
                 (is (eq :vertical (split-node-orientation root)))
                 (is (eq node1 (split-node-child-a root)) "Child A should be the original node.")

                 (let ((new-node (split-node-child-b root)))
                   (is (typep new-node 'pane-node))
                   (is (eq new-pane (pane-node-pane new-node)))
                   (is (eq root (layout-node-parent new-node)))
                   (is (eq root (layout-node-parent node1))))))))
      ;; 4. Restore original function
      (setf (symbol-function 'lto-tui::get-next-pane-id) original-get-id))))

(test close-pane-test
  "Tests closing a pane and simplifying the layout."
  (setup-layout-test)
  ;; 1. Mock external dependencies and ensure cleanup
  (let ((original-kill (symbol-function 'lto-phase1:kill))
        (original-delwin (symbol-function 'charms/ll:delwin))
        (original-recalculate (symbol-function 'lto-tui::recalculate-layout))
        (original-dims (symbol-function 'charms:window-dimensions))
        (charms:*standard-window* (cffi:null-pointer)))
    (declare (ignorable charms:*standard-window*))
    (unwind-protect
         (progn
           ;; Override functions for the test
           (setf (symbol-function 'lto-phase1:kill) (lambda (pid signal) (declare (ignore pid signal)) t))
           (setf (symbol-function 'charms/ll:delwin) (lambda (win) (declare (ignore win)) t))
           (setf (symbol-function 'lto-tui::recalculate-layout) (lambda (node y x h w) (declare (ignore node y x h w)) t))
           (setf (symbol-function 'charms:window-dimensions) (lambda (win) (declare (ignore win)) (values 80 24)))

           ;; 2. Setup initial state with a split layout
           (let* ((pane1 (make-instance 'pane :id 1 :title "Pane 1" :child-pid 1234 :window (cffi:null-pointer)))
                  (pane2 (make-instance 'pane :id 2 :title "Pane 2" :child-pid 5678 :window (cffi:null-pointer)))
                  (node1 (make-pane-node pane1))
                  (node2 (make-pane-node pane2))
                  (split-node (make-split-node :vertical node1 node2)))
             (setf (layout-node-parent node1) split-node)
             (setf (layout-node-parent node2) split-node)
             (setf lto-tui::*layout-root* split-node)
             (setf lto-tui::*active-pane* pane2) ; We will close pane2

             ;; 3. Perform the close operation
             (close-active-pane)

             ;; 4. Verify the new state
             (is (eq lto-tui::*layout-root* node1)
                 "The layout root should now be the sibling node (node1).")
             (is (null (layout-node-parent lto-tui::*layout-root*))
                 "The new root node should have no parent.")
             (is (eq lto-tui::*active-pane* pane1)
                 "The active pane should be the sibling (pane1).")))
      ;; 5. Restore original functions
      (setf (symbol-function 'lto-phase1:kill) original-kill)
      (setf (symbol-function 'charms/ll:delwin) original-delwin)
      (setf (symbol-function 'lto-tui::recalculate-layout) original-recalculate)
      (setf (symbol-function 'charms:window-dimensions) original-dims))))
