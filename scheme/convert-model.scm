(define load-wavefront-obj
  (lambda (filename)
    (define file-port (open-input-file filename))
    (define list-of-lines (list '()))

    ; Get one line and append it to list-of-lines.
    (let ((raw-model-data (read-all file-port read-line)))
      raw-model-data
      )
    )
  
  )

(define raw-data (load-wavefront-obj "cube.3d"))

(write raw-data)
(newline)
