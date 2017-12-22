; jump condition codes
;   %00000:   T    always
;   %00100:   CC   carry clear (less than)
;   %01000:   CS   carry set   (greater or equal)
;   %00010:   EQ   zero set (equal)
;   %00001:   NE   zero clear (not equal) 
;   %11000:   MI   negative set
;   %10100:   PL   negative clear
;   %00101:   HI   greater than
	lo	equ	4
	ge	equ	8

	.include "jaguar.inc"
	.include "3d_types.risc.inc"
	.globl	_back_buffer
	.globl	_front_buffer
	.globl	_scanline_offset_table
	.globl  _VIEW_EYE

	.globl  _tri_ndc_1
	.globl  _tri_ndc_2
	.globl  _tri_ndc_3
	
	;all FIXED_32
	.globl _line_clut_color
	
;Registers for line drawing.
	LINE_X1		.equr	r10
	LINE_Y1		.equr	r11
	LINE_X2		.equr	r12
	LINE_Y2		.equr	r13
	
	X_DIST		.equr	r15
	Y_DIST		.equr	r16

	DIVIDEND	.equr	r17
	DIVISOR		.equr	r18
	SLOPE		.equr	r19

	PTR_VERTEXES	.equr	r21
	
	B_A1_BASE	.equr	r22
	B_A1_PIXEL	.equr	r23
	B_A1_FPIXEL	.equr	r24
	B_A1_INC	.equr	r25
	B_A1_FINC	.equr	r26
	B_A1_FLAGS	.equr	r27
	B_A1_STEP	.equr	r28
	B_B_PATD	.equr	r29
	B_B_COUNT	.equr	r30
	B_B_CMD		.equr	r8

	.include "regmacros.inc"

	.macro DEBUG_DUMP variable,destination
	movei	#\variable,TEMP1
	load	(TEMP1),TEMP1
	movei	#\destination,TEMP2
	store	TEMP1,(TEMP2)
	.endm
	
	.macro BLIT_XY x,y
	move	\x,TEMP2
	move	\y,TEMP1

	shlq	#16,TEMP1
	or	TEMP2,TEMP1
	.endm
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.phrase
_blit_triangle_program_start::
	.gpu
	.org $F03000

_blit_wireframe_triangle::
	GPU_REG_BANK_1
	movei	#stack_bank_1_end,SP
	
setup_blit:
	
	GPU_REG_BANK_0
	GPU_RTS

;;; ;;;;;;;;;;;;;;;;;;;;;;;;
;;; do_blit_line
;;; - Blits a line from (LINE_X1,LINE_Y1) to (LINE_X2,LINE_Y2)
;;; - Uses register bank 0
;;; ;;;;;;;;;;;;;;;;;;;;;;;;
	
do_blit_line:
	GPU_RTS
	
	.phrase
_ptr_vertex_array::		dcb.l	1,0
_ptr_current_triangle:		dcb.l	1,0

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.include "fixed.risc.inc"

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.phrase
_tri_slope1:			dcb.l	1,0
_tri_slope2:			dcb.l  	1,0

tri_x4:	dcb.l	1,0
tri_y4:	dcb.l	1,0
general_case:	dcb.l	1,0
	
	.phrase
_blit_filled_triangle:
	POLY_PTR_VERTICES	.equr	r10
	POLYFILL_CUR_X1		.equr	r2
	POLYFILL_CUR_X2		.equr	r3
	POLYFILL_SCANLINE_START	.equr	r4
	POLYFILL_SCANLINE_END	.equr	r5
	POLYFILL_SCANLINE_CUR	.equr	r6

	;; Sort the vertex array in ascending Y coordinate, ascending X coordinate order.
	movei	#_ptr_vertex_array,TEMP1
 	load	(TEMP1),POLY_PTR_VERTICES

	moveq	#VECTOR4FX_X,r14
	moveq	#VECTOR4FX_Y,r15

	;; Get the beginning of each Vector4FX vertex.
	move	POLY_PTR_VERTICES,r20
	addq	#16,r10
	move	POLY_PTR_VERTICES,r21
	addq	#16,r10
	move	POLY_PTR_VERTICES,r22

	load	(r15+r20),r23	; get Y coordinates
	load	(r15+r21),r24
	load	(r15+r22),r25
	load	(r14+r20),r26	; get X coordinates
	load	(r14+r21),r27
	load	(r14+r22),r28

	;; TODO: Make these functions instead to save space.
.swap1:
	movei	#.swap2,r30
	movei	#.swap1_do,r29

	cmp	r23,r24
	jump	mi,(r29) 	; if y2 >= y1, skip
	nop	
	jump	ne,(r30)	; && y1 != y2, skip
	nop
	cmp	r26,r27
	jump	lo,(r30)	; if y1 == y2 && x1 > x2, swap. is this correct?
	nop
	
	;; y2 > y1 or x2 > x1. Swap v1 and v2.
.swap1_do:
	movei	#4,r4
	movei	#.swap1_loop,r29
.swap1_loop:
	load	(r20),r2
	load	(r21),r3
	store	r2,(r21)
	store	r3,(r20)
	subq	#1,r4
	addq	#4,r20
	addq	#4,r21
	cmpq	#0,r4
	jump	ne,(r29)	; swap 16 bytes
	nop
.swap1_done:
	subq	#16,r20
	subq	#16,r21

.swap2:
	load	(r15+r20),r23	; get Y coordinates
	load	(r15+r21),r24
	load	(r15+r22),r25
	load	(r14+r20),r26	; get X coordinates
	load	(r14+r21),r27
	load	(r14+r22),r28
	
	movei	#.swap3,r30
	movei	#.swap2_do,r29

	cmp	r24,r25
	jump	mi,(r29) 	; if y2 > y3, swap
	nop	
	jump	ne,(r30)	; if y2 == y3...
	nop
	cmp	r27,r28
	jump	lo,(r30)	; ...and x2 > x3, swap.
	nop
	
	;; y3 > y2 or x3 > x2. Swap v3 and v2.
.swap2_do:
	movei	#4,r4
	movei	#.swap2_loop,r29
.swap2_loop:
	load	(r21),r2
	load	(r22),r3
	store	r2,(r22)
	store	r3,(r21)
	subq	#1,r4
	addq	#4,r21
	addq	#4,r22
	cmpq	#0,r4
	jump	ne,(r29)	; swap 16 bytes
	nop
.swap2_done:
	subq	#16,r21
	subq	#16,r22

.swap3:
	load	(r15+r20),r23	; get Y coordinates
	load	(r15+r21),r24
	load	(r15+r22),r25
	load	(r14+r20),r26	; get X coordinates
	load	(r14+r21),r27
	load	(r14+r22),r28
	
	movei	#.swaps_done,r30
	movei	#.swap3_do,r29

	cmp	r23,r24
	jump	mi,(r29) 	; if y1 > y2, swap
	nop	
	jump	ne,(r30)	; if y1 == y2...
	nop
	cmp	r26,r27
	jump	lo,(r30)	; if y1 == y2 && x1 > x2, swap. is this correct?
	nop
	
	;; y2 > y1 or x2 > x1. Swap v1 and v2.
.swap3_do:
	movei	#4,r4
	movei	#.swap3_loop,r29
.swap3_loop:
	load	(r20),r2
	load	(r21),r3
	store	r2,(r21)
	store	r3,(r20)
	subq	#1,r4
	addq	#4,r20
	addq	#4,r21
	cmpq	#0,r4
	jump	ne,(r29)	; swap 16 bytes
	nop
.swap3_done:
	subq	#16,r20
	subq	#16,r21

.swaps_done:
	load	(r14+r20),r23	; get X coordinates
	load	(r14+r21),r24
	load	(r14+r22),r25
	load	(r15+r20),r26	; get Y coordinates
	load	(r15+r21),r27
	load	(r15+r22),r28

	movei	#general_case,TEMP1
	moveq	#0,TEMP2
	store	TEMP2,(TEMP1)
	
	;; OK, now ptr_vertex_array is in the correct order.
	GPU_JSR	_load_vertex_data_for_polyfill

	;; if v1.y == v2.y, this is a flat-top triangle.
	movei	#.draw_flat_top_only,r30
	cmp	r26,r27
	jump	eq,(r30)
	nop
	
	;; if v2.y == v3.y, this is a flat-bottom triangle.
	movei	#.draw_flat_bottom_only,r30
	cmp	r27,r28
	jump	eq,(r30)
	nop

	;; Flat-top and flat-bottom triangles work, but the general case seems to be wrong
.draw_general_case:
	;; RTS if we already drew a trivial case
	movei	#general_case,TEMP1
	load	(TEMP1),TEMP2
	cmpq	#0,TEMP2
	jr	eq,.do_general

	GPU_RTS

.do_general:	
*	load	(r14+r20),r23	; v1.x
*	load	(r14+r21),r24	; v2.x
*	load	(r14+r22),r25	; v3.x
*	load	(r15+r20),r26	; v1.y
*	load	(r15+r21),r27	; v2.y
*	load	(r15+r22),r28	; v3.y
	
	;; OK, now calculate x4.
	;; x4 = x1 + ((y2-y1)/(y3-y1)) * (x3-x1)
	movei	#tri_x4,r20
	movei	#tri_y4,r21

	move	r27,r10
	move	r28,r11
	sub	r26,r10
	sub	r26,r11

	move	r10,TEMP1
	move	r11,TEMP2
	
	GPU_JSR	FIXED_DIV
	move	TEMP1,r17	; r17 = (y2-y1)/(y3-y1)

	move	r25,r18
	sub	r23,r18		; r18 = x3-x1

	GPU_JSR	FIXED_PRODUCT_BANK_1
	
	add	r23,r5		; r5 = x4
	move	r27,r6		; r6 = y4 = y2
	store	r5,(r20)
	store	r6,(r21)
	
;;; Flat-top triangle - (v2, v4, v3)
	GPU_JSR	_load_vertex_data_for_polyfill

	moveta	r28,POLYFILL_SCANLINE_START
	moveta	r27,POLYFILL_SCANLINE_END

	move	r25,TEMP1
	sub	r24,TEMP1	; TEMP1 = v3.x - v2.x
	move	r28,TEMP2
	sub	r27,TEMP2	; TEMP2 = v3.y - v2.y
	GPU_JSR FIXED_DIV	; (v3.x - v2.x) / (v3.x - v2.x)
	movei	#_tri_slope1,TEMP2
	store	TEMP1,(TEMP2)

	movei	#tri_x4,r20
	movei	#tri_y4,r21
	load	(r20),r5
	load	(r21),r6

	move	r25,TEMP1
	sub	r5,TEMP1	; TEMP1 = v3.x - v4.x
	move	r28,TEMP2
	sub	r6,TEMP2	; TEMP2 = v3.y - v4.y
	
	GPU_JSR FIXED_DIV	; (v3.x - v4.x) / (v3.x - v4.x)
	movei	#_tri_slope2,TEMP2
	store	TEMP1,(TEMP2)

	moveta	r25,POLYFILL_CUR_X1
	moveta	r25,POLYFILL_CUR_X2
	
	GPU_JSR	_do_fill_flattop_polygon

;;; Flat-bottom triangle - (v1, v2, v4)
	GPU_JSR	_load_vertex_data_for_polyfill

*	load	(r14+r20),r23	; v1.x
*	load	(r14+r21),r24	; v2.x
*	load	(r14+r22),r25	; v3.x
*	load	(r15+r20),r26	; v1.y
*	load	(r15+r21),r27	; v2.y
*	load	(r15+r22),r28	; v3.y

	move	r24,TEMP1
	sub	r23,TEMP1	; TEMP1 = v2.x - v1.x
	move	r27,TEMP2
	sub	r26,TEMP2	; TEMP2 = v2.y - v1.y
	GPU_JSR FIXED_DIV	; (v2.x - v1.x) / (v2.y - v1.y)
	movei	#_tri_slope1,TEMP2
	store	TEMP1,(TEMP2)

	movei	#tri_x4,r20
	movei	#tri_y4,r21
	load	(r20),r5
	load	(r21),r6

	moveta	r26,POLYFILL_SCANLINE_START
	moveta	r6,POLYFILL_SCANLINE_END
	
	move	r5,TEMP1
	sub	r23,TEMP1	; TEMP1 = v4.x - v1.x
	move	r6,TEMP2
	sub	r26,TEMP2	; TEMP2 = v4.y - v1.y
	GPU_JSR FIXED_DIV	; (v4.x - v1.x) / (v4.y - v1.y)
	movei	#_tri_slope2,TEMP2
	store	TEMP1,(TEMP2)
	
	moveta	r23,POLYFILL_CUR_X1
	moveta	r23,POLYFILL_CUR_X2
	
	GPU_JSR	_do_fill_flatbottom_polygon
	
	GPU_RTS

.draw_flat_bottom_only:
	movei	#general_case,TEMP1
	moveq	#1,TEMP2
	store	TEMP2,(TEMP1)
	
	GPU_JSR	_load_vertex_data_for_polyfill

	move	r24,TEMP1
	sub	r23,TEMP1	; TEMP1 = v2.x - v1.x
	move	r27,TEMP2
	sub	r26,TEMP2	; TEMP2 = v2.y - v1.y
	GPU_JSR FIXED_DIV	; (v2.x - v1.x) / (v2.x - v1.x)
	movei	#_tri_slope1,TEMP2
	store	TEMP1,(TEMP2)
	
	move	r25,TEMP1
	sub	r23,TEMP1	; TEMP1 = v3.x - v1.x
	move	r28,TEMP2
	sub	r26,TEMP2	; TEMP2 = v3.y - v1.y
	GPU_JSR FIXED_DIV	; (v3.x - v1.x) / (v3.x - v1.x)
	movei	#_tri_slope2,TEMP2
	store	TEMP1,(TEMP2)

	moveta	r23,POLYFILL_CUR_X1
	moveta	r23,POLYFILL_CUR_X2
	moveta	r26,POLYFILL_SCANLINE_START
	moveta	r27,POLYFILL_SCANLINE_END
	
	GPU_JSR	_do_fill_flatbottom_polygon
	GPU_RTS	

.draw_flat_top_only:
	movei	#general_case,TEMP1
	moveq	#1,TEMP2
	store	TEMP2,(TEMP1)

	GPU_JSR	_load_vertex_data_for_polyfill

	move	r25,TEMP1
	sub	r23,TEMP1	; TEMP1 = v3.x - v1.x
	move	r28,TEMP2
	sub	r26,TEMP2	; TEMP2 = v3.y - v1.y
	GPU_JSR FIXED_DIV	; (v3.x - v2.x) / (v3.x - v2.x)
	movei	#_tri_slope1,TEMP2
	store	TEMP1,(TEMP2)
	
	move	r25,TEMP1
	sub	r24,TEMP1	; TEMP1 = v3.x - v2.x
	move	r28,TEMP2
	sub	r27,TEMP2	; TEMP2 = v3.y - v2.y
	GPU_JSR FIXED_DIV	; (v3.x - v1.x) / (v3.x - v1.x)
	movei	#_tri_slope2,TEMP2
	store	TEMP1,(TEMP2)

	moveta	r25,POLYFILL_CUR_X1
	moveta	r25,POLYFILL_CUR_X2
	moveta	r28,POLYFILL_SCANLINE_START
	moveta	r26,POLYFILL_SCANLINE_END
	
	GPU_JSR	_do_fill_flattop_polygon
	GPU_RTS

	.phrase
_load_vertex_data_for_polyfill:
	movei	#_ptr_vertex_array,TEMP1
 	load	(TEMP1),POLY_PTR_VERTICES
	
	moveq	#VECTOR4FX_X,r14
	moveq	#VECTOR4FX_Y,r15
	
	move	POLY_PTR_VERTICES,r20
	addq	#16,r10
	move	POLY_PTR_VERTICES,r21
	addq	#16,r10
	move	POLY_PTR_VERTICES,r22

	load	(r14+r20),r23	; v1.x
	load	(r14+r21),r24	; v2.x
	load	(r14+r22),r25	; v3.x
	load	(r15+r20),r26	; v1.y
	load	(r15+r21),r27	; v2.y
	load	(r15+r22),r28	; v3.y
	
	GPU_RTS

	.phrase
_polyfill_blit_registers_setup:
	;; Set up some blitter registers...
	movei	#A1_BASE,B_A1_BASE
	movei	#A1_PIXEL,B_A1_PIXEL
	movei	#A1_FPIXEL,B_A1_FPIXEL
	movei	#A1_INC,B_A1_INC
	movei	#A1_FINC,B_A1_FINC
	movei	#A1_FLAGS,B_A1_FLAGS
	movei	#A1_STEP,B_A1_STEP
	movei	#B_PATD,B_B_PATD
	movei	#B_COUNT,B_B_COUNT
	movei	#B_CMD,B_B_CMD

	movei	#_back_buffer,TEMP1
	load	(TEMP1),TEMP1
	store	TEMP1,(B_A1_BASE)

	PushReg	r17

	movei	#_gpu_tri_facing_ratio,TEMP1	
	load	(TEMP1),r17
	
	shrq	#12,r17		; shift out all but the high nybble of the ratio.
	sat8	r17
	
	store	r17,(B_B_PATD)

	PopReg	r17
	
	movei	#$00C80140,TEMP1 ; 320x200 window
	movei	#A1_CLIP,TEMP2
	store	TEMP1,(TEMP2)

	moveq	#0,TEMP1
	movei	#PITCH1|PIXEL8|WID320|XADDPIX,TEMP2
	
	store	TEMP1,(B_A1_FPIXEL)
	store	TEMP2,(B_A1_FLAGS)

	moveq	#$00000000,TEMP1
	store	TEMP1,(B_A1_STEP)

	GPU_RTS

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.phrase
_do_fill_flattop_polygon:
	GPU_REG_BANK_1

	;; http://www.sunshine2k.de/coding/java/TriangleRasterization/TriangleRasterization.html
	
	;; for (int scanlineY = v3.y; scanlineY > v1.y; scanlineY--)
	;; {
	;;   drawLine(POLYFILL_CUR_X1, scanlineY, POLYFILL_CUR_X2, scanlineY)
	;;   POLYFILL_CUR_X1 -= tri_slope1
	;;   POLYFILL_CUR_X2 -= tri_slope2
	;; }

*	POLYFILL_CUR_X1		.equr	r2
*	POLYFILL_CUR_X2		.equr	r3
*	POLYFILL_SCANLINE_START	.equr	r4
*	POLYFILL_SCANLINE_END	.equr	r5
*	POLYFILL_SCANLINE_CUR	.equr	r6

	;; Set up some blitter registers...
	GPU_JSR	_polyfill_blit_registers_setup

	movei	#$FFFF0000,r10
	and	r10,POLYFILL_SCANLINE_START
	and	r10,POLYFILL_SCANLINE_END

	movei	#_tri_slope1,TEMP1
	movei	#_tri_slope2,TEMP2
	load	(TEMP1),r18
	load	(TEMP2),r19

	movei	#.polyfill_loop,r7
	move	POLYFILL_SCANLINE_START,POLYFILL_SCANLINE_CUR
	
.polyfill_loop:
	move	POLYFILL_CUR_X1,r15
	move	POLYFILL_CUR_X2,r16
	shrq	#16,r15
	shrq	#16,r16

.clamp_x1:
	btst	#15,r15
	jr	eq,.clamp_x2	; check the sign of r15. if negative, clamp to 0
	nop
	moveq	#0,r15
.clamp_x2:
	btst	#15,r16		; check the sign of r16. if negative, clamp to 0
	jr	eq,.reorder
	nop
	moveq	#0,r16	

.reorder:
	cmp	r15,r16
	jr	hi,.go

	move	r16,TEMP1
	move	r15,r16
	move	TEMP1,r15

.go:	
	;; Store the pixel pointer for the starting position.
	move	POLYFILL_SCANLINE_CUR,r10
	or	r15,r10
	store	r10,(B_A1_PIXEL)

	;; Draw a horizontal line from POLYFILL_CUR_X1 to POLYFILL_CUR_X2 on scanline POLYFILL_SCANLINE_CUR.
	move 	r16,TEMP1
	sub	r15,TEMP1
	bset	#16,TEMP1
	store	TEMP1,(B_B_COUNT)
	move	TEMP1,r12
	
	movei	#CLIP_A1|PATDSEL|LFU_REPLACE,TEMP1
	store	TEMP1,(B_B_CMD)

.next_loop:
	movei	#$00010000,r11
	sub	r11,POLYFILL_SCANLINE_CUR

	sub	r18,POLYFILL_CUR_X1
	sub	r19,POLYFILL_CUR_X2

	cmp	POLYFILL_SCANLINE_CUR,POLYFILL_SCANLINE_END
	jump	ge,(r7)
	nop

.polyfill_complete:
	GPU_REG_BANK_0
	GPU_RTS

;;; ;;;;;;;;;;;;;;;;;;;;;;;;
	
	.phrase
_do_fill_flatbottom_polygon:
	GPU_REG_BANK_1

	;; http://www.sunshine2k.de/coding/java/TriangleRasterization/TriangleRasterization.html
	
	;; for (int scanlineY = v3.y; scanlineY > v1.y; scanlineY--)
	;; {
	;;   drawLine(POLYFILL_CUR_X1, scanlineY, POLYFILL_CUR_X2, scanlineY)
	;;   POLYFILL_CUR_X1 -= tri_slope1
	;;   POLYFILL_CUR_X2 -= tri_slope2
	;; }

*	POLYFILL_CUR_X1		.equr	r2
*	POLYFILL_CUR_X2		.equr	r3
*	POLYFILL_SCANLINE_START	.equr	r4
*	POLYFILL_SCANLINE_END	.equr	r5
*	POLYFILL_SCANLINE_CUR	.equr	r6

	;; Set up some blitter registers...
	GPU_JSR	_polyfill_blit_registers_setup

	movei	#$FFFF0000,r10
	and	r10,POLYFILL_SCANLINE_START
	and	r10,POLYFILL_SCANLINE_END

	movei	#_tri_slope1,TEMP1
	movei	#_tri_slope2,TEMP2
	load	(TEMP1),r18
	load	(TEMP2),r19

	movei	#.polyfill_loop,r7
	move	POLYFILL_SCANLINE_START,POLYFILL_SCANLINE_CUR
	
.polyfill_loop:
	move	POLYFILL_CUR_X1,r15
	move	POLYFILL_CUR_X2,r16
	shrq	#16,r15
	shrq	#16,r16

.clamp_x1:
	btst	#15,r15
	jr	eq,.clamp_x2	; check the sign of r15. if negative, clamp to 0
	nop
	moveq	#0,r15
.clamp_x2:
	btst	#15,r16		; check the sign of r16. if negative, clamp to 0
	jr	eq,.reorder
	nop
	moveq	#0,r16	

.reorder:
	cmp	r15,r16
	jr	ne,.notsame	; make sure x1 != x2
	nop
	addq	#1,r16
	
.notsame:
	cmp	r15,r16
	jr	hi,.go

	move	r16,TEMP1
	move	r15,r16
	move	TEMP1,r15
	
.go:
	;; Store the pixel pointer for the starting position.
	move	POLYFILL_SCANLINE_CUR,r10
	or	r15,r10
	store	r10,(B_A1_PIXEL)

	;; Draw a horizontal line from POLYFILL_CUR_X1 to POLYFILL_CUR_X2 on scanline POLYFILL_SCANLINE_CUR.
	move 	r16,TEMP1
	sub	r15,TEMP1
	bset	#16,TEMP1
	bset	#0,TEMP1
	store	TEMP1,(B_B_COUNT)
	move	TEMP1,r12
	
	movei	#CLIP_A1|PATDSEL|LFU_REPLACE,TEMP1
	store	TEMP1,(B_B_CMD)
	
	movei	#$00010000,r11
	add	r11,POLYFILL_SCANLINE_CUR

	add	r18,POLYFILL_CUR_X1
	add	r19,POLYFILL_CUR_X2
	
	;; if POLYFILL_SCANLINE_CUR <= POLYFILL_SCANLINE_END, jump back to polyfill_loop
	cmp	POLYFILL_SCANLINE_END,POLYFILL_SCANLINE_CUR
	jump	ge,(r7)
	nop

.polyfill_complete:
	GPU_REG_BANK_0
	GPU_RTS

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FIXED_NORMALIZE:	
	;; Normalize the vector at r2-r4 in place.	
	;; Store the products in the other register bank at r10-r12.
	move	r2,r17
	move	r2,r18
	GPU_JSR	FIXED_PRODUCT_BANK_1
	moveta	r5,r10		; pass to bank 1

	move	r3,r17
	move	r3,r18
	GPU_JSR	FIXED_PRODUCT_BANK_1
	moveta	r5,r11		; pass to bank 1

	move	r4,r17
	move	r4,r18
	GPU_JSR	FIXED_PRODUCT_BANK_1
	moveta	r5,r12		; pass to bank 1

	;; Do FIXED_SQRT in reg bank 1.
	GPU_REG_BANK_1
	nop

	move	r10,r0
	add	r11,r0
	add	r12,r0

	GPU_JSR	FIXED_SQRT	; r0 = sqrt(r0)
	moveta	r0,r10		; store the magnitude in bank 0 r10

	;; divide vector by magnitude
	movefa	r2,r0
	movefa	r10,r1
	GPU_JSR	FIXED_DIV
	moveta	r0,r2		; x

	movefa	r3,r0
	movefa	r10,r1
	GPU_JSR	FIXED_DIV
	moveta	r0,r3		; y

	movefa	r4,r0
	movefa	r10,r1
	GPU_JSR	FIXED_DIV
	moveta	r0,r4		; z

	GPU_REG_BANK_0
	nop

	GPU_RTS

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Draw triangle on the screen routine
	.phrase
_gpu_mvp_result_ptr:	dc.l	0
_gpu_mvp_vector_ptr:	dc.l	0
_gpu_mvp_matrix_ptr:	dc.l	0
_gpu_mvp_matrix:	dcb.l	16,0

	.phrase			; Three Vector4FX for the triangle points.
_gpu_tri_point_1::	dcb.l	4,0
_gpu_tri_point_2::	dcb.l	4,0
_gpu_tri_point_3::	dcb.l	4,0
	
_gpu_tri_facing_ratio::	dcb.l	1,0

_gpu_tri_normal:	dcb.l	3,0
	
	.globl	_object_M
	.globl	_object_Triangle
	.globl	_shape_Current

	DIVISOR_IS_NEGATIVE	.equr	r24
	DIVIDEND_IS_NEGATIVE	.equr	r25
	ADVANCE_TRIANGLE	.equr	r26

	EDGE_AREA_HI		.equr	r28
	EDGE_AREA_LO		.equr	r29
	
	.phrase
_gpu_project_and_draw_triangle::
	GPU_REG_BANK_0
	nop
	
	movei	#stack_bank_0_end,SP
	movei	#stack_bank_1_end,TEMP1
	moveta	TEMP1,SP

	;; Get matrix-vector product of each of the points.
.triangle_loop:
	;; Dereference the triangle pointer and get the triangle.
	movei	#_object_Triangle,r3
	movei	#_ptr_current_triangle,r4
	load	(r3),r5
	load	(r5),r6
	store	r6,(r4)

.triangle1:
	movei	#_object_M,TEMP1
	load	(TEMP1),TEMP1
	movei	#_gpu_mvp_matrix_ptr,TEMP2
	store	TEMP1,(TEMP2)

	movei	#_ptr_current_triangle,TEMP1	;ptr to the first triangle's coords
	load	(TEMP1),TEMP1
	movei	#_gpu_mvp_vector_ptr,TEMP2
	store	TEMP1,(TEMP2)

	movei	#_gpu_tri_point_1,TEMP1
	movei	#_gpu_mvp_result_ptr,TEMP2
	store	TEMP1,(TEMP2)

	GPU_JSR	_gpu_matrix_vector_product

.triangle2:
	movei	#_ptr_current_triangle,TEMP1	;ptr to the first triangle's coords
	load	(TEMP1),TEMP1
	addq	#12,TEMP1	;advance to triangle #2
	movei	#_gpu_mvp_vector_ptr,TEMP2
	store	TEMP1,(TEMP2)
	
	movei	#_gpu_tri_point_2,TEMP1
	movei	#_gpu_mvp_result_ptr,TEMP2
	store	TEMP1,(TEMP2)

	GPU_JSR	_gpu_matrix_vector_product

.triangle3:
	movei	#_ptr_current_triangle,TEMP1	;ptr to the first triangle's coords
	load	(TEMP1),TEMP1
	addq	#12,TEMP1	;advance to triangle #2
	addq	#12,TEMP1	;advance to triangle #3
	movei	#_gpu_mvp_vector_ptr,TEMP2
	store	TEMP1,(TEMP2)
	
	movei	#_gpu_tri_point_3,TEMP1
	movei	#_gpu_mvp_result_ptr,TEMP2
	store	TEMP1,(TEMP2)

	GPU_JSR	_gpu_matrix_vector_product

.perspective_divide:
	;; Now we have the NDC coordinates for our three triangles.
	;; Perform the perspective divide on each triangle.
	
	movei	#_gpu_tri_point_1,TEMP1
	GPU_JSR	_gpu_perspective_divide

	movei	#_gpu_tri_point_2,TEMP1
	GPU_JSR	_gpu_perspective_divide

	movei	#_gpu_tri_point_3,TEMP1
	GPU_JSR	_gpu_perspective_divide

.determine_triangle_winding:
	WIND_POINT_1	.equr	r6
	WIND_POINT_2	.equr	r7
	WIND_POINT_3	.equr	r8

	WIND_V0_X	.equr	r10
	WIND_V0_Y	.equr	r11
	WIND_V0_Z	.equr	r12

	WIND_V1_X	.equr	r19
	WIND_V1_Y	.equr	r20
	WIND_V1_Z	.equr	r21

	WIND_V2_X	.equr	r22
	WIND_V2_Y	.equr	r23
	WIND_V2_Z	.equr	r24

	VECTOR_U_X	.equr	r25
	VECTOR_U_Y	.equr	r26
	VECTOR_U_Z	.equr	r27

	VECTOR_V_X	.equr	r28
	VECTOR_V_Y	.equr	r29
	VECTOR_V_Z	.equr	r30
	
	movei	#_gpu_tri_point_1,r3
	movei	#_gpu_tri_point_2,r4
	movei	#_gpu_tri_point_3,r5

	;; X
	load	(r3),WIND_V0_X	
	load	(r4),WIND_V1_X
	load	(r5),WIND_V2_X	
	moveq	#4,r14
	
	;; Y
	load	(r14+r3),WIND_V0_Y
	load	(r14+r4),WIND_V1_Y
	load	(r14+r5),WIND_V2_Y
	moveq	#8,r14

	;; Z
	load	(r14+r3),WIND_V0_Z
	load	(r14+r4),WIND_V1_Z
	load	(r14+r5),WIND_V2_Z

	;; http://cmichel.io/understanding-front-faces-winding-order-and-normals/
	;; u = v1 - v0
	move	WIND_V1_X,TEMP2
	move	WIND_V0_X,TEMP1
	sub	TEMP1,TEMP2
	move	TEMP2,VECTOR_U_X
	move	TEMP2,r2

	move	WIND_V1_Y,TEMP2
	move	WIND_V0_Y,TEMP1
	sub	TEMP1,TEMP2
	move	TEMP2,VECTOR_U_Y

	move	WIND_V1_Z,TEMP2
	move	WIND_V0_Z,TEMP1
	sub	TEMP1,TEMP2
	move	TEMP2,VECTOR_U_Z

	;; v = v2 - v0
	move	WIND_V2_X,TEMP2
	move	WIND_V0_X,TEMP1
	sub	TEMP1,TEMP2
	move	TEMP2,VECTOR_V_X

	move	WIND_V2_Y,TEMP2
	move	WIND_V0_Y,TEMP1
	sub	TEMP1,TEMP2
	move	TEMP2,VECTOR_V_Y

	move	WIND_V2_Z,TEMP2
	move	WIND_V0_Z,TEMP1
	sub	TEMP1,TEMP2
	move	TEMP2,VECTOR_V_Z
	
	;; Cross product:
	;; U.y*V.z - U.z*V.y
	;; U.z*V.x - U.x*V.z
	;; U.x*V.y - U.y*V.x
	move	VECTOR_U_Y,r17
	move	VECTOR_V_Z,r18
	GPU_JSR	FIXED_PRODUCT_BANK_1
	move	r5,r6

	move	VECTOR_U_Z,r17
	move	VECTOR_V_Y,r18

	GPU_JSR FIXED_PRODUCT_BANK_1
	sub	r5,r6
	move	r6,r2

	;;
	move	VECTOR_U_Z,r17
	move	VECTOR_V_X,r18
	GPU_JSR	FIXED_PRODUCT_BANK_1
	move	r5,r6

	move	VECTOR_U_X,r17
	move	VECTOR_V_Z,r18
	GPU_JSR FIXED_PRODUCT_BANK_1
	sub	r5,r6
	move	r6,r3

	;; 
	move	VECTOR_U_X,r17
	move	VECTOR_V_Y,r18
	GPU_JSR	FIXED_PRODUCT_BANK_1
	move	r5,r6

	move	VECTOR_U_Y,r17
	move	VECTOR_V_X,r18
	GPU_JSR FIXED_PRODUCT_BANK_1
	sub	r5,r6
	move	r6,r4

	move	VECTOR_U_X,r16
	move	VECTOR_U_Y,r17
	move	VECTOR_U_Z,r18

	move	VECTOR_V_X,r20
	move	VECTOR_V_Y,r21
	move	VECTOR_V_Z,r22

.normalize:
	GPU_JSR	FIXED_NORMALIZE
	
	movei	#_gpu_tri_normal,TEMP2
	store	r2,(TEMP2)
	addq	#4,TEMP2
	store	r3,(TEMP2)
	addq	#4,TEMP2
	store	r4,(TEMP2)

	;; Now create a vector from the camera to the triangle's p1.
	movei	#_gpu_tri_point_1,r10
	load	(r10),r11
	addq	#4,r10
	load	(r10),r12
	addq	#4,r10
	load	(r10),r13

	movei	#_VIEW_EYE,r19
	load	(r19),r2
	addq	#4,r19
	load	(r19),r3
	addq	#4,r19
	load	(r19),r4
	
	sub	r11,r2
	sub	r12,r3
	sub	r13,r4

	GPU_JSR	FIXED_NORMALIZE

	movei	#_gpu_tri_normal,TEMP2
	load	(TEMP2),r20
	addq	#4,TEMP2
	load	(TEMP2),r21
	addq	#4,TEMP2
	load	(TEMP2),r22

	;; store the NDC coordinates of point 1 for debugging
	movei	#_gpu_tri_point_1,r10
	movei	#_tri_ndc_1,r11
	load	(r10),r12	
	load	(r11),r13
	store	r12,(r13)
	addq	#4,r10
	addq	#4,r13
	load	(r10),r12	
	store	r12,(r13)
	addq	#4,r10
	addq	#4,r13
	load	(r10),r12	
	store	r12,(r13)
	
	;; Calculate the dot product of V and p1 vector
	FIXED_DOT_PRODUCT	r2,r3,r4, r20,r21,r22, r6

	;; TODO: Clamp to 0.000-0.999
	
	movei	#_gpu_tri_facing_ratio,TEMP1
	store	r6,(TEMP1)

	movei	#.advance_triangle,r30
	btst	#31,r6
	jump	ne,(r30)	; if surface normal is positive, it's visible
	nop

.make_screen_coordinates:
	movei	#_gpu_tri_point_1,r10
	movei	#_gpu_tri_point_2,r11
	movei	#_gpu_tri_point_3,r12

	;; Multiply X coordinates by 160 and add 160
	load	(r10),r17
	movei	#$00A00000,r18
	GPU_JSR	FIXED_PRODUCT_BANK_1
	add	r18,r5
	store	r5,(r10)

	load	(r11),r17
	GPU_JSR	FIXED_PRODUCT_BANK_1
	add	r18,r5
	store	r5,(r11)

	load	(r12),r17
	GPU_JSR	FIXED_PRODUCT_BANK_1
	add	r18,r5
	store	r5,(r12)

	;; Multiply Y coordinates by 100 and add 100
	addq	#4,r10
	addq	#4,r11
	addq	#4,r12
	
	load	(r10),r17
	movei	#$00640000,r18
	GPU_JSR	FIXED_PRODUCT_BANK_1
	add	r18,r5
	store	r5,(r10)

	load	(r11),r17
	GPU_JSR	FIXED_PRODUCT_BANK_1
	add	r18,r5
	store	r5,(r11)

	load	(r12),r17
	GPU_JSR	FIXED_PRODUCT_BANK_1
	add	r18,r5
	store	r5,(r12)

	movei	#_gpu_tri_point_1,TEMP1
	movei	#_ptr_vertex_array,TEMP2
	store	TEMP1,(TEMP2)

	;; And blit.
	GPU_JSR #_blit_filled_triangle

.advance_triangle:
	movei	#_object_Triangle,r3
	load	(r3),r4
	addq	#4,r4
	store	r4,(r3)

	load	(r4),r5
	movei	#.triangle_loop,r3
	cmpq	#0,r5	; if the next triangle is a null pointer, we're done
	jump	ne,(r3)
	nop
	
	StopGPU
	nop
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Perspective divide function.
;;; Takes a pointer to a Vector4FX in TEMP1 and stores the result back to it.
	.phrase
_gpu_perspective_divide:
	move	TEMP1,r10	; store the Vector4FX pointer

.perspective_divide_x:
	move	r10,TEMP1
	load	(TEMP1),TEMP1	; grab the X coordinate
	move	r10,TEMP2
	addq	#12,TEMP2
	load	(TEMP2),TEMP2
	
	GPU_JSR	FIXED_DIV
	store	TEMP1,(r10)
	
.perspective_divide_y:
	addq	#4,r10
	load	(r10),TEMP1	; grab the Y coordinate
	move	r10,TEMP2
	addq	#8,TEMP2	; grab the W coordinate
	load	(TEMP2),TEMP2
	
	GPU_JSR	FIXED_DIV
	store	TEMP1,(r10)

.perspective_divide_z:
	addq	#4,r10
	load	(r10),TEMP1	; grab the Z coordinate
	move	r10,TEMP2
	addq	#4,TEMP2	; grab the W coordinate
	load	(TEMP2),TEMP2
	GPU_JSR	FIXED_DIV
	store	TEMP1,(r10)
	
	GPU_RTS
_gpu_project_and_draw_triangle_end::

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.phrase
_gpu_matrix_vector_product:
	GPU_REG_BANK_1
	
	MV_MATRIX		.equr	r10
	MV_VECTOR		.equr	r11
	MV_RESULT		.equr	r12
	MV_MATRIX_OFFSET	.equr	r14
	MV_RESULT_OFFSET	.equr	r15
	MV_ACCUMULATOR		.equr	r16
	
	movei	#_gpu_mvp_result_ptr,MV_RESULT
	movei	#_gpu_mvp_matrix_ptr,MV_MATRIX
	movei	#_gpu_mvp_vector_ptr,MV_VECTOR

	load	(MV_RESULT),MV_RESULT
	load	(MV_MATRIX),MV_MATRIX
	load	(MV_VECTOR),MV_VECTOR

	movei	#0,MV_MATRIX_OFFSET
	movei	#0,MV_RESULT_OFFSET

	movei	#stack_bank_1_end,SP
	movei	#.calculate_row,r30
	moveq	#4,r3

.calculate_row:
	load	(MV_MATRIX_OFFSET+MV_MATRIX),r17
	load	(MV_VECTOR),r18	
	GPU_JSR	FIXED_PRODUCT	; matrix->data[0][0] * vector->x
	move	r5,MV_ACCUMULATOR
	
	addq	#4,MV_MATRIX_OFFSET
	addq	#4,MV_VECTOR
	load	(MV_MATRIX_OFFSET+MV_MATRIX),r17
	load	(MV_VECTOR),r18
	GPU_JSR FIXED_PRODUCT	; matrix->data[0][1] * vector->y
	add	r5,MV_ACCUMULATOR

	addq	#4,MV_MATRIX_OFFSET
	addq	#4,MV_VECTOR
	load	(MV_MATRIX_OFFSET+MV_MATRIX),r17
	load	(MV_VECTOR),r18
	GPU_JSR FIXED_PRODUCT	; matrix->data[0][2] * vector->z
	add	r5,MV_ACCUMULATOR

	addq	#4,MV_MATRIX_OFFSET
	load	(MV_MATRIX_OFFSET+MV_MATRIX),r17
	add	r17,MV_ACCUMULATOR ; matrix->data[0][3] * 1
	store	MV_ACCUMULATOR,(MV_RESULT)

	move	MV_ACCUMULATOR,r20

	addq	#4,MV_MATRIX_OFFSET
	addq	#4,MV_RESULT
	subq	#8,MV_VECTOR	; reset to vector->x

	subq	#1,r3
	cmpq	#0,r3
	jump	ne,(r30)
	nop
	
	GPU_REG_BANK_0
	nop
	GPU_RTS
	
;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.phrase
FIXED_PRODUCT_BANK_1:
	GPU_REG_BANK_1
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
	GPU_REG_BANK_0
	nop
	movefa    FIXED_PRODUCT_RESULT,r5
	nop
	GPU_RTS

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.phrase
stack_bank_0:	dcb.l	8,0
stack_bank_0_end:

	.phrase
stack_bank_1:	dcb.l	8,0
stack_bank_1_end:

	
	.68000
_blit_triangle_end::
