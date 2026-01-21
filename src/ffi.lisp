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
  "Corresponds to the forkpty() syscall from libutil."
  (amaster :pointer)
  (name :pointer)
  (termp :pointer)
  (winp :pointer))

(cffi:defcfun ("read" posix-read) :int
  "Corresponds to the read() syscall."
  (fd :int)
  (buf :pointer)
  (count :int))

(cffi:defcfun ("write" posix-write) :int
  "Corresponds to the write() syscall."
  (fd :int)
  (buf :pointer)
  (count :int))

(cffi:defcfun "execvp" :int
  "Corresponds to the execvp() syscall."
  (file :string)
  (argv :pointer))

(cffi:defcfun "setenv" :int
  "Corresponds to the setenv() syscall."
  (name :string)
  (value :string)
  (overwrite :int))

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

(cffi:defcfun "dup2" :int
  (oldfd :int)
  (newfd :int))

;; POSIX Signals
(defconstant sigkill 9)

;;; --- Termios definitions ---

(cffi:defcstruct termios
  (c_iflag :unsigned-int)
  (c_oflag :unsigned-int)
  (c_cflag :unsigned-int)
  (c_lflag :unsigned-int)
  (c_line :unsigned-char)
  (c_cc :unsigned-char :count 32)
  (c_ispeed :unsigned-int)
  (c_ospeed :unsigned-int))

(cffi:defcfun "tcgetattr" :int
  (fd :int)
  (termios_p :pointer))

(cffi:defcfun "tcsetattr" :int
  (fd :int)
  (optional_actions :int)
  (termios_p :pointer))

(cffi:defcfun "cfmakeraw" :void
  (termios_p :pointer))

;; Constants for waitpid
(defconstant wuntraced 2)
