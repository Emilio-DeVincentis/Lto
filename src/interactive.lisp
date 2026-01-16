(in-package #:lto-phase1)

(defun send-input (string)
  "Writes the given string, followed by a newline, to the PTY."
  (when *master-fd*
    (let ((formatted-string (format nil "~A~%" string)))
      (cffi:with-foreign-string (buf formatted-string)
        (posix-write *master-fd* buf (length formatted-string))))))
