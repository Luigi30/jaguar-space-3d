;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Fixed-point math function library and macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Dot product (v1,v2) => result
	.macro FIXED_DOT_PRODUCT v1x,v1y,v1z,v2x,v2y,v2z,result
		move	\v1x,r17
		move	\v2x,r18
		GPU_JSR	FIXED_PRODUCT_BANK_1
		move	r5,\result
		
		move	\v1y,r17
		move	\v2y,r18
		GPU_JSR	FIXED_PRODUCT_BANK_1
		add	r5,\result

		move	\v1z,r17
		move	\v2z,r18
		GPU_JSR	FIXED_PRODUCT_BANK_1
		add	r5,\result
	.endm

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
	FP_STEP6_OPERAND_2	.equr	r19
	
	.phrase
FIXED_PRODUCT:
	GPU_REG_BANK_0
	nop
	nop
	nop
			
	;; Subroutine that multiplies two fixed-point numbers r17 and r18.
	;; Result is returned in r5.	
	movei   #$0000FFFF,LOWORD_MASK
	movei   #0,FIXED_PRODUCT_RESULT

	movefa	r17,FP_A
	movefa	r18,FP_B
	
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
	movefa    FIXED_PRODUCT_RESULT,r5
	nop
	nop
	nop
	GPU_RTS

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.phrase
FIXED_DIV:
	;; Fixed-point divide.
	;; TEMP1 = TEMP1 / TEMP2
	movei	#1,r2	; set the divide unit for fixed-point divide
	movei	#G_DIVCTRL,r3
	store	r2,(r3)
	nop
	
	DIV_DIVISOR_IS_NEGATIVE		.equr	r3
	DIV_DIVIDEND_IS_NEGATIVE	.equr	r4
	DIV_MINUS_ONE			.equr	r5
	DIV_7FFFFFFF			.equr	r6

	movei	#$FFFFFFFF,DIV_MINUS_ONE	; -1.0
	movei	#$7FFFFFFF,DIV_7FFFFFFF		; xor value for negating a quotient
	
.test_dividend_sign:
	btst	#31,TEMP1
	jr	eq,.test_divisor_sign	;skip to the divisor if the number is positive
	movei	#0,DIV_DIVIDEND_IS_NEGATIVE

	;; The dividend is negative.
	xor	DIV_MINUS_ONE,TEMP1	; take the absolute value of the dividend
	addq	#1,TEMP1
	movei	#1,DIV_DIVIDEND_IS_NEGATIVE

.test_divisor_sign:
	btst	#31,TEMP2
	jr	eq,.do_divide		; skip to the divide if the number is positive
	movei	#0,DIV_DIVISOR_IS_NEGATIVE
	
	xor	DIV_MINUS_ONE,TEMP2
	addq    #1,TEMP2
	movei	#1,DIV_DIVISOR_IS_NEGATIVE

.do_divide:
	div	TEMP2,TEMP1		; TEMP1 = TEMP1 / TEMP2
	or	TEMP1,TEMP1

	movei	#0,r2
	add	DIV_DIVISOR_IS_NEGATIVE,r2
	add	DIV_DIVIDEND_IS_NEGATIVE,r2
	cmpq	#1,r2
	jr	ne,.return_divided
	nop

	bset	#31,TEMP1
	xor	DIV_7FFFFFFF,TEMP1
	addq	#1,TEMP1

	movei	#0,r2		; set the divide unit for integer divide
	movei	#G_DIVCTRL,r3
	store	r2,(r3)
	nop

.return_divided:
	GPU_RTS

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.phrase
FIXED_SQRT:
	;; Calculate the square root of r0.
	;; Returned in r0.
	FRACBITS	.equ	16
	ITERS		.equ	(15 + (FRACBITS >> 1))

	SQRT_ROOT	.equr	r20
	SQRT_REM_HI	.equr	r21
	SQRT_REM_LO	.equr	r22
	SQRT_TEST_DIV	.equr	r23
	SQRT_COUNT	.equr	r24

	SQRT_THIRTY	.equr	r25
	SQRT_LOOP_CHECK	.equr	r29
	SQRT_LOOP_ADDR	.equr	r30

	moveq	#0,SQRT_ROOT
	moveq	#0,SQRT_REM_HI
	move	r0,SQRT_REM_LO
	moveq	ITERS,SQRT_COUNT

	moveq	#30,SQRT_THIRTY
	movei	#.sqrt_loop,SQRT_LOOP_ADDR
	movei	#.sqrt_do_loop,SQRT_LOOP_CHECK

.sqrt_loop:
	shlq	#2,SQRT_REM_HI
	move	SQRT_REM_LO,TEMP1
	sh	SQRT_THIRTY,TEMP1
	or	TEMP1,SQRT_REM_HI
	shlq	#2,SQRT_REM_LO

	shlq	#1,SQRT_ROOT
	move	SQRT_ROOT,SQRT_TEST_DIV
	shlq	#1,SQRT_TEST_DIV
	addq	#1,SQRT_TEST_DIV

	cmp	SQRT_TEST_DIV,SQRT_REM_HI
	jump	ge,(SQRT_LOOP_CHECK) ;if remHi >= testDiv
	nop

	sub	SQRT_TEST_DIV,SQRT_REM_HI
	addq	#1,SQRT_ROOT

.sqrt_do_loop:
	subq	#1,SQRT_COUNT

	cmpq	#-1,SQRT_COUNT
	jump	ne,(SQRT_LOOP_ADDR) ; if not -1, keep looping
	nop

	move	SQRT_ROOT,r0

	GPU_RTS