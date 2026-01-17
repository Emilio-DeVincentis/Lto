;;; src/tui/renderer.lisp

(in-package #:lto-tui)

(defun render-pane (pane &key (is-active? nil))
  "Renders the content of a single pane, including borders, title, and vbuffer content."
  (bt:with-lock-held ((pane-lock pane))
    (when (pane-dirty-p pane)
      (let ((window (pane-window pane))
            (vbuffer (pane-vbuffer pane)))

        ;; 1. Set color based on focus and draw borders
        (let ((color-pair (if is-active?
                              (charms/ll:color-pair 2)
                              (charms/ll:color-pair 1))))
          (unwind-protect
               (progn
                 (charms/ll:wattron window color-pair)
                 (charms/ll:box window 0 0))
            (charms/ll:wattroff window color-pair)))

        ;; 2. Draw title
        (charms:write-string-at-point window (pane-title pane) 0 1)

        ;; 3. Draw vbuffer content
        (let ((grid (vbuffer-grid vbuffer)))
          (destructuring-bind (rows cols) (array-dimensions grid)
            (loop for y from 0 below rows
                  do (loop for x from 0 below cols
                           do (let* ((cell (aref grid y x))
                                     (char (vcell-char cell)))
                                (charms:write-char-at-point window char (+ y 1) (+ x 1)))))))

        (setf (pane-dirty-p pane) nil)))

    (charms:refresh-window (pane-window pane))))
