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