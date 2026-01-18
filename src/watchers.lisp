;;; src/watchers.lisp

(in-package #:lto-phase1)

(defstruct watcher
  (name nil :type symbol)
  (regex nil :type string)
  (compiled-regex nil)
  (callback nil :type function)
  (pane-specific-p nil :type boolean))

(defvar *global-watchers* '()
  "A list of all globally active watchers.")

(defvar *watchers-lock* (make-lock "watchers-lock")
  "A lock to synchronize access to the watchers lists.")

(defmacro define-watcher (name (pane-var &optional (matches-var (gensym "matches-")))
                         &key regex pane-specific-p callback)
  "A DSL for defining new watchers.
   - NAME: A symbol to identify the watcher.
   - PANE-VAR: The variable that will be bound to the pane object in the callback.
   - MATCHES-VAR: The variable that will be bound to the list of regex matches.
   - REGEX: The string pattern to match against pane output.
   - PANE-SPECIFIC-P: If T, this watcher must be explicitly enabled on a pane.
   - CALLBACK: A lambda expression that will be executed on match."
  `(let ((new-watcher (make-watcher
                       :name ',name
                       :regex ,regex
                       :compiled-regex (create-scanner ,regex :multi-line-mode t)
                       :callback (lambda (,pane-var ,matches-var) ,@callback)
                       :pane-specific-p ,pane-specific-p)))
     (with-lock-held (*watchers-lock*)
       (if ,pane-specific-p
           ;; Pane-specific watchers are defined but not globally enabled.
           ;; They need to be attached to a pane instance later.
           (progn
             (format t "Defined pane-specific watcher: ~A~%" ',name)
             ;; Store it somewhere if you want to activate it by name later
             )
           ;; Global watchers are added to the active list immediately.
           (push new-watcher *global-watchers*)))
     ',name))

;;; --- Example Watcher ---
;; (define-watcher example-error-watcher (pane matches)
;;     :regex "Error"
;;     :pane-specific-p nil
;;     :callback ((let ((line (first matches)))
;;                  (set-context "last-error" (format nil "Error found in pane ~A: ~A" (lto-tui::pane-id pane) line)))))

(define-watcher lisp-error-jumper (pane matches)
  :regex "([\\w\\/\\.-]+.lisp):(\\d+):"
  :pane-specific-p nil
  :callback
  ((let ((file-path (second matches))
         (line-num (third matches)))
     (when (and file-path line-num)
       ;; For now, hardcode sending the command to pane 2, which is where we spawn kakoune
       (send-to-editor 2 (format nil "edit -existing ~A" file-path))
       (send-to-editor 2 (format nil "select ~A.1,~A.999" line-num line-num))))))
