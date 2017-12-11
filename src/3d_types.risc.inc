;;; C: struct shape_t
SHAPE_START			.equ	0
SHAPE_TRANSLATION	.equ	0	; Vector3FX
SHAPE_ROTATION		.equ	12	; Vector3FX
SHAPE_SCALE			.equ	24	; Vector3FX
SHAPE_TRIANGLES		.equ	36	; Vector3FX **
SHAPE_SIZE			.equ	40
;;;

;;; C: struct vector3fx_t
VECTOR3FX_START		.equ	0
VECTOR3FX_X			.equ	4
VECTOR3FX_Y			.equ	8
VECTOR3FX_Z			.equ	12
VECTOR3FX_SIZE		.equ	16

;;; C: struct vector4fx_t
VECTOR4FX_START		.equ	0
VECTOR4FX_X			.equ	4
VECTOR4FX_Y			.equ	8
VECTOR4FX_Z			.equ	12
VECTOR4FX_W			.equ	16
VECTOR4FX_SIZE		.equ	20