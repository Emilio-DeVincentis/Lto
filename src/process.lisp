(in-package #:lto-phase1)

(defvar *master-fd* nil "The file descriptor for the master side of the PTY.")

(defun spawn-pty-shell ()
  "Forks the current process, creates a PTY, and executes /bin/sh in the child.
  The parent process stores and returns the master file descriptor."
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
