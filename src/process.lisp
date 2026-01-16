(in-package #:lto-phase1)

(defvar *master-fd* nil
  "Holds the file descriptor for the master side of the PTY.
NOTE: This is a global variable, which is not ideal. It is used by 'send-input'
to direct output to the correct PTY. A future refactoring should make this
explicitly passed instead.")

(defun spawn-pty-shell ()
  "Spawns a new shell process connected to a pseudo-terminal (PTY).

This function orchestrates several steps:
1. It calls the 'forkpty' C function to create a new process.
2. The child process replaces itself with '/bin/sh' using 'execvp'.
3. The parent process receives the file descriptor for the master side of the PTY.

Returns:
  The integer file descriptor for the master side of the PTY, which can be used
  by the parent process to communicate with the child shell."
  (cffi:with-foreign-object (amaster :int)
    (let ((pid (forkpty amaster (cffi:null-pointer) (cffi:null-pointer) (cffi:null-pointer))))
      (cond
        ((zerop pid)
         ;; Child process: Execute the shell
         (cffi:with-foreign-strings ((sh "/bin/sh"))
           (cffi:with-foreign-object (argv :pointer 2)
             (setf (cffi:mem-aref argv :pointer 0) sh
                   (cffi:mem-aref argv :pointer 1) (cffi:null-pointer))
             (execvp "/bin/sh" argv))))
        ((> pid 0)
         ;; Parent process: Store and return the master FD
         (setf *master-fd* (cffi:mem-ref amaster :int))
         (format t "[Parent] Spawned child with PID ~A, master FD: ~A~%" pid *master-fd*)
         *master-fd*)
        (t
         ;; Error case
         (error "forkpty failed."))))))
