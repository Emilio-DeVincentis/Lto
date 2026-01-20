;;; src/tui/test-rpc.lisp

(in-package #:lto-tui)

(defun handle-test-command (command-str)
  "Parses a command string from the test client and returns the result."
  (let ((command (read-from-string command-str)))
    (prin1-to-string
     (case (car command)
       (:get-pane-count
        (length (get-all-panes *layout-root*)))
       (:get-active-pane-id
        (pane-id *active-pane*))
       (otherwise
        (list :error "Unknown command"))))))

(defun test-rpc-server-loop (server)
  "The main loop for the test RPC server thread."
  (loop
    (let ((client-stream (iolib:accept-connection server :wait t)))
      (when client-stream
        (unwind-protect
             (let* ((command-str (read-line client-stream))
                    (response (handle-test-command command-str)))
               (write-line response client-stream)
               (finish-output client-stream))
          (close client-stream))))))

(defun start-test-rpc-server (&optional (port 9999))
  "Starts the test RPC server in a new thread."
  (let ((server (iolib:make-socket :connect :passive
                                   :address-family :internet
                                   :type :stream
                                   :external-format '(:utf-8)
                                   :local-port port)))
    (make-thread (lambda () (test-rpc-server-loop server))
                 :name "test-rpc-server")))
