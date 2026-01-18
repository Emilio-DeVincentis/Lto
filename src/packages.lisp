(defpackage #:lto-phase1
  (:use #:cl #:bordeaux-threads #:cl-ppcre #:iolib #:babel)
  (:export #:spawn-process-in-pty
           #:send-input
           ;; VTE exports
           #:make-vbuffer
           #:vbuffer-grid
           #:vcell-char
           #:vbuffer-cursor-x
           #:vbuffer-cursor-y
           #:vbuffer-width
           #:vbuffer-height
           #:clear-buffer
           #:get-line-text
           #:find-string-in-buffer
           ;; Parser exports
           #:process-output-stream
           ;; FFI exports for resize
           #:ioctl
           #:tiocswinsz
           #:kill
           #:posix-close
           #:sigkill
           ;; Watcher exports
           #:define-watcher
           #:watcher-callback
           #:watcher-compiled-regex
           #:*watchers-lock*
           #:*global-watchers*
           #:activate-watcher
           #:*watcher-definitions*
           ;; RPC exports
           #:send-to-editor
           ;; Context exports
           #:get-context
           #:set-context
           #:*lto-context*))
