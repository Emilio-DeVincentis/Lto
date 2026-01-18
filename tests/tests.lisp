(in-package #:lto-tests)

(def-suite :lto-tests
  :description "Main test suite for LTO.")

(in-suite :lto-tests)

(test sanity-check
  "A simple test to ensure the framework is set up correctly."
  (is (= 1 1) "This simple check should always pass."))
