(in-package #:lto-tests)

(in-suite :lto-tests)

(test get-line-text-test
  "Test the get-line-text function."
  (let ((vbuffer (make-vbuffer 80 24)))
    (process-output-stream vbuffer (format nil "line 1~%line 2~%"))
    (is (string= "line 1" (get-line-text vbuffer 0)))
    (is (string= "line 2" (get-line-text vbuffer 1)))))

(test find-string-in-buffer-test
  "Test the find-string-in-buffer function."
  (let ((vbuffer (make-vbuffer 80 24)))
    (process-output-stream vbuffer (format nil "hello world~%find me here~%"))
    (is (equal '(6 0) (find-string-in-buffer vbuffer "world")))
    (is (equal '(5 1) (find-string-in-buffer vbuffer "me")))
    (is (null (find-string-in-buffer vbuffer "not-found")))))
