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

(cffi:defcfun "forkpty" :int
  "Corresponds to the forkpty() syscall from libutil.
Creates a new process, allocates a new pseudo-terminal (PTY), and associates
the PTY's slave side with the child's standard I/O streams.
Returns the child's PID in the parent, 0 in the child, or -1 on error."
  (amaster :pointer)
  (name :pointer)
  (termp :pointer)
  (winp :pointer))

(cffi:defcfun ("read" posix-read) :int
  "Corresponds to the read() syscall.
Reads a specified number of bytes from a file descriptor into a buffer.
Renamed to 'posix-read' to avoid symbol conflicts with cl:read."
  (fd :int)
  (buf :pointer)
  (count :int))

(cffi:defcfun ("write" posix-write) :int
  "Corresponds to the write() syscall.
Writes a specified number of bytes from a buffer to a file descriptor.
Renamed to 'posix-write' to avoid symbol conflicts with cl:write."
  (fd :int)
  (buf :pointer)
  (count :int))

(cffi:defcfun "execvp" :int
  "Corresponds to the execvp() syscall.
Replaces the current process image with a new process image. Used by the child
process to execute a shell after the fork."
  (file :string)
  (argv :pointer))

(cffi:defcfun "waitpid" :int
  (pid :int)
  (statloc :pointer)
  (options :int))

;; For resizing
(defconstant tiocswinsz #x5414)

(cffi:defcstruct winsize
  (ws_row :unsigned-short)
  (ws_col :unsigned-short)
  (ws_xpixel :unsigned-short)
  (ws_ypixel :unsigned-short))

(cffi:defcfun "ioctl" :int
  (fd :int)
  (request :unsigned-long)
  &rest)

(cffi:defcfun "kill" :int
  (pid :int)
  (sig :int))

;; POSIX Signals
(defconstant sigkill 9)
