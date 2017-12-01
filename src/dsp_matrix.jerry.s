	;;  jump condition codes
	;;    %00000:   T    always
	;;    %00100:   CC   carry clear (less than)
	;;    %01000:   CS   carry set   (greater or equal)
	;;    %00010:   EQ   zero set (equal)
	;;    %00001:   NE   zero clear (not equal)
	;;    %11000:   MI   negative set
	;;    %10100:   PL   negative clear
	;;    %00101:   HI   greater than

	.section text
	
	.include "jaguar.inc"
	.globl  _jag_vidmem
	.globl  _scanline_offset_table

	.globl	_mvp_matrix
	.globl	_mvp_vector
	.globl	_mvp_result

	.include "regmacros.inc"

	.dsp
	SIZE_UINT32	.equ	4 ;bytes
	
;;; Global registers for these functions
	PTR_INDEX	.equr	r14 ;index into whatever register we're accessing
	
	PTR_MATRIX_1	.equr	r26 ;pointer to Matrix 1
	PTR_MATRIX_2	.equr	r27 ;pointer to Matrix 2
	PTR_MATRIX_R	.equr	r28 ;pointer to result matrix

;;; Global register defines
	PTR_MATRIX	.equr	r29
	
	FIXED_ONE	.equr	r30
	FIXED_ZERO	.equr	r31
	
;;; ;;;;;;;;;;;;;;;;
;;; DSP matrix functions
	.globl 	_dsp_matrix_ptr_m1
	.globl	_dsp_matrix_ptr_m2

_dsp_matrix_functions::

	.dsp
	.org    $F1B000
_dsp_matrix_functions_start::
	
	.phrase
_dsp_matrix_identity_set::
	.dsp

	movei	#_dsp_matrix_ptr_m1,TEMP1
	load	(TEMP1),PTR_MATRIX_1

	moveq	#000000000,TEMP1
	movei	#$00010000,TEMP2 ;fixed-point: 1.0

	;; Row 0
	movei	#SIZE_UINT32*0,PTR_INDEX
	store	TEMP2,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*1,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*2,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*3,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	;; Row 1
	movei	#SIZE_UINT32*4,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*5,PTR_INDEX
	store	TEMP2,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*6,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*7,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	;; Row 2
	movei	#SIZE_UINT32*8,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*9,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*10,PTR_INDEX
	store	TEMP2,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*11,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)
	
	;; Row 3
	movei	#SIZE_UINT32*12,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*13,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*14,PTR_INDEX
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	movei	#SIZE_UINT32*15,PTR_INDEX
	store	TEMP2,(PTR_INDEX+PTR_MATRIX_1)
	
	StopDSP
	nop

_dsp_matrix_identity_set_end::

	.dsp
;;; Zero out the matrix at dsp_matrix_ptr_m1
	.phrase
_dsp_matrix_zero::
	LoadValue _dsp_matrix_ptr_m1,PTR_MATRIX_1

	movei	#0,TEMP1

	movei	#0,LOOPCOUNTER
	movei	#16,LOOPEND
	movei	#.zero_loop,JUMPADDR

	movei	#SIZE_UINT32*0,PTR_INDEX
	
.zero_loop:
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_1)

	addq	#SIZE_UINT32,PTR_INDEX

	cmpq	#15,LOOPCOUNTER
	jr	ne,.zero_loop	;if LOOPCOUNTER < 15, loop.
	addq	#1,LOOPCOUNTER

	StopDSP
	nop

_dsp_matrix_zero_end::

	.dsp
;;; Add the matrices in operand_1 and operand_2, store the result
	.phrase
_dsp_matrix_add::
	movei	#0,LOOPCOUNTER
	movei	#16,LOOPEND
	movei	#.addition_loop,JUMPADDR
	
	movei	#_dsp_matrix_operand_1,PTR_MATRIX_1
	movei	#_dsp_matrix_operand_2,PTR_MATRIX_2
	movei	#_dsp_matrix_result,PTR_MATRIX_R

	movei	#SIZE_UINT32*0,PTR_INDEX

.addition_loop:
	load	(PTR_INDEX+PTR_MATRIX_1),TEMP1
	load	(PTR_INDEX+PTR_MATRIX_2),TEMP2
	add	TEMP1,TEMP2
	store	TEMP2,(PTR_INDEX+PTR_MATRIX_R)

	addq	#SIZE_UINT32,PTR_INDEX

	cmpq	#15,LOOPCOUNTER
	jr	ne,.addition_loop ;if LOOPCOUNTER < 15, loop.
	addq	#1,LOOPCOUNTER
	
	StopDSP
	nop

_dsp_matrix_add_end::

	.dsp
	.phrase
_dsp_matrix_sub::
	movei	#0,LOOPCOUNTER
	movei	#16,LOOPEND
	movei	#.subtraction_loop,JUMPADDR
	
	movei	#_dsp_matrix_operand_1,PTR_MATRIX_1
	movei	#_dsp_matrix_operand_2,PTR_MATRIX_2
	movei	#_dsp_matrix_result,PTR_MATRIX_R

	movei	#SIZE_UINT32*0,PTR_INDEX

.subtraction_loop:
	load	(PTR_INDEX+PTR_MATRIX_1),TEMP1
	load	(PTR_INDEX+PTR_MATRIX_2),TEMP2
	sub	TEMP2,TEMP1
	store	TEMP1,(PTR_INDEX+PTR_MATRIX_R)

	addq	#SIZE_UINT32,PTR_INDEX

	cmpq	#15,LOOPCOUNTER
	jr	ne,.subtraction_loop ;if LOOPCOUNTER < 15, loop.
	addq	#1,LOOPCOUNTER
	
	StopDSP
	nop

_dsp_matrix_sub_end::

	.phrase
;;; Translation.
_dsp_matrix_translation::
	PTR_TRANSLATION	.equr	r10
	TRANS_X		.equr	r11
	TRANS_Y		.equr	r12
	TRANS_Z		.equr	r13
	
	movei	#$00010000,FIXED_ONE
	movei	#$00000000,FIXED_ZERO

	movei	#_dsp_matrix_ptr_result,PTR_MATRIX
	load	(PTR_MATRIX),PTR_MATRIX	;dereference the pointer
	
	movei	#_dsp_matrix_vector,PTR_TRANSLATION
	load	(PTR_TRANSLATION),TRANS_X
	addq	#4,PTR_TRANSLATION
	load	(PTR_TRANSLATION),TRANS_Y
	addq	#4,PTR_TRANSLATION
	load	(PTR_TRANSLATION),TRANS_Z
	
.set_matrix_values:
	store	FIXED_ONE,(PTR_MATRIX) 	;[0][0]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX)	;[0][1]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX)	;[0][2]
	addq	#4,PTR_MATRIX
	store	TRANS_X,(PTR_MATRIX)	;[0][3]

	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[1][0]
	addq	#4,PTR_MATRIX
	store	FIXED_ONE,(PTR_MATRIX)  ;[1][1]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[1][2]
	addq	#4,PTR_MATRIX
	store	TRANS_Y,(PTR_MATRIX)    ;[1][3]

	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[2][0]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[2][1]
	addq	#4,PTR_MATRIX
	store	FIXED_ONE,(PTR_MATRIX)  ;[2][2]
	addq	#4,PTR_MATRIX
	store	TRANS_Z,(PTR_MATRIX)	;[2][3]

	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[3][0]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[3][1]
	addq	#4,PTR_MATRIX
	store	FIXED_ZERO,(PTR_MATRIX) ;[3][2]
	addq	#4,PTR_MATRIX
	store	FIXED_ONE,(PTR_MATRIX) 	;[3][3]
	
	StopDSP
	nop
_dsp_matrix_translation_end::

	;; Rotation matrix construction.
	.dsp
	.macro	LoadTrigTables
	    movei	_FIXED_SINE_TABLE,TEMP1
	    move	TEMP1,SIN_TABLE

	    movei	_FIXED_COSINE_TABLE,TEMP1
	    move	TEMP1,COS_TABLE
	.endm
	
	PTR_ORIENTATION		.equr	r10
	DEGREES			.equr	r11

	PTR_MATRIX_ROT		.equr	r12

	MATRIX_OFFSET		.equr	r14
	TRIG_TABLE_OFFSET	.equr	r15

	FIXED_SIN		.equr	r16
	FIXED_COS		.equr	r17

	SIN_TABLE		.equr	r18
	COS_TABLE		.equr	r19

	SIN_DEGREES		.equr	r20
	COS_DEGREES		.equr	r21

	X_DEGREES		.equr	r22
	Y_DEGREES		.equr	r23
	Z_DEGREES		.equr	r24

	SIN_X_DEGREES		.equr	r25
	COS_X_DEGREES		.equr	r26
	SIN_Y_DEGREES		.equr	r27
	COS_Y_DEGREES		.equr	r28
	SIN_Z_DEGREES		.equr	r29
	COS_Z_DEGREES		.equr	r30

	.phrase
_dsp_matrix_rotation::
	;; Build a rotation matrix for (X,Y,Z) degrees.
	DSP_REG_BANK_1
	movei	#stack_end,SP

	LoadTrigTables

	movei	#_dsp_matrix_ptr_result,PTR_MATRIX_ROT
	load	(PTR_MATRIX_ROT),PTR_MATRIX_ROT

	; Load the X,Y,Z degrees.
	movei	#_dsp_matrix_vector,TEMP1
	movei	#4,r14
	load	(TEMP1),X_DEGREES
	load	(r14+TEMP1),Y_DEGREES
	addq	#4,r14
	load	(r14+TEMP1),Z_DEGREES

.get_sin_X_cos_X:
	move	X_DEGREES,TRIG_TABLE_OFFSET
	shlq	#2,TRIG_TABLE_OFFSET ;trig table entries are 4 bytes long
	load	(TRIG_TABLE_OFFSET+SIN_TABLE),SIN_X_DEGREES
	load	(TRIG_TABLE_OFFSET+COS_TABLE),COS_X_DEGREES

.get_sin_Y_cos_Y:
	move	Y_DEGREES,TRIG_TABLE_OFFSET
	shlq	#2,TRIG_TABLE_OFFSET ;trig table entries are 4 bytes long
	load	(TRIG_TABLE_OFFSET+SIN_TABLE),SIN_Y_DEGREES
	load	(TRIG_TABLE_OFFSET+COS_TABLE),COS_Y_DEGREES

.get_sin_Z_cos_Z:
	move	Z_DEGREES,TRIG_TABLE_OFFSET
	shlq	#2,TRIG_TABLE_OFFSET ;trig table entries are 4 bytes long
	load	(TRIG_TABLE_OFFSET+SIN_TABLE),SIN_Z_DEGREES
	load	(TRIG_TABLE_OFFSET+COS_TABLE),COS_Z_DEGREES
	
	;; Row 0 Column 0 | FIXED_MUL(FIXED_COSINE_TABLE[xDeg], FIXED_COSINE_TABLE[yDeg]);
	move	COS_X_DEGREES,TEMP1 
	move	COS_Y_DEGREES,TEMP2
	DSP_JSR	FIXED_PRODUCT
	movei	#0,MATRIX_OFFSET
	store	TEMP1,(MATRIX_OFFSET+PTR_MATRIX_ROT)

	;; Row 0 Column 1 | (-(FIXED_MUL(FIXED_COSINE_TABLE[xDeg], FIXED_SINE_TABLE[zDeg]))) + (FIXED_MUL(FIXED_MUL(FIXED_SINE_TABLE[xDeg], FIXED_SINE_TABLE[yDeg]), FIXED_COSINE_TABLE[zDeg]));
	move	COS_X_DEGREES,TEMP1
	move	SIN_Y_DEGREES,TEMP2
	DSP_JSR	FIXED_PRODUCT
	move	SIN_Z_DEGREES,TEMP2
	DSP_JSR	FIXED_PRODUCT
	move	TEMP1,r13

	move	SIN_X_DEGREES,TEMP1
	move	COS_Z_DEGREES,TEMP2
	DSP_JSR	FIXED_PRODUCT
	move	r13,TEMP2
	sub	TEMP1,TEMP2 	; TEMP2 -= TEMP1
	
*	neg	TEMP1
*	add	r13,TEMP1
	movei	#4,MATRIX_OFFSET
	store	TEMP2,(MATRIX_OFFSET+PTR_MATRIX_ROT)	
*	store	TEMP1,(MATRIX_OFFSET+PTR_MATRIX_ROT)	
	
	;; Row 0 Column 2 | FIXED_MUL(FIXED_SINE_TABLE[xDeg], FIXED_SINE_TABLE[zDeg]) + (FIXED_MUL(FIXED_MUL(FIXED_COSINE_TABLE[xDeg], FIXED_SINE_TABLE[yDeg]), FIXED_COSINE_TABLE[zDeg]));
	move	COS_X_DEGREES,TEMP1 
	move	SIN_Y_DEGREES,TEMP2
	DSP_JSR	FIXED_PRODUCT	; result in TEMP1
	move	COS_Z_DEGREES,TEMP2
	DSP_JSR	FIXED_PRODUCT	; result in TEMP1
	move	TEMP1,r13	; temp storage

	move	SIN_X_DEGREES,TEMP1
	move	SIN_Z_DEGREES,TEMP2
	DSP_JSR	FIXED_PRODUCT	; result in TEMP1

	add	r13,TEMP1	; add two products together
	movei	#8,MATRIX_OFFSET
	store	TEMP1,(MATRIX_OFFSET+PTR_MATRIX_ROT)

	;; Row 1 Column 0 | FIXED_MUL(FIXED_COSINE_TABLE[yDeg], FIXED_SINE_TABLE[zDeg]);
	move	SIN_X_DEGREES,TEMP1
	move	COS_Y_DEGREES,TEMP2
	DSP_JSR	FIXED_PRODUCT
	movei	#16,MATRIX_OFFSET
	store	TEMP1,(MATRIX_OFFSET+PTR_MATRIX_ROT)

	;; Row 1 Column 1 | FIXED_MUL(FIXED_COSINE_TABLE[yDeg], FIXED_COSINE_TABLE[zDeg]) + (FIXED_MUL(FIXED_MUL(FIXED_SINE_TABLE[xDeg], FIXED_SINE_TABLE[yDeg]), FIXED_SINE_TABLE[zDeg]));
	move	SIN_X_DEGREES,TEMP1
	move	SIN_Y_DEGREES,TEMP2
	DSP_JSR	FIXED_PRODUCT	; result in TEMP1
	move	SIN_Z_DEGREES,TEMP2
	DSP_JSR	FIXED_PRODUCT
	move	TEMP1,r13

	move	COS_X_DEGREES,TEMP1
	move	COS_Z_DEGREES,TEMP2
	DSP_JSR	FIXED_PRODUCT

	add	r13,TEMP1
	movei	#20,MATRIX_OFFSET
	store	TEMP1,(MATRIX_OFFSET+PTR_MATRIX_ROT)

	;; Row 1 Column 2 | (-(FIXED_MUL(FIXED_SINE_TABLE[xDeg], FIXED_COSINE_TABLE[zDeg]))) + (FIXED_MUL(FIXED_MUL(FIXED_COSINE_TABLE[xDeg], FIXED_SINE_TABLE[yDeg]), FIXED_SINE_TABLE[zDeg]));
	move	SIN_X_DEGREES,TEMP1
	move	SIN_Y_DEGREES,TEMP2
	DSP_JSR	FIXED_PRODUCT
	move	COS_Z_DEGREES,TEMP2
	DSP_JSR	FIXED_PRODUCT
	move	TEMP1,r13

	move	COS_X_DEGREES,TEMP1
	move	SIN_Z_DEGREES,TEMP2
	DSP_JSR	FIXED_PRODUCT
	move	r13,TEMP2
	sub	TEMP1,TEMP2
	
*	neg	TEMP1
*	add	r13,TEMP1
	movei	#24,MATRIX_OFFSET
*	store	TEMP1,(MATRIX_OFFSET+PTR_MATRIX_ROT)
	store	TEMP2,(MATRIX_OFFSET+PTR_MATRIX_ROT)
	
	;; Row 2 Column 0 | -(FIXED_SINE_TABLE[yDeg])
	move	SIN_Y_DEGREES,TEMP1
	neg	TEMP1
	movei	#32,MATRIX_OFFSET
	store	TEMP1,(MATRIX_OFFSET+PTR_MATRIX_ROT)

	;; Row 2 Column 1 | FIXED_MUL(FIXED_SINE_TABLE[xDeg],   FIXED_COSINE_TABLE[yDeg]);
	move	COS_Y_DEGREES,TEMP1
	move	SIN_Z_DEGREES,TEMP2
	DSP_JSR	FIXED_PRODUCT
	movei	#36,MATRIX_OFFSET
	store	TEMP1,(MATRIX_OFFSET+PTR_MATRIX_ROT)

	;; Row 2 Column 2 | FIXED_MUL(FIXED_COSINE_TABLE[xDeg], FIXED_COSINE_TABLE[yDeg]);
	move	COS_Y_DEGREES,TEMP1
	move	COS_Z_DEGREES,TEMP2
	DSP_JSR	FIXED_PRODUCT
	movei	#40,MATRIX_OFFSET
	store	TEMP1,(MATRIX_OFFSET+PTR_MATRIX_ROT)

	movei	#$00000000,TEMP1
	movei	#$00010000,TEMP2
	movei	#12,MATRIX_OFFSET
	store	TEMP1,(MATRIX_OFFSET+PTR_MATRIX_ROT)
	movei	#28,MATRIX_OFFSET
	store	TEMP1,(MATRIX_OFFSET+PTR_MATRIX_ROT)
	movei	#44,MATRIX_OFFSET
	store	TEMP1,(MATRIX_OFFSET+PTR_MATRIX_ROT)
	movei	#48,MATRIX_OFFSET
	store	TEMP1,(MATRIX_OFFSET+PTR_MATRIX_ROT)
	movei	#52,MATRIX_OFFSET
	store	TEMP1,(MATRIX_OFFSET+PTR_MATRIX_ROT)
	movei	#56,MATRIX_OFFSET
	store	TEMP1,(MATRIX_OFFSET+PTR_MATRIX_ROT)
	movei	#60,MATRIX_OFFSET
	store	TEMP2,(MATRIX_OFFSET+PTR_MATRIX_ROT)

.abort:
	DSP_REG_BANK_0
	StopDSP
	nop
_dsp_matrix_rotation_end::
	
	.phrase
_dsp_matrix_copy::
	.globl	_M_CopySource
	.globl	_M_CopyDestination
	
	movei	#_M_CopySource,r10
	movei	#_M_CopyDestination,r11
	load	(r10),r10
	load	(r11),r11
	movei	#0,r14
	movei	#16,LOOPCOUNTER
	
.dsp_matrix_copy_loop:
	load	(r14+r10),r12
	store	r12,(r14+r11)
	addq	#4,r14
	subq	#1,LOOPCOUNTER
	cmpq	#0,LOOPCOUNTER
	jr	ne,.dsp_matrix_copy_loop
	nop
	
	StopDSP
	nop
_dsp_matrix_copy_end::

	.phrase
_dsp_matrix_vector_product::
	DSP_REG_BANK_1
	
	MV_MATRIX		.equr	r10
	MV_VECTOR		.equr	r11
	MV_RESULT		.equr	r12
	MV_MATRIX_OFFSET	.equr	r14
	MV_RESULT_OFFSET	.equr	r15
	MV_ACCUMULATOR		.equr	r16
	
	movei	#_mvp_result,MV_RESULT
	movei	#_mvp_matrix,MV_MATRIX
	movei	#_mvp_vector,MV_VECTOR

	move	MV_MATRIX,r5
	move	MV_VECTOR,r6
	move	MV_RESULT,r7

	load	(MV_RESULT),MV_RESULT
	load	(MV_MATRIX),MV_MATRIX
	load	(MV_VECTOR),MV_VECTOR

	or	MV_RESULT,MV_RESULT
	or	MV_MATRIX,MV_MATRIX
	or	MV_VECTOR,MV_VECTOR

	movei	#0,MV_MATRIX_OFFSET
	movei	#0,MV_RESULT_OFFSET

	movei	#stack_end,SP

.calculate_x:
	load	(MV_MATRIX_OFFSET+MV_MATRIX),TEMP1
	load	(MV_VECTOR),TEMP2
	DSP_JSR	FIXED_PRODUCT	; matrix->data[0][0] * vector->x
	move	TEMP1,MV_ACCUMULATOR

	addq	#4,MV_MATRIX_OFFSET
	addq	#4,MV_VECTOR
	load	(MV_MATRIX_OFFSET+MV_MATRIX),TEMP1
	load	(MV_VECTOR),TEMP2
	DSP_JSR FIXED_PRODUCT	; matrix->data[0][1] * vector->y
	add	TEMP1,MV_ACCUMULATOR

	addq	#4,MV_MATRIX_OFFSET
	addq	#4,MV_VECTOR
	load	(MV_MATRIX_OFFSET+MV_MATRIX),TEMP1
	load	(MV_VECTOR),TEMP2
	DSP_JSR FIXED_PRODUCT	; matrix->data[0][2] * vector->z
	add	TEMP1,MV_ACCUMULATOR

	addq	#4,MV_MATRIX_OFFSET
	load	(MV_MATRIX_OFFSET+MV_MATRIX),TEMP1
	add	TEMP1,MV_ACCUMULATOR
	store	MV_ACCUMULATOR,(MV_RESULT)

	move	MV_ACCUMULATOR,r20

	addq	#4,MV_MATRIX_OFFSET
	addq	#4,MV_RESULT
	subq	#8,MV_VECTOR	; reset to vector->x
	
.calculate_y:
	load	(MV_MATRIX_OFFSET+MV_MATRIX),TEMP1
	load	(MV_VECTOR),TEMP2
	DSP_JSR	FIXED_PRODUCT	; matrix->data[1][0] * vector->x
	move	TEMP1,MV_ACCUMULATOR

	addq	#4,MV_MATRIX_OFFSET
	addq	#4,MV_VECTOR
	load	(MV_MATRIX_OFFSET+MV_MATRIX),TEMP1
	load	(MV_VECTOR),TEMP2
	DSP_JSR FIXED_PRODUCT	; matrix->data[1][1] * vector->y
	add	TEMP1,MV_ACCUMULATOR

	addq	#4,MV_MATRIX_OFFSET
	addq	#4,MV_VECTOR
	load	(MV_MATRIX_OFFSET+MV_MATRIX),TEMP1
	load	(MV_VECTOR),TEMP2
	DSP_JSR FIXED_PRODUCT	; matrix->data[1][2] * vector->z
	add	TEMP1,MV_ACCUMULATOR

	addq	#4,MV_MATRIX_OFFSET
	load	(MV_MATRIX_OFFSET+MV_MATRIX),TEMP1
	add	TEMP1,MV_ACCUMULATOR
	store	MV_ACCUMULATOR,(MV_RESULT)

	move	MV_ACCUMULATOR,r21

	addq	#4,MV_MATRIX_OFFSET
	addq	#4,MV_RESULT
	subq	#8,MV_VECTOR	; reset to vector->x

.calculate_z:
	load	(MV_MATRIX_OFFSET+MV_MATRIX),TEMP1
	load	(MV_VECTOR),TEMP2
	DSP_JSR	FIXED_PRODUCT	; matrix->data[1][0] * vector->x
	move	TEMP1,MV_ACCUMULATOR

	addq	#4,MV_MATRIX_OFFSET
	addq	#4,MV_VECTOR
	load	(MV_MATRIX_OFFSET+MV_MATRIX),TEMP1
	load	(MV_VECTOR),TEMP2
	DSP_JSR FIXED_PRODUCT	; matrix->data[1][1] * vector->y
	add	TEMP1,MV_ACCUMULATOR

	addq	#4,MV_MATRIX_OFFSET
	addq	#4,MV_VECTOR
	load	(MV_MATRIX_OFFSET+MV_MATRIX),TEMP1
	load	(MV_VECTOR),TEMP2
	DSP_JSR FIXED_PRODUCT	; matrix->data[1][2] * vector->z
	add	TEMP1,MV_ACCUMULATOR

	addq	#4,MV_MATRIX_OFFSET
	load	(MV_MATRIX_OFFSET+MV_MATRIX),TEMP1
	add	TEMP1,MV_ACCUMULATOR
	store	MV_ACCUMULATOR,(MV_RESULT)

	move	MV_ACCUMULATOR,r22

	StopDSP
	nop
	
_dsp_matrix_vector_product_end::

	.phrase
FIXED_PRODUCT:
	movei   #D_FLAGS,r4       ; Status flags
	load    (r4),r3
	bclr    #14,r3
	store   r3,(r4)           ; Switch the GPU/DSP to bank 0	
			
	;; Subroutine that multiplies two fixed-point numbers TEMP1 and TEMP2.
	;; Result is returned in TEMP1.
	FP_A     		.equr   r2
	FP_B     		.equr   r3
	FIXED_PRODUCT_RESULT    .equr   r4
	LOWORD_MASK		.equr 	r5

	FP_STEP1_OPERAND_1	.equr	r20
	FP_STEP1_OPERAND_2	.equr	r21
	FP_STEP2_OPERAND_1	.equr	r22
	FP_STEP2_OPERAND_2	.equr	r23
	FP_STEP3_OPERAND_1	.equr	r24
	FP_STEP3_OPERAND_2	.equr	r25
	FP_STEP4_OPERAND_1	.equr	r26
	FP_STEP4_OPERAND_2	.equr	r27
	FP_STEP5_OPERAND_1	.equr	r28
	FP_STEP5_OPERAND_2	.equr	r29
	FP_STEP6_OPERAND_1	.equr	r30
	FP_STEP6_OPERAND_2	.equr	r31
	
	movei   #$0000FFFF,LOWORD_MASK
	movei   #0,FIXED_PRODUCT_RESULT

	movefa	TEMP1,FP_A
	movefa	TEMP2,FP_B
	
	;; Step 1: A.i * B.f
	move	FP_A,FP_STEP1_OPERAND_1
	move	FP_B,FP_STEP1_OPERAND_2
	shrq	#16,FP_STEP1_OPERAND_1
	and	LOWORD_MASK,FP_STEP1_OPERAND_2
	mult	FP_STEP1_OPERAND_1,FP_STEP1_OPERAND_2
	
	;; Step 2: A.f * B.i
	move  	FP_A,FP_STEP2_OPERAND_1
	move  	FP_B,FP_STEP2_OPERAND_2
	and     LOWORD_MASK,FP_STEP2_OPERAND_1
	shrq    #16,FP_STEP2_OPERAND_2
	mult    FP_STEP2_OPERAND_1,FP_STEP2_OPERAND_2

	;; Pipeline step 1
	add	FP_STEP1_OPERAND_2,FIXED_PRODUCT_RESULT
	
	;; Step 3: (A.i * B.i) << 16
	move	FP_A,FP_STEP3_OPERAND_1
	move  	FP_B,FP_STEP3_OPERAND_2
	shrq    #16,FP_STEP3_OPERAND_1
	shrq    #16,FP_STEP3_OPERAND_2
	mult    FP_STEP3_OPERAND_1,FP_STEP3_OPERAND_2
	shlq    #16,FP_STEP3_OPERAND_2

	;; Pipeline step 2
	add     FP_STEP2_OPERAND_2,FIXED_PRODUCT_RESULT
	
	;; Step 4: (A.f * B.f) >> 16
	move  	FP_A,FP_STEP4_OPERAND_1
	move  	FP_B,FP_STEP4_OPERAND_2
	and     LOWORD_MASK,FP_STEP4_OPERAND_1
	and     LOWORD_MASK,FP_STEP4_OPERAND_2
	mult    FP_STEP4_OPERAND_1,FP_STEP4_OPERAND_2
	shrq    #16,FP_STEP4_OPERAND_2

	;; Pipeline step 3
	add     FP_STEP3_OPERAND_2,FIXED_PRODUCT_RESULT
	
.neg_a_check:           ; Is A negative? Add (-B.f) << 16 if so.
	move  	FP_A,FP_STEP5_OPERAND_1
	move	FP_B,FP_STEP5_OPERAND_2
	and     LOWORD_MASK,FP_STEP5_OPERAND_2 ; get B.f
	btst    #31,FP_STEP5_OPERAND_1 ; is A a negative number?
	jr      eq,.neg_b_check
	
	neg     FP_STEP5_OPERAND_2
	shlq    #16,FP_STEP5_OPERAND_2
	add     FP_STEP5_OPERAND_2,FIXED_PRODUCT_RESULT

.neg_b_check:           ; Is B negative? Add (-A.f) << 16 if so.
	move 	FP_A,FP_STEP6_OPERAND_1
	move	FP_B,FP_STEP6_OPERAND_2
	and     LOWORD_MASK,FP_STEP6_OPERAND_1 ; get A.f
	btst    #31,FP_STEP6_OPERAND_2 ; is B a negative number?
	jr      eq,.accumulate
	
	neg     FP_STEP6_OPERAND_1
	shlq    #16,FP_STEP6_OPERAND_1
	add     FP_STEP6_OPERAND_1,FIXED_PRODUCT_RESULT

.accumulate:
	add     FP_STEP4_OPERAND_2,FIXED_PRODUCT_RESULT 
	
.done:	
	DSP_REG_BANK_1
	movefa    FIXED_PRODUCT_RESULT,TEMP1
	DSP_RTS
	
_dsp_matrix_functions_end::
		
	.long
stack:	dcb.l	16,$00000000
stack_end:
	
	;; Operands for matrix functions
	.phrase
_dsp_matrix_operand_1::	dcb.l	16,$AA55AA55 ;operand 1
	.phrase
_dsp_matrix_operand_2:: dcb.l	16,$AA55AA55 ;operand 2
	.phrase
_dsp_matrix_result::	dcb.l	16,$AA55AA55 ;result matrix
	.phrase
_dsp_matrix_vector::	dcb.l	3,$11223344  ;matrix/vector product storage

	.long
_dsp_matrix_ptr_result::dcb.l	1,$00000000  ;pointer to the matrix we want to write the result to

	;; Operands for vector functions
	.long
_dsp_vector_operand_1:: dcb.l	3,$11223344 ;vector operand 1
	.long
_dsp_vector_operand_2:: dcb.l	3,$11223344 ;vector operand 2
	.long
_dsp_vector_result::	dcb.l	3,$11223344 ;vector result

	;; Constants
	.long
CONST_MATRIX_IDENTITY:
	dc.l	$00010000,$00000000,$00000000,$00000000
	dc.l	$00000000,$00010000,$00000000,$00000000
	dc.l	$00000000,$00000000,$00010000,$00000000
	dc.l	$00000000,$00000000,$00000000,$00010000
	
	.68000
	
