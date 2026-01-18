;;; src/rpc.lisp

(in-package #:lto-phase1)

(defun get-kakoune-socket-path (session-name)
  "Constructs the full path to the Kakoune socket for a given session name."
  (let ((tmpdir (uiop:getenv "XDG_RUNTIME_DIR")))
    (unless (and tmpdir (uiop:directory-exists-p tmpdir))
      (setf tmpdir "/tmp"))
    (format nil "~A/kakoune/~A" tmpdir session-name)))

(defun send-kakoune-command (session-name command)
  "Sends a command to a Kakoune session via its Unix socket."
  (let* ((socket-path (get-kakoune-socket-path session-name))
         (full-command (format nil "eval -client 0 %~A~%" command)))
    (handler-case
        (with-open-socket (socket :address-family :local
                                        :remote-filename socket-path)
          (write-sequence (string-to-octets full-command) socket)
          (finish-output socket)
          (values t))
      (error (e)
        (format *error-output* "Failed to send command to Kakoune session ~A: ~A~%" session-name e)
        (values nil e)))))

(defun send-to-editor (pane-id command-string)
  "High-level function to send a command to the editor running in a specific pane."
  ;; For now, we assume the editor is Kakoune and the session is named deterministically.
  (let ((session-name (format nil "LTO-~A" pane-id)))
    (send-kakoune-command session-name command-string)))
