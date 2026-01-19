(in-package #:lto-phase1)

;;; Virtual Cell (vcell) Definition
(defstruct vcell
  "Represents a single cell in the virtual terminal grid.
Each cell holds a character and its display attributes, such as foreground and
background colors."
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
  (:documentation "Manages the state of the virtual terminal.

This class encapsulates the grid of characters (vcells), the dimensions of the
terminal, and the cursor position."))

(defun make-vbuffer (width height)
  "Creates and returns a new vbuffer instance."
  (make-instance 'vbuffer :width width :height height))

(defmethod initialize-instance :after ((buffer vbuffer) &key)
  "Post-initialization method for the vbuffer class.
This method is called automatically after a new vbuffer instance is created.
It initializes the character grid, ensuring that each cell contains a fresh
vcell object."
  (setf (vbuffer-grid buffer)
        (make-array (list (vbuffer-height buffer) (vbuffer-width buffer))))
  (loop for y from 0 below (vbuffer-height buffer)
        do (loop for x from 0 below (vbuffer-width buffer)
                 do (setf (aref (vbuffer-grid buffer) y x) (make-vcell)))))

;;; VTE Inspection and Manipulation API

(defun get-line-text (vbuffer line-number)
  "Extracts and returns the text from a specific line in the vbuffer.
Args:
  vbuffer: The vbuffer instance to read from.
  line-number: The integer index of the line to extract.
Returns:
  A string containing the characters of the specified line, with leading/trailing whitespace removed."
  (let ((line-text (make-string (vbuffer-width vbuffer))))
    (loop for x from 0 below (vbuffer-width vbuffer)
          do (setf (char line-text x)
                   (vcell-char (aref (vbuffer-grid vbuffer) line-number x))))
    (string-trim '(#\Space) line-text)))

(defun find-string-in-buffer (vbuffer target-string)
  "Finds the first occurrence of a string in the buffer.
This function scans the buffer line by line.
Args:
  vbuffer: The vbuffer instance to search in.
  target-string: The string to find.
Returns:
  A list containing the (x, y) coordinates of the start of the string,
or nil if the string is not found."
  (loop for y from 0 below (vbuffer-height vbuffer)
        do (let ((line-text (get-line-text vbuffer y)))
             (let ((x (search target-string line-text)))
               (when x
                 (return-from find-string-in-buffer (list x y))))))
  nil)

(defun clear-buffer (vbuffer)
  "Resets the entire vbuffer to its default state.
This involves replacing every cell with a new default vcell and resetting the
cursor position to (0, 0)."
  (loop for y from 0 below (vbuffer-height vbuffer)
        do (loop for x from 0 below (vbuffer-width vbuffer)
                 do (setf (aref (vbuffer-grid vbuffer) y x) (make-vcell))))
  (setf (vbuffer-cursor-x vbuffer) 0)
  (setf (vbuffer-cursor-y vbuffer) 0))
