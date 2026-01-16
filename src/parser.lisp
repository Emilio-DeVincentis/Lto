(in-package #:lto-phase1)

(defun parse-csi-sequence (vbuffer stream)
  "Parses a CSI sequence from the stream and updates the vbuffer."
  (let ((params '())
        (current-param 0)
        (char nil))
    (loop
      (setf char (read-char stream nil nil))
      (unless (and char (or (digit-char-p char) (char= char #\;)))
        (return))
      (if (char= char #\;)
          (progn
            (push current-param params)
            (setf current-param 0))
          (setf current-param (+ (* current-param 10) (digit-char-p char)))))
    (push current-param params)
    (setf params (nreverse params))
    (when char
      (case char
        (#\H ; Cursor Position
         (let ((row (or (first params) 1))
               (col (or (second params) 1)))
           (setf (vbuffer-cursor-y vbuffer) (max 0 (min (1- (vbuffer-height vbuffer)) (1- row))))
           (setf (vbuffer-cursor-x vbuffer) (max 0 (min (1- (vbuffer-width vbuffer)) (1- col))))))
      (#\A ; Cursor Up
         (setf (vbuffer-cursor-y vbuffer) (max 0 (- (vbuffer-cursor-y vbuffer) (or (first params) 1)))))
      (#\B ; Cursor Down
         (setf (vbuffer-cursor-y vbuffer) (min (1- (vbuffer-height vbuffer)) (+ (vbuffer-cursor-y vbuffer) (or (first params) 1)))))
      (#\C ; Cursor Forward
         (setf (vbuffer-cursor-x vbuffer) (min (1- (vbuffer-width vbuffer)) (+ (vbuffer-cursor-x vbuffer) (or (first params) 1)))))
      (#\D ; Cursor Backward
         (setf (vbuffer-cursor-x vbuffer) (max 0 (- (vbuffer-cursor-x vbuffer) (or (first params) 1)))))
      (#\J ; Erase in Display
       (when (= (or (first params) 0) 2)
         ;; Clear the entire screen
         (loop for y from 0 below (vbuffer-height vbuffer)
               do (loop for x from 0 below (vbuffer-width vbuffer)
                        do (setf (aref (vbuffer-grid vbuffer) y x) (make-vcell))))
         (setf (vbuffer-cursor-x vbuffer) 0)
           (setf (vbuffer-cursor-y vbuffer) 0)))))))

(defun process-output-stream (vbuffer raw-string)
  "Parses a raw string from the PTY and updates the vbuffer accordingly."
  (with-input-from-string (stream raw-string)
    (loop for char = (read-char stream nil nil)
          while char
          do (cond
               ((char= char #\Escape)
                (let ((next-char (read-char stream nil nil)))
                  (when (and next-char (char= next-char #\[))
                    (parse-csi-sequence vbuffer stream))))
               ((char= char #\newline)
                (setf (vbuffer-cursor-x vbuffer) 0)
                (when (< (vbuffer-cursor-y vbuffer) (1- (vbuffer-height vbuffer)))
                  (incf (vbuffer-cursor-y vbuffer))))
               ((char= char #\return)
                (setf (vbuffer-cursor-x vbuffer) 0))
               (t
                ;; Handle printable characters
                (when (>= (vbuffer-cursor-x vbuffer) (vbuffer-width vbuffer))
                  (setf (vbuffer-cursor-x vbuffer) 0)
                  (when (< (vbuffer-cursor-y vbuffer) (1- (vbuffer-height vbuffer)))
                    (incf (vbuffer-cursor-y vbuffer))))

                (let ((x (vbuffer-cursor-x vbuffer))
                      (y (vbuffer-cursor-y vbuffer)))
                  (when (< y (vbuffer-height vbuffer))
                    (setf (vcell-char (aref (vbuffer-grid vbuffer) y x)) char)
                    (incf (vbuffer-cursor-x vbuffer)))))))))
