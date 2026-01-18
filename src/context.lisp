;;; src/context.lisp

(in-package #:lto-phase1)

(defvar *lto-context* (make-hash-table :test 'equal)
  "A global, thread-safe hash table for storing shared state across the LTO system.
Keys are strings, values can be anything. Access should be synchronized using *lto-context-lock*.")

(defvar *lto-context-lock* (make-lock "lto-context-lock")
  "The lock for synchronizing access to *LTO-CONTEXT*.")

(defun get-context (key &optional default)
  "Safely retrieves a value from the global context."
  (with-lock-held (*lto-context-lock*)
    (gethash key *lto-context* default)))

(defun set-context (key value)
  "Safely sets a value in the global context."
  (with-lock-held (*lto-context-lock*)
    (setf (gethash key *lto-context*) value)))
