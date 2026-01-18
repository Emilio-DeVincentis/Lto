;;; src/tui/snapshot.lisp

(in-package #:lto-tui)

(defun clean-ansi-codes (text)
  "Removes ANSI escape codes from a string."
  (regex-replace-all "(\x9B|\x1B\\[)[0-?]*[ -/]*[@-~]" text ""))

(defun get-all-panes (layout-root)
  "Traverses the layout tree and returns a flat list of all pane objects."
  (let ((panes '()))
    (labels ((traverse (node)
               (typecase node
                 (pane-node
                  (push (pane-node-pane node) panes))
                 (split-node
                  (traverse (split-node-child-a node))
                  (traverse (split-node-child-b node))))))
      (traverse layout-root)
      (reverse panes))))

(defun capture-semantic-snapshot ()
  "Serializes the state of all panes into a JSON string."
  (let ((snapshot-data '()))
    (dolist (pane (get-all-panes *layout-root*))
      (let ((pane-info (make-hash-table :test 'equal)))
        (setf (gethash "id" pane-info) (pane-id pane))
        (setf (gethash "title" pane-info) (pane-title pane))
        (setf (gethash "command" pane-info) (pane-command pane))
        (setf (gethash "content" pane-info)
              (clean-ansi-codes
               (dump-vbuffer-to-string (pane-vbuffer pane))))
        (push pane-info snapshot-data)))

    (with-output-to-string (s)
      (encode-json (reverse snapshot-data) s))))
