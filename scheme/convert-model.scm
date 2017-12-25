(load "srfi1.scm")
(load "format-srfi-28.scm")
(load "format-srfi-48.scm")

(define MODEL-FILE "cube.3d")

; Splits a string str on the character ch.
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

; Reads in an .obj file.
(define load-wavefront-obj
  (lambda (filename)
    (define file-port (open-input-file filename))
    (let ((raw-model-data (read-all file-port read-line)))
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

(define load-raw-data (lambda (filename) (load-wavefront-obj filename)))
(define str-split-on-spaces (lambda (str) (str-split str (integer->char 32))))
(define str-split-on-slashes (lambda (str) (str-split str #\/)))

(define filter-list-for-vertices (filter line-is-vertex (load-raw-data MODEL-FILE)))
(define filter-list-for-faces (filter line-is-face (load-raw-data MODEL-FILE)))

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

(define vertex-list
  (map
   (lambda (element) (cdr (convert-elements-to-numbers (str-split-on-spaces element))))
   filter-list-for-vertices))

(define face-list
  (map
   (lambda (element) (cdr (str-split-on-spaces element)))
   filter-list-for-faces))

; Given a list of faces and a list of vertexes, produce a list of triangle coordinates for the whole mesh.
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

;;;(pretty-print (get-faces face-list))
;;;(pretty-print vertex-list)

(define convert-number-to-32bit-fixed
  (lambda (number)
  (bitwise-ior
   (arithmetic-shift (inexact->exact (floor number)) 16)
   (inexact->exact (* 65536 (- number (floor number)))))))

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
	   

(define model-mesh (get-triangle-mesh face-list vertex-list))

;;; (pretty-print model-mesh)
(pretty-print (convert-mesh-to-32bit-fixed model-mesh))
