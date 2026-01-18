(in-package #:lto-phase1)

(defvar *master-fd* nil
  "Holds the file descriptor for the master side of the PTY.
NOTE: This is a global variable, which is not ideal. It is used by 'send-input'
to direct output to the correct PTY. A future refactoring should make this
explicitly passed instead.")

(defun spawn-process-in-pty (command args &optional (env-vars nil))
  "Spawns a new process connected to a pseudo-terminal (PTY),
   with specified arguments and environment variables."
  (cffi:with-foreign-object (amaster :int)
    (let ((pid (forkpty amaster (cffi:null-pointer) (cffi:null-pointer) (cffi:null-pointer))))
      (cond
        ((zerop pid)
         ;; Child process
         ;; 1. Set environment variables
         (dolist (var env-vars)
           (let ((name (car var))
                 (value (cdr var)))
             (cffi:with-foreign-strings ((c-name name) (c-value value))
               (setenv c-name c-value 1)))) ; 1 = overwrite

         ;; 2. Prepare command and arguments for execvp
         (let* ((all-args (cons command args))
                (arg-count (length all-args)))
           (cffi:with-foreign-object (argv :pointer (1+ arg-count))
             (loop for i from 0
                   for arg in all-args
                   do (setf (cffi:mem-aref argv :pointer i) (cffi:foreign-string-alloc arg)))
             (setf (cffi:mem-aref argv :pointer arg-count) (cffi:null-pointer))

             (execvp command argv)
             ;; If execvp returns, it's an error
             (error "execvp failed for command: ~A" command))))
        ((> pid 0)
         ;; Parent process: Return the master FD and the PID
         (let ((master-fd (cffi:mem-ref amaster :int)))
           (values master-fd pid)))
        (t
         ;; Error case
         (error "forkpty failed."))))))
