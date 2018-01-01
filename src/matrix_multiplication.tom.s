;;; Matrix multiplication program for the Jaguar GPU.
;;; ABI: r0-r9 are volatile on function calls, r10-r30 should be preserved. r31 = stack pointer.
;;; TODO: Make all the routines compliant with this ABI.
	.section text
	
	.gpu
	.include "jaguar.inc"
	.include "regmacros.inc"
	.include "3d_types.risc.inc"

	.globl	_mTranslation
	.globl	_mRotation

	.globl	_m
	.globl	_mPerspective
	.globl	_mView
	.globl	_mModel

	.globl	_M_MultLeft
	.globl  _M_MultRight
	.globl  _M_MultResult
	
	.phrase
	;; Matrix multiplication.
	.macro MATRIX_MULT_AND_ACC	acc_num, offset_left, offset_right
	
	movei	#\offset_left,OFFSET_MATRIX_LEFT
	movei	#\offset_right,OFFSET_MATRIX_RIGHT

	GPU_JSR	FIXED_PRODUCT_MMULT
	add	TEMP1,MATRIX_ACCUMULATOR_\acc_num
	
	.endm

	.macro MATRIX_MULT_AND_ACC_ROW	acc_num, offset_left, offset_right
	
	movei	#\offset_left,OFFSET_MATRIX_LEFT
	movei	#\offset_right,OFFSET_MATRIX_RIGHT
	GPU_JSR	FIXED_PRODUCT_MMULT
	add	TEMP1,MATRIX_ACCUMULATOR_\acc_num

	addq	#4,OFFSET_MATRIX_LEFT
	addq	#16,OFFSET_MATRIX_RIGHT
	GPU_JSR	FIXED_PRODUCT_MMULT
	add	TEMP1,MATRIX_ACCUMULATOR_\acc_num

	addq	#4,OFFSET_MATRIX_LEFT
	addq	#16,OFFSET_MATRIX_RIGHT
	GPU_JSR	FIXED_PRODUCT_MMULT
	add	TEMP1,MATRIX_ACCUMULATOR_\acc_num

	addq	#4,OFFSET_MATRIX_LEFT
	addq	#16,OFFSET_MATRIX_RIGHT
	GPU_JSR	FIXED_PRODUCT_MMULT
	add	TEMP1,MATRIX_ACCUMULATOR_\acc_num
	
	.endm

	COPY_MATRIX_COPY_TEMP	.equr	r3
	COPY_MATRIX_COPY_ITER	.equr	r4
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.macro	COPY_MATRIX_FROM_POINTER_TO_ARRAY from, to	
	movei	\from,TEMP1
	movei	\to,TEMP2 ; this is an array so we just need the address
	load	(TEMP1),TEMP1	; dereference the matrix pointer to get the matrix address

	movei	#16,COPY_MATRIX_COPY_ITER

.matrix_copy_loop_\~:
	load	(TEMP1),COPY_MATRIX_COPY_TEMP
	store	COPY_MATRIX_COPY_TEMP,(TEMP2)
	subq	#1,COPY_MATRIX_COPY_ITER
	addq	#4,TEMP1
	addq	#4,TEMP2
	cmpq	#0,COPY_MATRIX_COPY_ITER
	jr	ne,.matrix_copy_loop_\~
	nop
	.endm

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.macro	COPY_MATRIX_FROM_ARRAY_TO_ARRAY from, to	
	movei	\from,TEMP1
	movei	\to,TEMP2 ; this is an array so we just need the address

	movei	#16,COPY_MATRIX_COPY_ITER

.matrix_copy_loop_\~:
	load	(TEMP1),COPY_MATRIX_COPY_TEMP
	store	COPY_MATRIX_COPY_TEMP,(TEMP2)
	subq	#1,COPY_MATRIX_COPY_ITER
	addq	#4,TEMP1
	addq	#4,TEMP2
	cmpq	#0,COPY_MATRIX_COPY_ITER
	jr	ne,.matrix_copy_loop_\~
	nop
	.endm

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.macro	COPY_MATRIX_FROM_POINTER_TO_POINTER from, to	
	movei	\from,TEMP1
	movei	\to,TEMP2 ;	
	load	(TEMP1),TEMP1	; dereference the matrix pointer to get the matrix address
	load	(TEMP2),TEMP2

	movei	#16,COPY_MATRIX_COPY_ITER

.matrix_copy_loop_\~:
	load	(TEMP1),COPY_MATRIX_COPY_TEMP
	store	COPY_MATRIX_COPY_TEMP,(TEMP2)
	subq	#1,COPY_MATRIX_COPY_ITER
	addq	#4,TEMP1
	addq	#4,TEMP2
	cmpq	#0,COPY_MATRIX_COPY_ITER
	jr	ne,.matrix_copy_loop_\~
	nop
	.endm

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.macro	COPY_MATRIX_FROM_ARRAY_TO_POINTER from, to	
	movei	\from,TEMP1
	movei	\to,TEMP2
	load	(TEMP2),TEMP2	; dereference the matrix pointer to get the matrix address

	movei	#16,COPY_MATRIX_COPY_ITER

.matrix_copy_loop_\~:
	load	(TEMP1),COPY_MATRIX_COPY_TEMP
	store	COPY_MATRIX_COPY_TEMP,(TEMP2)
	subq	#1,COPY_MATRIX_COPY_ITER
	addq	#4,TEMP1
	addq	#4,TEMP2
	cmpq	#0,COPY_MATRIX_COPY_ITER
	jr	ne,.matrix_copy_loop_\~
	nop
	.endm	
	
_gpu_matrix_multiply_program_start::
	.gpu
	.org    $F03000

_gpu_matrix_multiply::	
	;; Calculate gpu_matrix_operand_1 * gpu_matrix_operand_2
	;; Result is stored in gpu_matrix_result
	PTR_MATRIX_RESULT	.equr	r2
	PTR_MATRIX_LEFT		.equr	r3
	PTR_MATRIX_RIGHT	.equr	r4
	MATRIX_ACCUMULATOR_1	.equr	r5
	MATRIX_ACCUMULATOR_2	.equr	r6
	OFFSET_MATRIX_LEFT	.equr	r14
	OFFSET_MATRIX_RIGHT	.equr	r15

	STOP_GPU_AT_END		.equr	r30

	GPU_REG_BANK_1
	movei	#stack_bank_1_end,SP
	movei	#1,STOP_GPU_AT_END
	
	.phrase
_gpu_matrix_multiply_jsr_entry:
	
	PushReg	r14
	PushReg	r15
	PushReg	r30
	
	COPY_MATRIX_FROM_POINTER_TO_ARRAY	#_M_MultLeft,#_gpu_matrix_operand_1
	COPY_MATRIX_FROM_POINTER_TO_ARRAY	#_M_MultRight,#_gpu_matrix_operand_2

.fill_registers:
	movei	#_gpu_matrix_operand_1,PTR_MATRIX_LEFT
	movei	#_gpu_matrix_operand_2,PTR_MATRIX_RIGHT
	movei	#_gpu_matrix_result,PTR_MATRIX_RESULT
	
	;; Row 0 Column 0
.r0c0:	
	moveq	#0,MATRIX_ACCUMULATOR_1
	MATRIX_MULT_AND_ACC_ROW	1, 0, 0	 ; accumulator number, left byte offset, right byte offset
	store	MATRIX_ACCUMULATOR_1,(PTR_MATRIX_RESULT)
	
	;; Row 0 Column 1
.r0c1:
	moveq	#0,MATRIX_ACCUMULATOR_2
	MATRIX_MULT_AND_ACC_ROW	2, 0, 4	 ; accumulator number, left byte offset, right byte offset
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_2,(PTR_MATRIX_RESULT)

	;; Row 0 Column 2
.r0c2:
	moveq	#0,MATRIX_ACCUMULATOR_1
	MATRIX_MULT_AND_ACC_ROW	1, 0, 8	 ; accumulator number, left byte offset, right byte offset
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_1,(PTR_MATRIX_RESULT)
	
	;; Row 0 Column 3
.r0c3:
	moveq	#0,MATRIX_ACCUMULATOR_2
	MATRIX_MULT_AND_ACC_ROW	2, 0, 12 ; accumulator number, left byte offset, right byte offset
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_2,(PTR_MATRIX_RESULT)

	;; Row 1 Column 0
.r1c0:	
	moveq	#0,MATRIX_ACCUMULATOR_1
	MATRIX_MULT_AND_ACC_ROW	1, 16, 0 ; accumulator number, left byte offset, right byte offset
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_1,(PTR_MATRIX_RESULT)

	;; Row 1 Column 1
.r1c1:
	moveq	#0,MATRIX_ACCUMULATOR_2
	MATRIX_MULT_AND_ACC_ROW	2, 16, 4 ; accumulator number, left byte offset, right byte offset
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_2,(PTR_MATRIX_RESULT)

	;; Row 1 Column 2
.r1c2:
	moveq	#0,MATRIX_ACCUMULATOR_1
	MATRIX_MULT_AND_ACC_ROW	1, 16, 8 ; accumulator number, left byte offset, right byte offset
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_1,(PTR_MATRIX_RESULT)

	;; Row 1 Column 3
.r1c3:
	moveq	#0,MATRIX_ACCUMULATOR_2
	MATRIX_MULT_AND_ACC_ROW	2, 16, 12 ; accumulator number, left byte offset, right byte offset
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_2,(PTR_MATRIX_RESULT)

	;; Row 2 Column 0
.r2c0:	
	moveq	#0,MATRIX_ACCUMULATOR_1
	MATRIX_MULT_AND_ACC_ROW	1, 32, 0 ; accumulator number, left byte offset, right byte offset
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_1,(PTR_MATRIX_RESULT)

	;; Row 2 Column 1
.r2c1:
	moveq	#0,MATRIX_ACCUMULATOR_2
	MATRIX_MULT_AND_ACC_ROW	2, 32, 4 ; accumulator number, left byte offset, right byte offset
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_2,(PTR_MATRIX_RESULT)

	;; Row 2 Column 2
.r2c2:
	moveq	#0,MATRIX_ACCUMULATOR_1
	MATRIX_MULT_AND_ACC_ROW	1, 32, 8  ; accumulator number, left byte offset, right byte offset
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_1,(PTR_MATRIX_RESULT)

	;; Row 2 Column 3
.r2c3:
	moveq	#0,MATRIX_ACCUMULATOR_2
	MATRIX_MULT_AND_ACC_ROW	2, 32, 12 ; accumulator number, left byte offset, right byte offset
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_2,(PTR_MATRIX_RESULT)

	;; Row 3 Column 0
.r3c0:	
	moveq	#0,MATRIX_ACCUMULATOR_1
	MATRIX_MULT_AND_ACC_ROW	1, 48, 0 ; accumulator number, left byte offset, right byte offset

	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_1,(PTR_MATRIX_RESULT)

	;; Row 3 Column 1
.r3c1:
	moveq	#0,MATRIX_ACCUMULATOR_2
	MATRIX_MULT_AND_ACC_ROW	2, 48, 4 ; accumulator number, left byte offset, right byte offset
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_2,(PTR_MATRIX_RESULT)

	;; Row 3 Column 2
.r3c2:
	moveq	#0,MATRIX_ACCUMULATOR_1
	MATRIX_MULT_AND_ACC_ROW	1, 48, 8 ; accumulator number, left byte offset, right byte offset
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_1,(PTR_MATRIX_RESULT)

	;; Row 3 Column 3
.r3c3:
	moveq	#0,MATRIX_ACCUMULATOR_2
	MATRIX_MULT_AND_ACC_ROW	2, 48, 12 ; accumulator number, left byte offset, right byte offset
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_2,(PTR_MATRIX_RESULT)

.done:
	COPY_MATRIX_FROM_ARRAY_TO_POINTER	#_gpu_matrix_result,#_M_MultResult
	
	cmpq	#0,STOP_GPU_AT_END
	jr	eq,.return
	nop

	;; Stopping the GPU - don't care about the stack
	StopGPU
	nop

.return:
	PopReg	r30
	PopReg	r15
	PopReg	r14
	GPU_RTS
	
_gpu_matrix_multiply_end::

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.macro	LoadTrigTables
	    movei	_FIXED_SINE_TABLE,TEMP1
	    move	TEMP1,SIN_TABLE

	    movei	_FIXED_COSINE_TABLE,TEMP1
	    move	TEMP1,COS_TABLE
	.endm

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
_gpu_matrix_rotation_entry::
	GPU_REG_BANK_1			; ensure we start in register bank 1
	movei	#stack_bank_1_end,SP	; set up the stack

	GPU_JSR	_gpu_matrix_rotation

	StopGPU

	.phrase
_gpu_matrix_rotation::
	;; Build a rotation matrix for (X,Y,Z) degrees.
	;; gpu_matrix_ptr_vector points to the rotation vector
	;; gpu_matrix_ptr_result points to the output
	LoadTrigTables

	movei	#_gpu_matrix_ptr_result,PTR_MATRIX_ROT
	load	(PTR_MATRIX_ROT),PTR_MATRIX_ROT

	; Load the X,Y,Z degrees.
	movei	#_gpu_matrix_ptr_vector,TEMP1
	load	(TEMP1),TEMP2
	load	(TEMP2),X_DEGREES
	addq	#4,TEMP2
	load	(TEMP2),Y_DEGREES
	addq	#4,TEMP2
	load	(TEMP2),Z_DEGREES

	shrq	#16,X_DEGREES
	shrq	#16,Y_DEGREES
	shrq	#16,Z_DEGREES

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
	movei	#0,MATRIX_OFFSET
	
	move	COS_X_DEGREES,TEMP1 
	move	COS_Y_DEGREES,TEMP2

	GPU_JSR	FIXED_PRODUCT_ROTATION
	store	TEMP1,(MATRIX_OFFSET+PTR_MATRIX_ROT)

	;; Row 0 Column 1 | (-(FIXED_MUL(FIXED_COSINE_TABLE[xDeg], FIXED_SINE_TABLE[zDeg]))) + (FIXED_MUL(FIXED_MUL(FIXED_SINE_TABLE[xDeg], FIXED_SINE_TABLE[yDeg]), FIXED_COSINE_TABLE[zDeg]));
	moveq	#4,MATRIX_OFFSET
	move	COS_X_DEGREES,TEMP1
	move	SIN_Y_DEGREES,TEMP2
	GPU_JSR	FIXED_PRODUCT_ROTATION
	move	SIN_Z_DEGREES,TEMP2
	GPU_JSR	FIXED_PRODUCT_ROTATION
	move	TEMP1,r13

	move	SIN_X_DEGREES,TEMP1
	move	COS_Z_DEGREES,TEMP2
	GPU_JSR	FIXED_PRODUCT_ROTATION
	move	r13,TEMP2
	sub	TEMP1,TEMP2 	; TEMP2 -= TEMP1
	
	store	TEMP2,(MATRIX_OFFSET+PTR_MATRIX_ROT)
	
	;; Row 0 Column 2 | FIXED_MUL(FIXED_SINE_TABLE[xDeg], FIXED_SINE_TABLE[zDeg]) + (FIXED_MUL(FIXED_MUL(FIXED_COSINE_TABLE[xDeg], FIXED_SINE_TABLE[yDeg]), FIXED_COSINE_TABLE[zDeg]));
	moveq	#8,MATRIX_OFFSET
	move	COS_X_DEGREES,TEMP1 
	move	SIN_Y_DEGREES,TEMP2
	GPU_JSR	FIXED_PRODUCT_ROTATION	; result in TEMP1
	move	COS_Z_DEGREES,TEMP2
	GPU_JSR	FIXED_PRODUCT_ROTATION	; result in TEMP1
	move	TEMP1,r13	; temp storage

	move	SIN_X_DEGREES,TEMP1
	move	SIN_Z_DEGREES,TEMP2
	GPU_JSR	FIXED_PRODUCT_ROTATION	; result in TEMP1

	add	r13,TEMP1	; add two products together
	store	TEMP1,(MATRIX_OFFSET+PTR_MATRIX_ROT)

	;; Row 1 Column 0 | FIXED_MUL(FIXED_COSINE_TABLE[yDeg], FIXED_SINE_TABLE[zDeg]);
	moveq	#16,MATRIX_OFFSET
	move	SIN_X_DEGREES,TEMP1
	move	COS_Y_DEGREES,TEMP2
	GPU_JSR	FIXED_PRODUCT_ROTATION
	store	TEMP1,(MATRIX_OFFSET+PTR_MATRIX_ROT)

	;; Row 1 Column 1 | FIXED_MUL(FIXED_COSINE_TABLE[yDeg], FIXED_COSINE_TABLE[zDeg]) + (FIXED_MUL(FIXED_MUL(FIXED_SINE_TABLE[xDeg], FIXED_SINE_TABLE[yDeg]), FIXED_SINE_TABLE[zDeg]));
	moveq	#20,MATRIX_OFFSET
	move	SIN_X_DEGREES,TEMP1
	move	SIN_Y_DEGREES,TEMP2
	GPU_JSR	FIXED_PRODUCT_ROTATION	; result in TEMP1
	move	SIN_Z_DEGREES,TEMP2
	GPU_JSR	FIXED_PRODUCT_ROTATION
	move	TEMP1,r13

	move	COS_X_DEGREES,TEMP1
	move	COS_Z_DEGREES,TEMP2
	GPU_JSR	FIXED_PRODUCT_ROTATION

	add	r13,TEMP1
	store	TEMP1,(MATRIX_OFFSET+PTR_MATRIX_ROT)

	;; Row 1 Column 2 | (-(FIXED_MUL(FIXED_SINE_TABLE[xDeg], FIXED_COSINE_TABLE[zDeg]))) + (FIXED_MUL(FIXED_MUL(FIXED_COSINE_TABLE[xDeg], FIXED_SINE_TABLE[yDeg]), FIXED_SINE_TABLE[zDeg]));
	moveq	#24,MATRIX_OFFSET
	move	SIN_X_DEGREES,TEMP1
	move	SIN_Y_DEGREES,TEMP2
	GPU_JSR	FIXED_PRODUCT_ROTATION
	move	COS_Z_DEGREES,TEMP2
	GPU_JSR	FIXED_PRODUCT_ROTATION
	move	TEMP1,r13

	move	COS_X_DEGREES,TEMP1
	move	SIN_Z_DEGREES,TEMP2
	GPU_JSR	FIXED_PRODUCT_ROTATION
	move	r13,TEMP2
	sub	TEMP1,TEMP2
	
	store	TEMP2,(MATRIX_OFFSET+PTR_MATRIX_ROT)
	
	;; Row 2 Column 0 | -(FIXED_SINE_TABLE[yDeg])
	movei	#32,MATRIX_OFFSET
	move	SIN_Y_DEGREES,TEMP1
	neg	TEMP1
	store	TEMP1,(MATRIX_OFFSET+PTR_MATRIX_ROT)

	;; Row 2 Column 1 | FIXED_MUL(FIXED_SINE_TABLE[xDeg],   FIXED_COSINE_TABLE[yDeg]);
	movei	#36,MATRIX_OFFSET
	move	COS_Y_DEGREES,TEMP1
	move	SIN_Z_DEGREES,TEMP2
	GPU_JSR	FIXED_PRODUCT_ROTATION
	store	TEMP1,(MATRIX_OFFSET+PTR_MATRIX_ROT)

	;; Row 2 Column 2 | FIXED_MUL(FIXED_COSINE_TABLE[xDeg], FIXED_COSINE_TABLE[yDeg]);
	movei	#40,MATRIX_OFFSET
	move	COS_Y_DEGREES,TEMP1
	move	COS_Z_DEGREES,TEMP2
	GPU_JSR	FIXED_PRODUCT_ROTATION
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
	GPU_RTS

_gpu_matrix_rotation_end::
	
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
	FP_STEP6_OPERAND_2	.equr	r6
	
	.phrase
FIXED_PRODUCT_MMULT:
	PushReg	r14
	PushReg	r15
	
	;; Space optimization: This is only needed for matrix multiply and accumulate behavior
	;; but nothing else uses FIXED_PRODUCT in this GPU program
	load	(OFFSET_MATRIX_LEFT+PTR_MATRIX_LEFT),r14
	load	(OFFSET_MATRIX_RIGHT+PTR_MATRIX_RIGHT),r15

	;; Make sure we have these values before the register bank changes
	or	r14,r14
	or	r15,r15

	moveta	r14,FP_A
	moveta	r15,FP_B

	movei	#FIXED_PRODUCT_BANK_0,TEMP1
	jump	t,(TEMP1)
	nop

FIXED_PRODUCT_ROTATION:
	PushReg	r14
	PushReg	r15
	
	moveta	TEMP1,FP_A
	moveta	TEMP2,FP_B

FIXED_PRODUCT_BANK_0:	
	GPU_REG_BANK_0
	nop
	nop
	nop
			
	movei   #$0000FFFF,LOWORD_MASK
	moveq   #0,FIXED_PRODUCT_RESULT
	
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
	nop
	
	neg     FP_STEP5_OPERAND_2
	shlq    #16,FP_STEP5_OPERAND_2
	add     FP_STEP5_OPERAND_2,FIXED_PRODUCT_RESULT

.neg_b_check:           ; Is B negative? Add (-A.f) << 16 if so.
	move 	FP_A,FP_STEP6_OPERAND_1
	move	FP_B,FP_STEP6_OPERAND_2
	and     LOWORD_MASK,FP_STEP6_OPERAND_1 ; get A.f
	btst    #31,FP_STEP6_OPERAND_2 ; is B a negative number?
	jr      eq,.accumulate
	nop
	
	neg     FP_STEP6_OPERAND_1
	shlq    #16,FP_STEP6_OPERAND_1
	add     FP_STEP6_OPERAND_1,FIXED_PRODUCT_RESULT

.accumulate:
	add     FP_STEP4_OPERAND_2,FIXED_PRODUCT_RESULT
	nop
	nop
	nop

.done:
	GPU_REG_BANK_1
	nop
	nop
	nop
	movefa	FIXED_PRODUCT_RESULT,TEMP1
	PopReg	r15
	PopReg	r14
	GPU_RTS

_gpu_matrix_multiply_program_end::

	;; Operands for matrix functions
	.phrase
_gpu_matrix_operand_1::	dcb.l	16,$AA55AA55 ;operand 1
	.phrase
_gpu_matrix_operand_2:: dcb.l	16,$AA55AA55 ;operand 2
	.phrase
_gpu_matrix_result::	dcb.l	16,$AA55AA55 ;result matrix
	.phrase
_gpu_accumulator:	dc.l	0

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.phrase
;;; Construct a translation matrix for a given gpu_matrix_vector. Store it to [gpu_matrix_ptr_result].
;;; Can run in either bank.
_gpu_matrix_translation:
	TRANS_PTR_TRANSLATION	.equr	r3
	TRANS_X			.equr	r4
	TRANS_Y			.equr	r5
	TRANS_Z			.equr	r6
	TRANS_FIXED_ONE		.equr	r7
	TRANS_FIXED_ZERO	.equr	r8
	TRANS_PTR_MATRIX	.equr	r9
	
	movei	#$00010000,TRANS_FIXED_ONE
	moveq	#$00000000,TRANS_FIXED_ZERO

	movei	#_gpu_matrix_ptr_result,TRANS_PTR_MATRIX
	load	(TRANS_PTR_MATRIX),TRANS_PTR_MATRIX	;dereference the pointer
	
	movei	#_gpu_matrix_ptr_vector,TRANS_PTR_TRANSLATION
	load	(TRANS_PTR_TRANSLATION),TRANS_X
	addq	#4,TRANS_PTR_TRANSLATION
	load	(TRANS_PTR_TRANSLATION),TRANS_Y
	addq	#4,TRANS_PTR_TRANSLATION
	load	(TRANS_PTR_TRANSLATION),TRANS_Z
	
.set_matrix_values:
	store	TRANS_FIXED_ONE,(TRANS_PTR_MATRIX) 	;[0][0]
	addq	#4,TRANS_PTR_MATRIX
	store	TRANS_FIXED_ZERO,(TRANS_PTR_MATRIX)	;[0][1]
	addq	#4,TRANS_PTR_MATRIX
	store	TRANS_FIXED_ZERO,(TRANS_PTR_MATRIX)	;[0][2]
	addq	#4,TRANS_PTR_MATRIX
	store	TRANS_X,(TRANS_PTR_MATRIX)		;[0][3]

	addq	#4,TRANS_PTR_MATRIX
	store	TRANS_FIXED_ZERO,(TRANS_PTR_MATRIX) 	;[1][0]
	addq	#4,TRANS_PTR_MATRIX
	store	TRANS_FIXED_ONE,(TRANS_PTR_MATRIX)  	;[1][1]
	addq	#4,TRANS_PTR_MATRIX
	store	TRANS_FIXED_ZERO,(TRANS_PTR_MATRIX) 	;[1][2]
	addq	#4,TRANS_PTR_MATRIX
	store	TRANS_Y,(TRANS_PTR_MATRIX)    		;[1][3]

	addq	#4,TRANS_PTR_MATRIX
	store	TRANS_FIXED_ZERO,(TRANS_PTR_MATRIX) 	;[2][0]
	addq	#4,TRANS_PTR_MATRIX
	store	TRANS_FIXED_ZERO,(TRANS_PTR_MATRIX)	;[2][1]
	addq	#4,TRANS_PTR_MATRIX
	store	TRANS_FIXED_ONE,(TRANS_PTR_MATRIX) 	;[2][2]
	addq	#4,TRANS_PTR_MATRIX
	store	TRANS_Z,(TRANS_PTR_MATRIX)		;[2][3]
	
	addq	#4,TRANS_PTR_MATRIX
	store	TRANS_FIXED_ZERO,(TRANS_PTR_MATRIX) 	;[3][0]
	addq	#4,TRANS_PTR_MATRIX
	store	TRANS_FIXED_ZERO,(TRANS_PTR_MATRIX) 	;[3][1]
	addq	#4,TRANS_PTR_MATRIX
	store	TRANS_FIXED_ZERO,(TRANS_PTR_MATRIX)	;[3][2]
	addq	#4,TRANS_PTR_MATRIX
	store	TRANS_FIXED_ONE,(TRANS_PTR_MATRIX)	;[3][3]
	
	GPU_RTS
_gpu_matrix_translation_end::

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.globl	_shape_Current
	
	.phrase
_gpu_build_transformation_matrix::
	GPU_REG_BANK_1		; ensure we start in register bank 1

	movei	#stack_bank_1_end,SP	; set up the stack

	movei	#_gpu_pc_result_ptr,TEMP1
	movei	#_gpu_pc_result_storage,TEMP2
	store	TEMP2,(TEMP1)

	;; Reset _m and _mModel
	COPY_MATRIX_FROM_ARRAY_TO_POINTER	#_gpu_matrix_identity,#_m
	COPY_MATRIX_FROM_ARRAY_TO_POINTER	#_gpu_matrix_identity,#_mModel

	;; Create the model's rotation matrix.
	movei	#_shape_Current,r10
	load	(r10),r10
	movei	#SHAPE_ROTATION,r14
	add	r14,r10

	movei	#_mRotation,r3
	load	(r3),r3
	movei	#_gpu_matrix_ptr_result,r4
	store	r3,(r4)
	
	movei	#_gpu_matrix_ptr_vector,r5
	store	r10,(r5)

	GPU_JSR	#_gpu_matrix_rotation
	
	;; Create the model's translation matrix.
	movei	#_shape_Current,r10
	load	(r10),r10		; get the shape pointer
	movei	#SHAPE_TRANSLATION,r14 	; offset of the translation vector
	load	(r14+r10),r11		; ???

	movei	#_mTranslation,r3
	load	(r3),r3
	movei	#_gpu_matrix_ptr_result,r4
	store	r3,(r4)
	
	movei	#_gpu_matrix_ptr_vector,r5
	store	r11,(r5)

	GPU_JSR	#_gpu_matrix_translation
	
	;; Perform translation * rotation = mModel
	;; Perform mPerspective * mView * mModel = m
	moveq	#0,r30		; set up the matrix multiply as a JSR and not a standalone program

	movei	#_M_MultLeft,r27
	movei	#_M_MultRight,r28
	movei	#_M_MultResult,r29

	;; Calculate mModel - creates a local transformation for the points of the model.
	;; identity matrix * mTranslation
	movei	#_mModel,TEMP1
	movei	#_mTranslation,TEMP2
	load	(TEMP1),TEMP1
	load	(TEMP2),TEMP2
	store	TEMP1,(r27)
	store	TEMP2,(r28)
	movei	#_gpu_pc_result_storage,TEMP1
	store	TEMP1,(r29)
	GPU_JSR	#_gpu_matrix_multiply_jsr_entry		

	; intermediate product * mRotation
	movei	#_gpu_pc_result_ptr,TEMP1 
	movei	#_mRotation,TEMP2
	load	(TEMP1),TEMP1
	load	(TEMP2),TEMP2
	store	TEMP1,(r27)
	store	TEMP2,(r28)
	movei	#_gpu_pc_result_storage,TEMP1
	store	TEMP1,(r29)
	GPU_JSR	#_gpu_matrix_multiply_jsr_entry
	COPY_MATRIX_FROM_ARRAY_TO_POINTER	#_gpu_matrix_result, #_mModel

	;; m = mModel * mView * mPerspective

	movei	#_m,TEMP1
	movei	#_mPerspective,TEMP2
	load	(TEMP1),TEMP1
	load	(TEMP2),TEMP2
	store	TEMP1,(r27)
	store	TEMP2,(r28)
	movei	#_gpu_pc_result_storage,TEMP1
	store	TEMP1,(r29)
	GPU_JSR	#_gpu_matrix_multiply_jsr_entry

	movei	#_gpu_pc_result_ptr,TEMP1
	movei	#_mView,TEMP2
	load	(TEMP1),TEMP1
	load	(TEMP2),TEMP2
	store	TEMP1,(r27)
	store	TEMP2,(r28)
	movei	#_gpu_pc_result_storage,TEMP1
	store	TEMP1,(r29)
	GPU_JSR	#_gpu_matrix_multiply_jsr_entry

	movei	#_gpu_pc_result_ptr,TEMP1
	movei	#_mModel,TEMP2
	load	(TEMP1),TEMP1
	load	(TEMP2),TEMP2
	store	TEMP1,(r27)
	store	TEMP2,(r28)
	movei	#_gpu_pc_result_storage,TEMP1
	store	TEMP1,(r29)
	GPU_JSR	#_gpu_matrix_multiply_jsr_entry

	COPY_MATRIX_FROM_ARRAY_TO_POINTER	#_gpu_matrix_result, #_m
	
	StopGPU
	nop
_gpu_build_transformation_matrix_end::

	;; Precalculate variables.
	.phrase
_gpu_matrix_ptr_result::		dc.l	0   ; storage for a pointer to a Matrix44
_gpu_matrix_ptr_vector::		dc.l	0   ; storage for a pointer to a Vector3FX or Vector4FX
_gpu_matrix_vector:		dcb.l	4,0 ; storage for a Vector3FX or Vector4FX
	
	.phrase
_gpu_pc_result_storage::	dcb.l	16,$AA55AA55 ;the intermediate result
	.phrase
_gpu_pc_result_ptr:		dc.l	0

	.phrase
_gpu_matrix_identity:	dc.l	$00010000,$00000000,$00000000,$00000000
				dc.l	$00000000,$00010000,$00000000,$00000000
				dc.l	$00000000,$00000000,$00010000,$00000000
				dc.l	$00000000,$00000000,$00000000,$00010000

	;; 64-byte stack
	.phrase
stack_bank_0:	dcb.l	8,0
stack_bank_0end:

stack_bank_1:	dcb.l	8,0
stack_bank_1_end:	
	
	.68000
_gpu_matrix_program_end::
