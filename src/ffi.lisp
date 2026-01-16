(in-package #:lto-phase1)

;;; Define foreign libraries for CFFI
(cffi:define-foreign-library libc
  (:unix "libc.so.6")
  (t (:default "libc")))

(cffi:define-foreign-library libutil
  (:unix "libutil.so.1")
  (t (:default "libutil")))

;;; Load the foreign libraries
(cffi:use-foreign-library libc)
(cffi:use-foreign-library libutil)

;;; CFFI bindings for POSIX functions

;; Corresponds to the forkpty() syscall from libutil.
;; Creates a new process and connects it to a new pseudo-terminal.
(cffi:defcfun "forkpty" :int
  (amaster :pointer)
  (name :pointer)
  (termp :pointer)
  (winp :pointer))

;; Corresponds to the read() syscall.
;; Reads from a file descriptor. We name it posix-read to avoid clashing with cl:read.
(cffi:defcfun ("read" posix-read) :int
  (fd :int)
  (buf :pointer)
  (count :int))

;; Corresponds to the write() syscall.
;; Writes to a file descriptor. We name it posix-write to avoid clashing with cl:write.
(cffi:defcfun ("write" posix-write) :int
  (fd :int)
  (buf :pointer)
  (count :int))

;; Corresponds to the execvp() syscall.
;; Replaces the current process image with a new process image.
(cffi:defcfun "execvp" :int
  (file :string)
  (argv :pointer))
