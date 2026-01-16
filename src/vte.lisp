(in-package #:lto-phase1)

;;; Virtual Cell (vcell) Definition
(defstruct vcell
  "Represents a single cell in the virtual terminal grid."
  (char #\Space :type character)
  (fg-color :default :type keyword)
  (bg-color :default :type keyword)
  (attributes '() :type list))

;;; Virtual Buffer (vbuffer) Class
(defclass vbuffer ()
  ((width :initarg :width :accessor vbuffer-width)
   (height :initarg :height :accessor vbuffer-height)
   (grid :accessor vbuffer-grid)
   (cursor-x :initform 0 :accessor vbuffer-cursor-x)
   (cursor-y :initform 0 :accessor vbuffer-cursor-y))
  (:documentation "Represents the state of the virtual terminal emulator."))

(defmethod initialize-instance :after ((buffer vbuffer) &key)
  "Initializes the grid with distinct vcell objects."
  (setf (vbuffer-grid buffer)
        (make-array (list (vbuffer-height buffer) (vbuffer-width buffer))))
  (loop for y from 0 below (vbuffer-height buffer)
        do (loop for x from 0 below (vbuffer-width buffer)
                 do (setf (aref (vbuffer-grid buffer) y x) (make-vcell)))))

;;; Global VTE Buffer Instance
(defvar *vbuffer* (make-instance 'vbuffer :width 80 :height 24)
  "The global instance of the virtual terminal buffer.")

;;; VTE Inspection API
(defun get-line-text (vbuffer line-number)
  "Returns a clean string of a specific line from the buffer."
  (let ((line-text (make-string (vbuffer-width vbuffer))))
    (loop for x from 0 below (vbuffer-width vbuffer)
          do (setf (char line-text x)
                   (vcell-char (aref (vbuffer-grid vbuffer) line-number x))))
    (string-trim '(#\Space) line-text)))

(defun find-string-in-buffer (vbuffer target-string)
  "Finds a string in the buffer and returns its starting coordinates (x, y)."
  (loop for y from 0 below (vbuffer-height vbuffer)
        do (let ((line-text (get-line-text vbuffer y)))
             (let ((x (search target-string line-text)))
               (when x
                 (return-from find-string-in-buffer (list x y))))))
  nil)

(defun clear-buffer (vbuffer)
  "Clears the entire vbuffer."
  (loop for y from 0 below (vbuffer-height vbuffer)
        do (loop for x from 0 below (vbuffer-width vbuffer)
                 do (setf (aref (vbuffer-grid vbuffer) y x) (make-vcell))))
  (setf (vbuffer-cursor-x vbuffer) 0)
  (setf (vbuffer-cursor-y vbuffer) 0))
