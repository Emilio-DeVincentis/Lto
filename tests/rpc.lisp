(in-package #:lto-tests)

(in-suite :lto-tests)

(def-suite :lto-rpc :in :lto-tests
  :description "Tests for the RPC functionality.")

(in-suite :lto-rpc)

(test get-kakoune-socket-path-test
  "Tests the construction of the Kakoune socket path."
  (let ((original-getenv (symbol-function 'uiop:getenv))
        (original-dir-exists (symbol-function 'uiop:directory-exists-p)))
    (unwind-protect
         (progn
           ;; Test case 1: XDG_RUNTIME_DIR is set and exists
           (setf (symbol-function 'uiop:getenv) (lambda (name) (declare (ignore name)) "/fake/runtime/dir"))
           (setf (symbol-function 'uiop:directory-exists-p) (lambda (path) (declare (ignore path)) t))
           (is (equal "/fake/runtime/dir/kakoune/mysession"
                      (lto-phase1::get-kakoune-socket-path "mysession")))

           ;; Test case 2: XDG_RUNTIME_DIR is set but does not exist
           (setf (symbol-function 'uiop:getenv) (lambda (name) (declare (ignore name)) "/fake/runtime/dir"))
           (setf (symbol-function 'uiop:directory-exists-p) (lambda (path) (declare (ignore path)) nil))
           (is (equal "/tmp/kakoune/mysession"
                      (lto-phase1::get-kakoune-socket-path "mysession")))

           ;; Test case 3: XDG_RUNTIME_DIR is not set
           (setf (symbol-function 'uiop:getenv) (lambda (name) (declare (ignore name)) nil))
           (is (equal "/tmp/kakoune/mysession"
                      (lto-phase1::get-kakoune-socket-path "mysession"))))
      ;; Restore original functions
      (setf (symbol-function 'uiop:getenv) original-getenv)
      (setf (symbol-function 'uiop:directory-exists-p) original-dir-exists))))

(test send-to-editor-test
  "Tests the high-level send-to-editor function by mocking its dependency."
  (let ((received-session nil)
        (received-command nil)
        (original-func (symbol-function 'lto-phase1::send-kakoune-command)))
    (unwind-protect
         (progn
           ;; Define and set the mock function
           (setf (symbol-function 'lto-phase1::send-kakoune-command)
                 (lambda (session-name command)
                   (setf received-session session-name)
                   (setf received-command command)))

           ;; Call the function we are testing
           (lto-phase1::send-to-editor 5 "my-command")

           ;; Verify that our mock was called with the correct arguments
           (is (equal "LTO-5" received-session))
           (is (equal "my-command" received-command)))
      ;; Restore the original function
      (setf (symbol-function 'lto-phase1::send-kakoune-command) original-func))))
