(in-package #:lto-tests)

(in-suite :lto-tests)

(defvar *test-watcher-fired* nil)
(defvar *inactive-watcher-fired* nil)
(defvar *another-watcher-fired* nil)

(define-watcher test-watcher (pane matches)
  :regex "test-pattern"
  :callback ((setf *test-watcher-fired* t)))

(define-watcher inactive-watcher (pane matches)
  :regex "inactive-pattern"
  :callback ((setf *inactive-watcher-fired* t)))

(define-watcher another-watcher (pane matches)
  :regex "another-pattern"
  :callback ((setf *another-watcher-fired* t)))

(defun setup-watchers-test ()
  "Reset state before each watcher test run."
  (setf lto-phase1::*global-watchers* '())
  (setf *test-watcher-fired* nil)
  (setf *inactive-watcher-fired* nil)
  (setf *another-watcher-fired* nil))

(test watcher-system
  "Test the basic watcher definition, activation, and callback functionality."
  (setup-watchers-test)
  (let ((vbuffer (make-vbuffer 80 24)))
    (is-true (gethash 'test-watcher lto-phase1::*watcher-definitions*))

    (activate-watcher 'test-watcher)
    (is-true (member 'test-watcher lto-phase1::*global-watchers* :key #'lto-phase1::watcher-name))

    (process-output-stream vbuffer "some text containing test-pattern")
    (is-true *test-watcher-fired*)))

(test watcher-activation-edge-cases
  "Tests activation of non-existent and already-active watchers."
  (setup-watchers-test)
  ;; Attempt to activate a watcher that doesn't exist
  (activate-watcher 'non-existent-watcher)
  (is (null lto-phase1::*global-watchers*)
      "Activating a non-existent watcher should not add it to the global list.")

  ;; Activate a watcher once, then try to activate it again
  (activate-watcher 'test-watcher)
  (activate-watcher 'test-watcher)
  (is (= 1 (length lto-phase1::*global-watchers*))
      "Activating an already-active watcher should not add it to the list again."))

(test inactive-and-multiple-watchers
  "Tests that inactive watchers don't fire and multiple watchers work correctly."
  (setup-watchers-test)
  (let ((vbuffer (make-vbuffer 80 24)))
    ;; Activate two watchers, but not 'inactive-watcher'
    (activate-watcher 'test-watcher)
    (activate-watcher 'another-watcher)

    ;; Send text that matches the inactive watcher
    (process-output-stream vbuffer "some text with inactive-pattern")
    (is-false *inactive-watcher-fired*
              "An inactive watcher should not fire.")

    ;; Send text that matches one of the active watchers
    (process-output-stream vbuffer "some text with another-pattern")
    (is-true *another-watcher-fired*
             "The correct active watcher should fire.")
    (is-false *test-watcher-fired*
              "An active watcher should not fire if its pattern doesn't match.")))
