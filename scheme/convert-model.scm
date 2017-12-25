(load "lib/srfi1.scm") ; filter
(load "lib/format-srfi-28.scm") ; basic format
(load "lib/format-srfi-48.scm") ; intermediate format

(define MODEL-NAME "cube")
(define MODEL-FILENAME (format "input/~a.obj" MODEL-NAME))
(define OUTPUT-FILENAME (format "output/model_~a.asm" MODEL-NAME))

; Splits a string str on the character ch. Stolen from Snack Overflow.
(define (str-split str ch)
  (let ((len (string-length str)))
    (letrec
	((split
	  (lambda (a b)
	    (cond
	     ((>= b len) (if (= a b) '() (cons (substring str a b) '())))
	     ((char=? ch (string-ref str b)) (if (= a b)
						 (split (+ 1 a) (+ 1 b))
						 (cons (substring str a b) (split b b))))
	     (else (split a (+ 1 b)))))))
      (split 0 0))))

;;; Reads in an .obj file.
(define load-raw-data (lambda (filename) (load-wavefront-obj filename)))
(define load-wavefront-obj
  (lambda (filename)
    (let ((raw-model-data (read-all (open-input-file filename) read-line)))
      raw-model-data
      )
    )
  )

; Does this line begin with "v"?
(define line-is-vertex (lambda (line)
			 (string=? (list-ref (str-split line (integer->char 32)) 0) "v")))
; Does this line begin with "f"?
(define line-is-face (lambda (line)
		       (string=? (list-ref (str-split line (integer->char 32)) 0) "f")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define str-split-on-spaces (lambda (str) (str-split str (integer->char 32))))
(define str-split-on-slashes (lambda (str) (str-split str #\/)))

(define filter-list-for-vertices (filter line-is-vertex (load-raw-data MODEL-FILENAME)))
(define filter-list-for-faces (filter line-is-face (load-raw-data MODEL-FILENAME)))

;;; The file we read produces lists of strings. Turn these into numbers.
(define convert-elements-to-numbers
  (lambda (elements)
    (map
     (lambda (element)
       (string->number element))
     elements)))

;;; Create a list from the first element of the "f" entries.
;;; This is the model's triangle mesh.
(define get-faces
  (lambda (element)
     (map
      (lambda (triangle)
        (map
	 (lambda (vertex)
	   (string->number (car (str-split-on-slashes vertex))))
	 triangle))
      element)))

;;; Filter out everything from the model file except for the vertices.
(define vertex-list
  (map
   (lambda (element) (cdr (convert-elements-to-numbers (str-split-on-spaces element))))
   filter-list-for-vertices))

;;; Filter out everything from the model file except for the faces.
(define face-list
  (map
   (lambda (element) (cdr (str-split-on-spaces element)))
   filter-list-for-faces))

;;; Given a list of faces and a list of vertexes, produce the model's list of triangles.
(define get-triangle-mesh
  (lambda (faces vertexes)
    (map
     (lambda (triangle)
       (map
	(lambda (vertex)
	  (let ((zero-indexed-vertex (- vertex 1)))
	    (list-ref vertexes zero-indexed-vertex)))
	triangle))
     (get-faces faces))))

;;; Converts a Number to a signed 32-bit fixed-point number.
;;; TODO: bounds checking
(define convert-number-to-32bit-fixed
  (lambda (number)
  (bitwise-ior
   (arithmetic-shift (inexact->exact (floor number)) 16)
   (inexact->exact (* 65536 (- number (floor number)))))))

;;; Converts all points in the mesh to the fixed-point format.
(define convert-mesh-to-32bit-fixed
  (lambda (mesh)
    (map
     (lambda (triangle)
       (map
	(lambda (vertex)
	  (map
	   (lambda (coordinate)
	     (convert-number-to-32bit-fixed coordinate))
	   vertex))
	triangle))
     mesh)))

;;; Prints all points in the mesh as fixed-point numbers.
(define print-coordinates-as-32-bit-fixed
  (lambda (mesh)
    (let ((triangle-index 0))
      (map
       (lambda (triangle)
	 (display (format "MODEL_~a_triangle_~a:\n" MODEL-NAME triangle-index))
	 (set! triangle-index (+ triangle-index 1))
	 (map
	  (lambda (vertex)
	    (map
	     (lambda (coordinate)
	       (display (format "\tdc.l $~x\n" (convert-number-to-32bit-fixed coordinate))))
	     vertex)
	    (display (format "\n")))
	  triangle))
       mesh))))
  
(define model-mesh (get-triangle-mesh face-list vertex-list))

(define model-write-header
  (lambda (name mesh)
    (display (format "*** MODEL: ~a\n" name))
    (display (format "*** Triangles: ~a\n" (length mesh)))
    (display "**************************************************\n")))

(define model-write-xdefs
  (lambda (name)
    (display (format "\tXDEF _MODEL_~a\n" name))
    (display (format "\tXDEF _MODEL_~a_tri_count\n" name))
    (display (format "\tXDEF _MODEL_~a_tri_list\n" name))))

(define model-write-triangle-count
  (lambda ()
    (display (format "_MODEL_~a_tri_count:\n\tdc.l ~a\n\n" MODEL-NAME (length model-mesh)))))
     
(define model-write-triangle-pointers
  (lambda (model)
    (let ((triangle-index 0))
      (map
       (lambda (triangle)
	 (display (format "\tdc.l MODEL_~a_triangle_~a\n" MODEL-NAME triangle-index))
	 (set! triangle-index (+ triangle-index 1)))
       model))))

;;; Create the output file.
(with-output-to-file
    (list path: OUTPUT-FILENAME)
  (lambda ()
    (model-write-header MODEL-NAME model-mesh)
    (model-write-xdefs MODEL-NAME)
    (newline)
    (display "\teven\n")
    (model-write-triangle-count)
    (display (format "_MODEL_~a:\n" MODEL-NAME))
    (print-coordinates-as-32-bit-fixed model-mesh)
    (newline)
    (display (format "_MODEL_~a_tri_list:\n" MODEL-NAME))
    (model-write-triangle-pointers model-mesh)
    (newline)
    )
  ) 

(display (format "Model ~a converted to Motorola-format include file ~a.\n" MODEL-FILENAME OUTPUT-FILENAME))
