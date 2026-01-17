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
  Two values:
  1. The integer file descriptor for the master side of the PTY.
  2. The PID of the spawned child process."
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
         ;; Parent process: Return the master FD and the PID
         (let ((master-fd (cffi:mem-ref amaster :int)))
           (values master-fd pid)))
        (t
         ;; Error case
         (error "forkpty failed."))))))
