;;; src/tui/layout-manager.lisp

(in-package #:lto-tui)

(defclass layout-node ()
  ((parent :initarg :parent :accessor layout-node-parent)))

(defclass pane-node (layout-node)
  ((pane :initarg :pane :reader pane-node-pane)))

(defclass split-node (layout-node)
  ((orientation :initarg :orientation :reader split-node-orientation)
   (child-a :initarg :child-a :accessor split-node-child-a)
   (child-b :initarg :child-b :accessor split-node-child-b)
   (split-percentage :initarg :split-percentage :accessor split-node-percentage)))

(defun make-pane-node (pane &optional parent)
  (make-instance 'pane-node :pane pane :parent parent))

(defun make-split-node (orientation child-a child-b &key (split-percentage 0.5) parent)
  (make-instance 'split-node :orientation orientation :child-a child-a :child-b child-b
                               :split-percentage split-percentage :parent parent))

(defun find-pane-node (root pane-to-find)
  (typecase root
    (pane-node (when (eq (pane-node-pane root) pane-to-find) root))
    (split-node (or (find-pane-node (split-node-child-a root) pane-to-find)
                    (find-pane-node (split-node-child-b root) pane-to-find)))))

(defun replace-node-in-parent (old-node new-node)
  (let ((parent (layout-node-parent old-node)))
    (when parent
      (if (eq old-node (split-node-child-a parent))
          (setf (split-node-child-a parent) new-node)
          (setf (split-node-child-b parent) new-node))
      (setf (layout-node-parent new-node) parent))))

(defun get-next-pane-id ()
  (let ((max-id 0))
    (labels ((traverse (node)
               (typecase node
                 (pane-node (setf max-id (max max-id (pane-id (pane-node-pane node)))) )
                 (split-node (traverse (split-node-child-a node))
                             (traverse (split-node-child-b node))))))
      (traverse *layout-root*))
    (1+ max-id)))

(defun get-sibling-node (node)
  (let ((parent (layout-node-parent node)))
    (when (and parent (typep parent 'split-node))
      (if (eq node (split-node-child-a parent))
          (split-node-child-b parent)
          (split-node-child-a parent)))))

(defun get-first-leaf (node)
  "Find the first pane-node in a subtree."
  (typecase node
    (pane-node node)
    (split-node (get-first-leaf (split-node-child-a node)))))

(defun move-focus (direction)
  (labels ((find-target-pane (node)
             (let ((parent (layout-node-parent node)))
               (when (and parent (typep parent 'split-node))
                 (let ((orientation (split-node-orientation parent))
                       (sibling (get-sibling-node node)))
                   (cond
                     ;; Moving right in a vertical split
                     ((and (eq direction :right) (eq orientation :vertical) (eq node (split-node-child-a parent)))
                      (get-first-leaf sibling))
                     ;; Moving left in a vertical split
                     ((and (eq direction :left) (eq orientation :vertical) (eq node (split-node-child-b parent)))
                      (get-first-leaf sibling))
                     ;; Moving down in a horizontal split
                     ((and (eq direction :down) (eq orientation :horizontal) (eq node (split-node-child-a parent)))
                      (get-first-leaf sibling))
                     ;; Moving up in a horizontal split
                     ((and (eq direction :up) (eq orientation :horizontal) (eq node (split-node-child-b parent)))
                      (get-first-leaf sibling))
                     ;; Otherwise, recurse up the tree
                     (t (find-target-pane parent))))))))
    (let* ((current-node (find-pane-node *layout-root* *active-pane*))
           (target-node (find-target-pane current-node)))
      (when target-node
        (setf *active-pane* (pane-node-pane target-node))))))

(defun close-active-pane ()
  (when *active-pane*
    (let* ((pane-to-close *active-pane*)
           (node-to-close (find-pane-node *layout-root* pane-to-close)))
      (when node-to-close
        (cond
          ;; Case 1: The pane to close is the only pane (the root).
          ((eq node-to-close *layout-root*)
           (kill (pane-child-pid pane-to-close) sigkill)
           (charms/ll:delwin (pane-window pane-to-close))
           (setf *layout-root* nil)
           (setf *active-pane* nil))

          ;; Case 2: The pane is part of a split.
          (t
           (let* ((parent-split (layout-node-parent node-to-close))
                  (sibling-node (get-sibling-node node-to-close)))
             (kill (pane-child-pid pane-to-close) sigkill)
             (charms/ll:delwin (pane-window pane-to-close))

             ;; If the parent split is the root, the sibling becomes the new root.
             (if (eq parent-split *layout-root*)
                 (setf *layout-root* sibling-node)
                 (replace-node-in-parent parent-split sibling-node))

             (setf (layout-node-parent sibling-node) (layout-node-parent parent-split))
             (setf *active-pane* (pane-node-pane (get-first-leaf sibling-node)))
             (multiple-value-bind (cols rows) (charms:window-dimensions charms:*standard-window*)
               (recalculate-layout *layout-root* 0 0 rows cols)))))))))

(defun notify-panes-of-resize (node)
  "Traverse the layout tree and notify each PTY of the new terminal size."
  (typecase node
    (pane-node
     (let ((pane (pane-node-pane node)))
       (multiple-value-bind (cols rows) (charms:window-dimensions (pane-window pane))
         (cffi:with-foreign-object (ws 'lto-phase1::winsize)
           (setf (cffi:foreign-slot-value ws '(:struct lto-phase1::winsize) 'lto-phase1::ws_row) rows)
           (setf (cffi:foreign-slot-value ws '(:struct lto-phase1::winsize) 'lto-phase1::ws_col) cols)
           (ioctl (pane-pty-master-fd pane) tiocswinsz :pointer ws)))))
    (split-node
     (notify-panes-of-resize (split-node-child-a node))
     (notify-panes-of-resize (split-node-child-b node)))))

(defun recalculate-layout (node y x height width)
  (typecase node
    (pane-node
     (let ((pane (pane-node-pane node)))
       (if (pane-window pane)
           (progn
             (charms/ll:mvwin (pane-window pane) y x)
             (charms/ll:wresize (pane-window pane) height width))
           (setf (slot-value pane 'window) (charms/ll:newwin height width y x)))
       (setf (slot-value (pane-vbuffer pane) 'height) (- height 2))
       (setf (slot-value (pane-vbuffer pane) 'width) (- width 2))
       (setf (pane-dirty-p pane) t)))
    (split-node
     (if (eq (split-node-orientation node) :vertical)
         (let* ((width-a (floor (* width (split-node-percentage node))))
                (width-b (- width width-a)))
           (recalculate-layout (split-node-child-a node) y x height width-a)
           (recalculate-layout (split-node-child-b node) y (+ x width-a) height width-b))
         (let* ((height-a (floor (* height (split-node-percentage node))))
                (height-b (- height height-a)))
           (recalculate-layout (split-node-child-a node) y x height-a width)
           (recalculate-layout (split-node-child-b node) (+ y height-a) x height-b width))))))

(defun split-active-pane (orientation command)
  "Splits the active pane, creating a new pane alongside it.
   Returns the newly created pane object."
  (let ((pane-to-split *active-pane*))
    (when pane-to-split
      (let ((node-to-split (find-pane-node *layout-root* pane-to-split)))
        (when node-to-split
          (let* ((new-pane-id (get-next-pane-id))
                 (new-pane (make-pane new-pane-id
                                      (format nil "Pane ~d" new-pane-id)
                                      command
                                      (make-vbuffer 1 1) nil 0 0)) ; FD/PID are set later
                 (new-node (make-pane-node new-pane))
                 (new-split (make-split-node orientation
                                             node-to-split
                                             new-node
                                             :parent (layout-node-parent node-to-split))))

            (setf (layout-node-parent node-to-split) new-split)
            (setf (layout-node-parent new-node) new-split)

            (if (eq node-to-split *layout-root*)
                (setf *layout-root* new-split)
                (replace-node-in-parent node-to-split new-split))

            (setf *active-pane* new-pane)
            new-pane))))))
