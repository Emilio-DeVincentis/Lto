(in-package #:lto-phase1)

(defun send-input (fd string)
  "Sends a string of text to the specified PTY file descriptor.

Args:
  fd: The file descriptor of the master PTY.
  string: The string to send as input to the shell."
  (cffi:with-foreign-string (buf string)
    (posix-write fd buf (length string))))
