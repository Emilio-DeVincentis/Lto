(in-package #:lto-tests)

(in-suite :lto-tests)

(defvar *test-watcher-fired* nil)

(define-watcher test-watcher (pane matches)
  :regex "test-pattern"
  :callback ((setf *test-watcher-fired* t)))

(test watcher-system
  "Test the watcher definition, activation, and callback functionality."
  (let ((vbuffer (make-vbuffer 80 24)))
    ;; 1. Test watcher definition
    (is-true (gethash 'test-watcher lto-phase1::*watcher-definitions*))

    ;; 2. Test watcher activation
    (activate-watcher 'test-watcher)
    (is-true (member 'test-watcher lto-phase1::*global-watchers* :key #'lto-phase1::watcher-name))

    ;; 3. Test watcher callback
    (setf *test-watcher-fired* nil)
    (process-output-stream vbuffer "some text containing test-pattern")
    (is-true *test-watcher-fired*)))
