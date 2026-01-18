(in-package #:lto-tests)

(in-suite :lto-tests)

(test parser-functionality
  "Sequentially tests all parser functionality on a single vbuffer."
  (let ((vbuffer (make-vbuffer 80 24)))
    ;; 1. Test simple text parsing
    (process-output-stream vbuffer "Hello")
    (is (char= #\H (vcell-char (aref (vbuffer-grid vbuffer) 0 0))))
    (is (char= #\o (vcell-char (aref (vbuffer-grid vbuffer) 0 4))))
    (is (= 5 (vbuffer-cursor-x vbuffer)))
    (is (= 0 (vbuffer-cursor-y vbuffer)))

    ;; 2. Test newline handling
    (process-output-stream vbuffer (format nil "~%"))
    (is (= 0 (vbuffer-cursor-x vbuffer)))
    (is (= 1 (vbuffer-cursor-y vbuffer)))

    ;; 3. Test carriage return handling
    (process-output-stream vbuffer "World")
    (process-output-stream vbuffer (format nil "~c" #\Return))
    (is (char= #\W (vcell-char (aref (vbuffer-grid vbuffer) 1 0))))
    (is (= 0 (vbuffer-cursor-x vbuffer)))
    (is (= 1 (vbuffer-cursor-y vbuffer)))
    ;; Check that writing more text overwrites from the beginning of the line
    (process-output-stream vbuffer "Hi")
    (is (char= #\H (vcell-char (aref (vbuffer-grid vbuffer) 1 0))))
    (is (char= #\i (vcell-char (aref (vbuffer-grid vbuffer) 1 1))))
    (is (char= #\r (vcell-char (aref (vbuffer-grid vbuffer) 1 2))) "Original text should persist after overwritten part")
    (is (= 2 (vbuffer-cursor-x vbuffer)))
    (is (= 1 (vbuffer-cursor-y vbuffer)))

    ;; 4. Test CSI sequences (on a clean buffer)
    (clear-buffer vbuffer)
    (is (= 0 (vbuffer-cursor-x vbuffer)))
    (is (= 0 (vbuffer-cursor-y vbuffer)))
    ;; Move cursor to 10, 5
    (process-output-stream vbuffer (format nil "~c[11;6H" #\Escape))
    (is (= 10 (vbuffer-cursor-y vbuffer)))
    (is (= 5 (vbuffer-cursor-x vbuffer)))
    ;; Move cursor up by 2
    (process-output-stream vbuffer (format nil "~c[2A" #\Escape))
    (is (= 8 (vbuffer-cursor-y vbuffer)))
    ;; Move cursor down by 3
    (process-output-stream vbuffer (format nil "~c[3B" #\Escape))
    (is (= 11 (vbuffer-cursor-y vbuffer)))
    ;; Move cursor forward by 5
    (process-output-stream vbuffer (format nil "~c[5C" #\Escape))
    (is (= 10 (vbuffer-cursor-x vbuffer)))
    ;; Move cursor backward by 4
    (process-output-stream vbuffer (format nil "~c[4D" #\Escape))
    (is (= 6 (vbuffer-cursor-x vbuffer)))
    ;; Clear screen
    (process-output-stream vbuffer "X") ; Place a character to check for clearing
    (is (char= #\X (vcell-char (aref (vbuffer-grid vbuffer) 11 6))))
    (process-output-stream vbuffer (format nil "~c[2J" #\Escape))
    (is (char= #\Space (vcell-char (aref (vbuffer-grid vbuffer) 11 6))))
    (is (= 0 (vbuffer-cursor-x vbuffer)))
    (is (= 0 (vbuffer-cursor-y vbuffer)))))
