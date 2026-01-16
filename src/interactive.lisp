(in-package #:lto-phase1)

(defun send-input (string)
  "Sends a string of text to the PTY, simulating user input.

A newline character is automatically appended to the string to simulate the
user pressing 'Enter'. This function relies on the '*master-fd*' global
variable to identify the correct PTY to write to.

Args:
  string: The string to send as input to the shell."
  (when *master-fd*
    (let ((formatted-string (format nil "~A~%" string)))
      (cffi:with-foreign-string (buf formatted-string)
        (posix-write *master-fd* buf (length formatted-string))))))
