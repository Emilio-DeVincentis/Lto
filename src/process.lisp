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
         (dolist (var env-vars)
           (setenv (car var) (cdr var) 1))
         (let* ((all-args (cons command args))
                (arg-count (length all-args)))
           (cffi:with-foreign-object (argv :pointer (1+ arg-count))
             (loop for i from 0 for arg in all-args
                   do (setf (cffi:mem-aref argv :pointer i) (cffi:foreign-string-alloc arg)))
             (setf (cffi:mem-aref argv :pointer arg-count) (cffi:null-pointer))
             (execvp command argv)
             (error "execvp failed for command: ~A" command))))
        ((> pid 0)
         (let ((master-fd (cffi:mem-ref amaster :int)))
           (values master-fd pid)))
        (t
         (error "forkpty failed."))))))

(defun spawn-process-in-raw-pty (command args &optional (env-vars nil))
  "Spawns a process in a PTY after configuring the PTY's slave
   side to raw mode in the child process."
  (cffi:with-foreign-object (amaster :int)
    (let ((pid (forkpty amaster (cffi:null-pointer) (cffi:null-pointer) (cffi:null-pointer))))
      (cond
        ((zerop pid)
         ;; Child process
         (cffi:with-foreign-object (termios '(:struct termios))
           (tcgetattr 0 termios)
           (cfmakeraw termios)
           (tcsetattr 0 0 termios))
         (dolist (var env-vars)
           (setenv (car var) (cdr var) 1))
         (let* ((all-args (cons command args))
                (arg-count (length all-args)))
           (cffi:with-foreign-object (argv :pointer (1+ arg-count))
             (loop for i from 0 for arg in all-args
                   do (setf (cffi:mem-aref argv :pointer i) (cffi:foreign-string-alloc arg)))
             (setf (cffi:mem-aref argv :pointer arg-count) (cffi:null-pointer))
             (execvp command argv)
             (error "execvp failed"))))
        ((> pid 0)
         (let ((master-fd (cffi:mem-ref amaster :int)))
           (values master-fd pid)))
        (t
         (error "forkpty failed."))))))
