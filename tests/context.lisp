(in-package #:lto-tests)

(in-suite :lto-tests)

(test context-management
  "Test the basic functionality of get-context and set-context."
  ;; Ensure the context is clean before starting
  (setf lto-phase1::*lto-context* (make-hash-table :test 'equal))

  ;; 1. Test setting and getting a value
  (is (equal "bar" (set-context "foo" "bar")))
  (is (equal "bar" (get-context "foo")))

  ;; 2. Test getting a non-existent key without a default
  (is (null (get-context "non-existent-key")))

  ;; 3. Test getting a non-existent key with a default value
  (is (equal "default-value" (get-context "non-existent-key" "default-value")))

  ;; 4. Test overwriting an existing key
  (set-context "foo" "new-value")
  (is (equal "new-value" (get-context "foo"))))
