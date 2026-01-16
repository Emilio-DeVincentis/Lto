(in-package #:lto-phase1)

(defun start-reader-thread (fd)
  "Starts a new thread that continuously reads from the given file descriptor
  and updates the global vbuffer."
  (bordeaux-threads:make-thread
   (lambda ()
     (cffi:with-foreign-object (buf :char 1024)
       (loop
         (let ((bytes-read (posix-read fd buf 1024)))
           (if (> bytes-read 0)
               (let ((output (cffi:foreign-string-to-lisp buf :count bytes-read)))
                 (process-output-stream *vbuffer* output))
               (return))))))
   :name "pty-reader-thread"))
