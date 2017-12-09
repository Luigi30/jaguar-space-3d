;;; Matrix multiplication program for the Jaguar GPU.
;;; ABI: r0-r9 are volatile on function calls, r10-r30 should be preserved. r31 = stack pointer.
;;; TODO: Make all the routines compliant with this ABI.
	.section text
	
	.gpu
	.include "jaguar.inc"
	.include "regmacros.inc"

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

	GPU_JSR	FIXED_PRODUCT
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
	movei	#stack_end,SP
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
	movei	#0,MATRIX_ACCUMULATOR_1
	MATRIX_MULT_AND_ACC	1, 0, 0  ; accumulator number, left byte offset, right byte offset
	MATRIX_MULT_AND_ACC	1, 4, 16 ;
	MATRIX_MULT_AND_ACC	1, 8, 32 ;
	MATRIX_MULT_AND_ACC	1, 12,48 ;
	store	MATRIX_ACCUMULATOR_1,(PTR_MATRIX_RESULT)
	
	;; Row 0 Column 1
.r0c1:
	movei	#0,MATRIX_ACCUMULATOR_2
	MATRIX_MULT_AND_ACC	2, 0, 4
	MATRIX_MULT_AND_ACC	2, 4, 20
	MATRIX_MULT_AND_ACC	2, 8, 36
	MATRIX_MULT_AND_ACC	2, 12,52
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_2,(PTR_MATRIX_RESULT)

	;; Row 0 Column 2
.r0c2:
	movei	#0,MATRIX_ACCUMULATOR_1
	MATRIX_MULT_AND_ACC	1, 0, 8
	MATRIX_MULT_AND_ACC	1, 4, 24
	MATRIX_MULT_AND_ACC	1, 8, 40
	MATRIX_MULT_AND_ACC	1, 12,56
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_1,(PTR_MATRIX_RESULT)
	
	;; Row 0 Column 3
.r0c3:
	movei	#0,MATRIX_ACCUMULATOR_2
	MATRIX_MULT_AND_ACC	2, 0, 12 ; accumulator number, left byte offset, right byte offset
	MATRIX_MULT_AND_ACC	2, 4, 28 ;
	MATRIX_MULT_AND_ACC	2, 8, 44 ;
	MATRIX_MULT_AND_ACC	2, 12,60 ;
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_2,(PTR_MATRIX_RESULT)

	;; Row 1 Column 0
.r1c0:	
	movei	#0,MATRIX_ACCUMULATOR_1
	MATRIX_MULT_AND_ACC	1, 16, 0  ; accumulator number, left byte offset, right byte offset
	MATRIX_MULT_AND_ACC	1, 20, 16 ;
	MATRIX_MULT_AND_ACC	1, 24, 32 ;
	MATRIX_MULT_AND_ACC	1, 28, 48 ;
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_1,(PTR_MATRIX_RESULT)

	;; Row 1 Column 1
.r1c1:
	movei	#0,MATRIX_ACCUMULATOR_2
	MATRIX_MULT_AND_ACC	2, 16, 4
	MATRIX_MULT_AND_ACC	2, 20, 20
	MATRIX_MULT_AND_ACC	2, 24, 36
	MATRIX_MULT_AND_ACC	2, 28, 52
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_2,(PTR_MATRIX_RESULT)

	;; Row 1 Column 2
.r1c2:
	movei	#0,MATRIX_ACCUMULATOR_1
	MATRIX_MULT_AND_ACC	1, 16, 8
	MATRIX_MULT_AND_ACC	1, 20, 24
	MATRIX_MULT_AND_ACC	1, 24, 40
	MATRIX_MULT_AND_ACC	1, 28, 56
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_1,(PTR_MATRIX_RESULT)

	;; Row 1 Column 3
.r1c3:
	movei	#0,MATRIX_ACCUMULATOR_2
	MATRIX_MULT_AND_ACC	2, 16, 12
	MATRIX_MULT_AND_ACC	2, 20, 28
	MATRIX_MULT_AND_ACC	2, 24, 44
	MATRIX_MULT_AND_ACC	2, 28, 60
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_2,(PTR_MATRIX_RESULT)

	;; Row 2 Column 0
.r2c0:	
	movei	#0,MATRIX_ACCUMULATOR_1
	MATRIX_MULT_AND_ACC	1, 32, 0  ; accumulator number, left byte offset, right byte offset
	MATRIX_MULT_AND_ACC	1, 36, 16 ;
	MATRIX_MULT_AND_ACC	1, 40, 32 ;
	MATRIX_MULT_AND_ACC	1, 44, 48 ;
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_1,(PTR_MATRIX_RESULT)

	;; Row 2 Column 1
.r2c1:
	movei	#0,MATRIX_ACCUMULATOR_2
	MATRIX_MULT_AND_ACC	2, 32, 4
	MATRIX_MULT_AND_ACC	2, 36, 20
	MATRIX_MULT_AND_ACC	2, 40, 36
	MATRIX_MULT_AND_ACC	2, 44, 52
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_2,(PTR_MATRIX_RESULT)

	;; Row 2 Column 2
.r2c2:
	movei	#0,MATRIX_ACCUMULATOR_1
	MATRIX_MULT_AND_ACC	1, 32, 8
	MATRIX_MULT_AND_ACC	1, 36, 24
	MATRIX_MULT_AND_ACC	1, 40, 40
	MATRIX_MULT_AND_ACC	1, 44, 56
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_1,(PTR_MATRIX_RESULT)

	;; Row 2 Column 3
.r2c3:
	movei	#0,MATRIX_ACCUMULATOR_2
	MATRIX_MULT_AND_ACC	2, 32, 12
	MATRIX_MULT_AND_ACC	2, 36, 28
	MATRIX_MULT_AND_ACC	2, 40, 44
	MATRIX_MULT_AND_ACC	2, 44, 60
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_2,(PTR_MATRIX_RESULT)

	;; Row 3 Column 0
.r3c0:	
	movei	#0,MATRIX_ACCUMULATOR_1
	MATRIX_MULT_AND_ACC	1, 48, 0  ; accumulator number, left byte offset, right byte offset
	MATRIX_MULT_AND_ACC	1, 52, 16 ;
	MATRIX_MULT_AND_ACC	1, 56, 32 ;
	MATRIX_MULT_AND_ACC	1, 60, 48 ;
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_1,(PTR_MATRIX_RESULT)

	;; Row 3 Column 1
.r3c1:
	movei	#0,MATRIX_ACCUMULATOR_2
	MATRIX_MULT_AND_ACC	2, 48, 4
	MATRIX_MULT_AND_ACC	2, 52, 20
	MATRIX_MULT_AND_ACC	2, 56, 36
	MATRIX_MULT_AND_ACC	2, 60, 52
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_2,(PTR_MATRIX_RESULT)

	;; Row 3 Column 2
.r3c2:
	movei	#0,MATRIX_ACCUMULATOR_1
	MATRIX_MULT_AND_ACC	1, 48, 8
	MATRIX_MULT_AND_ACC	1, 52, 24
	MATRIX_MULT_AND_ACC	1, 56, 40
	MATRIX_MULT_AND_ACC	1, 60, 56
	addq	#4,PTR_MATRIX_RESULT
	store	MATRIX_ACCUMULATOR_1,(PTR_MATRIX_RESULT)

	;; Row 3 Column 3
.r3c3:
	movei	#0,MATRIX_ACCUMULATOR_2
	MATRIX_MULT_AND_ACC	2, 48, 12
	MATRIX_MULT_AND_ACC	2, 52, 28
	MATRIX_MULT_AND_ACC	2, 56, 44
	MATRIX_MULT_AND_ACC	2, 60, 60
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
	
	.phrase
FIXED_PRODUCT:
	PushReg	r14
	PushReg	r15
	
	;; Space optimization: This is only needed for matrix multiply and accumulate behavior
	;; but nothing else uses FIXED_PRODUCT in this GPU program
	load	(OFFSET_MATRIX_LEFT+PTR_MATRIX_LEFT),r14
	load	(OFFSET_MATRIX_RIGHT+PTR_MATRIX_RIGHT),r15

	;; Make sure we have these values before the register bank changes
	or	r14,r14
	or	r15,r15
	
	GPU_REG_BANK_0
	nop
	nop
	nop
			
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

	movefa	r14,FP_A
	movefa	r15,FP_B
	
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
_gpu_matrix_translation::
	TRANS_PTR_TRANSLATION	.equr	r3
	TRANS_X			.equr	r4
	TRANS_Y			.equr	r5
	TRANS_Z			.equr	r6
	TRANS_FIXED_ONE		.equr	r7
	TRANS_FIXED_ZERO	.equr	r8
	TRANS_PTR_MATRIX	.equr	r9
	
	movei	#$00010000,TRANS_FIXED_ONE
	movei	#$00000000,TRANS_FIXED_ZERO

	movei	#_gpu_matrix_ptr_result,TRANS_PTR_MATRIX
	load	(TRANS_PTR_MATRIX),TRANS_PTR_MATRIX	;dereference the pointer
	
	movei	#_gpu_matrix_vector,TRANS_PTR_TRANSLATION
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
	.phrase
_gpu_build_transformation_matrix::
	GPU_REG_BANK_1		; ensure we start in register bank 1
	
	;; Perform translation * rotation = mModel
	;; Perform mPerspective * mView * mModel = m
	movei	#0,r30		; set up the matrix multiply as a JSR and not a standalone program
	
	movei	#_gpu_pc_result_ptr,TEMP1
	movei	#_gpu_pc_result_storage,TEMP2
	store	TEMP2,(TEMP1)

	movei	#_M_MultLeft,r27
	movei	#_M_MultRight,r28
	movei	#_M_MultResult,r29

	;; Calculate mModel
	movei	#_mModel,TEMP1
	movei	#_mRotation,TEMP2
	load	(TEMP1),TEMP1
	load	(TEMP2),TEMP2
	store	TEMP1,(r27)
	store	TEMP2,(r28)
	movei	#_gpu_pc_result_storage,TEMP1
	store	TEMP1,(r29)
	GPU_JSR	#_gpu_matrix_multiply_jsr_entry

	movei	#_gpu_pc_result_ptr,TEMP1
	movei	#_mTranslation,TEMP2
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
_gpu_matrix_ptr_result:		dc.l	0   ; storage for a pointer to a Matrix44
_gpu_matrix_ptr_vector:		dc.l	0   ; storage for a pointer to a Vector3FX or Vector4FX
_gpu_matrix_vector:		dcb.l	4,0 ; storage for a Vector3FX or Vector4FX
	
	.phrase
_gpu_pc_result_storage::	dcb.l	16,$AA55AA55 ;the intermediate result
	.phrase
_gpu_pc_result_ptr:		dc.l	0

	;; 64-byte stack
	.phrase
stack:	dcb.l	16,$00000000
stack_end:
	
	.68000
_gpu_matrix_program_end::
