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
	.globl	_back_buffer
	.globl	_scanline_offset_table
	.globl  _VIEW_EYE
	
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

_blit_triangle::
	GPU_REG_BANK_1
	movei	#stack_bank_1_end,SP
	
setup_blit:
	GPU_REG_BANK_0
;; Set up registers for writing
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

	;; TODO: Implement a triangle queue. Dequeue a triangle, call do_blit_triangle.
	;; If the queue is empty, spin loop until there are more triangles to process.
	
	GPU_REG_BANK_1

do_blit_triangle:
	;; Blit a triangle using the vertexes at ptr_vertex_array
	;; The points will be (p0.x,p0.y),(p1.x,p1.y), (p1.x,p1.y),(p2.x,p2.y), (p2.x,p2.y),(p0.x,p0.y)
	;; TODO: colors besides white

	movei	#_ptr_vertex_array,PTR_VERTEXES
 	load	(PTR_VERTEXES),PTR_VERTEXES
	
.draw_line_1:
	movei	#0,r14
	movei	#16,r15
	load	(r14+PTR_VERTEXES),LINE_X1
	load	(r15+PTR_VERTEXES),LINE_X2
	movei	#4,r14
	movei	#20,r15
	load	(r14+PTR_VERTEXES),LINE_Y1
	load	(r15+PTR_VERTEXES),LINE_Y2

	moveta	LINE_X1,LINE_X1
	moveta	LINE_X2,LINE_X2
	moveta	LINE_Y1,LINE_Y1
	moveta	LINE_Y2,LINE_Y2

	GPU_JSR	#do_blit_line

.draw_line_2:
	movei	#_ptr_vertex_array,PTR_VERTEXES
 	load	(PTR_VERTEXES),PTR_VERTEXES
	
	movei	#16,r14
	movei	#32,r15
	load	(r14+PTR_VERTEXES),LINE_X1
	load	(r15+PTR_VERTEXES),LINE_X2
	movei	#20,r14
	movei	#36,r15
	load	(r14+PTR_VERTEXES),LINE_Y1
	load	(r15+PTR_VERTEXES),LINE_Y2

	moveta	LINE_X1,LINE_X1
	moveta	LINE_X2,LINE_X2
	moveta	LINE_Y1,LINE_Y1
	moveta	LINE_Y2,LINE_Y2

	GPU_JSR	#do_blit_line

.draw_line_3:
	movei	#_ptr_vertex_array,PTR_VERTEXES
 	load	(PTR_VERTEXES),PTR_VERTEXES
	
	movei	#32,r14
	movei	#0,r15
	load	(r14+PTR_VERTEXES),LINE_X1
	load	(r15+PTR_VERTEXES),LINE_X2
	movei	#36,r14
	movei	#4,r15
	load	(r14+PTR_VERTEXES),LINE_Y1
	load	(r15+PTR_VERTEXES),LINE_Y2

	moveta	LINE_X1,LINE_X1
	moveta	LINE_X2,LINE_X2
	moveta	LINE_Y1,LINE_Y1
	moveta	LINE_Y2,LINE_Y2

	GPU_JSR	#do_blit_line

	GPU_REG_BANK_0
	GPU_RTS

;;; ;;;;;;;;;;;;;;;;;;;;;;;;
;;; do_blit_line
;;; - Blits a line from (LINE_X1,LINE_Y1) to (LINE_X2,LINE_Y2)
;;; - Uses register bank 0
;;; ;;;;;;;;;;;;;;;;;;;;;;;;
	
do_blit_line:
	GPU_REG_BANK_0
	
	WAIT_FOR_BLITTER_IDLE	
	LOCK_BLITTER
	TAKE_BLIT_PRIORITY

	;; X1 > X2? Swap the points if so.
	cmp	LINE_X1,LINE_X2
	jr	hi,.calculateDistances
	nop

	move	LINE_X1,TEMP1
	move	LINE_X2,LINE_X1
	move	TEMP1,LINE_X2

	move	LINE_Y1,TEMP1
	move	LINE_Y2,LINE_Y1
	move	TEMP1,LINE_Y2
	
.calculateDistances:	
	;Calculate abs(x2-x1) and abs(y2-y1)
	move	LINE_X2,X_DIST
	move	LINE_Y2,Y_DIST
	sub	LINE_X1,X_DIST
	sub	LINE_Y1,Y_DIST
	abs	X_DIST
	abs	Y_DIST

.preset_registers:
	;Set up for 16.16 divide
	moveq	#1,TEMP1
	movei	#G_DIVCTRL,TEMP2
	store	TEMP1,(TEMP2)

	;; pre-set the blit registers
	movei	#_back_buffer,TEMP1
	load	(TEMP1),TEMP1
	store	TEMP1,(B_A1_BASE)

	movei	#_line_clut_color,TEMP2
	load	(TEMP2),TEMP1
	store	TEMP1,(B_B_PATD)

	movei	#0,TEMP1
	movei	#A1_CLIP,TEMP2
	store	TEMP1,(TEMP2)
	
.draw_line:
	movei	#dy_greater,TEMP1
	movei	#dx_greater,TEMP2
	movei	#dx_equals_dy,JUMPADDR
	cmp	X_DIST,Y_DIST
	jump	hi,(TEMP1) 	;dy_greater
	nop
	jump	eq,(JUMPADDR)	;dx_equals_dy
	nop
	jump	t,(TEMP2)	;dx_greater
	nop

dy_greater:

.calc_slope:
	move	X_DIST,DIVIDEND
	move	Y_DIST,DIVISOR

	;; dx / dy
	div	DIVISOR,DIVIDEND	;destination / source
	or	DIVIDEND,DIVIDEND
	move	DIVIDEND,SLOPE		;slope = DIVISOR/DIVIDEND
	
	movei	#.y2_is_greater,JUMPADDR
	cmp	LINE_Y1,LINE_Y2	
	jump	cc,(JUMPADDR)
	nop
	jump	eq,(JUMPADDR)
	nop

.y1_is_greater:
	;; YINC = -1
	;; XINC = (dx<<16) / dy

	movei	#$FFFF0000,TEMP1
	store	TEMP1,(B_A1_INC)
	store	SLOPE,(B_A1_FINC)

	movei	#.set_registers,JUMPADDR
	jump	t,(JUMPADDR)
	nop

.y2_is_greater:
	;; YINC = 1
	;; XINC = (dx<<16) / dy

	movei	#$00010000,TEMP1
	store	TEMP1,(B_A1_INC)
	store	SLOPE,(B_A1_FINC)
	
.set_registers:
	move	LINE_X1,r18
	move	LINE_Y1,r19
	shrq	#16,r18
	shrq	#16,r19
	
	BLIT_XY	r18,r19
	store	TEMP1,(B_A1_PIXEL)

	movei	#$00C80140,TEMP1
	movei	#A1_CLIP,TEMP2
	store	TEMP1,(TEMP2)

	movei	#0,TEMP1
	movei	#PITCH1|PIXEL8|WID320|XADDINC,TEMP2
	
	store	TEMP1,(B_A1_FPIXEL)
	store	TEMP2,(B_A1_FLAGS)

	movei	#$00000000,TEMP1
	store	TEMP1,(B_A1_STEP)

	movei	#blit_line_done,JUMPADDR
	cmpq	#0,Y_DIST
	jump	eq,(JUMPADDR)
	nop
	
	move	Y_DIST,TEMP1
	movei	#$FFFF0000,TEMP2
	and	TEMP2,TEMP1
	addq	#1,TEMP1
	store	TEMP1,(B_B_COUNT)
	
	movei	#blit_line_go,JUMPADDR
	jump	t,(JUMPADDR)
	nop
	
;;; 
dx_greater:

.calc_slope:
	move	Y_DIST,DIVIDEND
	move	X_DIST,DIVISOR
	
	;Set up for 16.16 divide
	moveq	#1,TEMP1
	movei	#G_DIVCTRL,TEMP2
	store	TEMP1,(TEMP2)

	;; dy / dx
	div	DIVISOR,DIVIDEND	;destination / source
	or	DIVIDEND,DIVIDEND
	move	DIVIDEND,SLOPE		;slope = DIVISOR/DIVIDEND

	movei	#.y2_is_greater,JUMPADDR
	cmp	LINE_Y1,LINE_Y2	
	jump	cc,(JUMPADDR)
	nop
	jump	eq,(JUMPADDR)
	nop

;;; if y1 > y2
.y1_greater:
	;; YINC = 65536 - ((dy<<16)/dx)
	movei	#65536,TEMP1
	sub	SLOPE,TEMP1

	movei	#$FFFF0001,TEMP2
	store	TEMP2,(B_A1_INC)

	shlq	#16,TEMP1
	store	TEMP1,(B_A1_FINC)

	movei	#.set_registers,JUMPADDR
	jump	t,(JUMPADDR)
	nop

.y2_is_greater:
	;; YINC = (dy<<16) / dx
	movei	#$00000001,TEMP1 
	store	TEMP1,(B_A1_INC) 

	move	SLOPE,TEMP1
	shlq	#16,TEMP1
	store	TEMP1,(B_A1_FINC)

.set_registers:
	;; A1_PIXEL = LINE_X1,LINE_Y1
	move	LINE_X1,r18
	move	LINE_Y1,r19
	shrq	#16,r18
	shrq	#16,r19
	
	BLIT_XY	r18,r19
	store	TEMP1,(B_A1_PIXEL)

	movei	#0,TEMP1
	movei	#PITCH1|PIXEL8|WID320|XADDINC,TEMP2
	
	store	TEMP1,(B_A1_FPIXEL)
	store	TEMP2,(B_A1_FLAGS)

	movei	#$00000000,TEMP1
	store	TEMP1,(B_A1_STEP)
	
	;; B_COUNT  = 1<<16 + X_DIST>>16
	movei	#blit_line_done,JUMPADDR
	cmpq	#0,X_DIST
	jump	eq,(JUMPADDR)
	
	move	X_DIST,TEMP1
	shrq	#16,TEMP1
	addq	#1,TEMP1
	movei	#$00010000,TEMP2
	add	TEMP2,TEMP1
	store	TEMP1,(B_B_COUNT)
	
	movei	#blit_line_go,JUMPADDR
	jump	t,(JUMPADDR)
	nop

dx_equals_dy:
	cmp	LINE_Y1,LINE_Y2	
	jr	hi,.y2_is_greater
	nop
	
.y1_is_greater:
	movei	#$FFFF0001,r20
	store	r20,(B_A1_INC)
	jr	t,.set_registers
	nop
	
.y2_is_greater:
	movei	#$00010001,r20
	store	r20,(B_A1_INC)
	
.set_registers:
	move	LINE_X1,r18
	move	LINE_Y1,r19
	shrq	#16,r18
	shrq	#16,r19
	
	BLIT_XY	r18,r19
	store	TEMP1,(B_A1_PIXEL)

	movei	#0,TEMP1
	store	TEMP1,(B_A1_FPIXEL)
	store	TEMP1,(B_A1_FINC)

	movei	#blit_line_done,JUMPADDR
	cmpq	#0,Y_DIST
	jump	eq,(JUMPADDR)
	
	move	Y_DIST,TEMP1
	movei	#$FFFF0000,TEMP2
	and	TEMP2,TEMP1
	addq	#1,TEMP1
	move	TEMP1,r5
	store	TEMP1,(B_B_COUNT)

blit_line_go:
	movei	#$00C80140,TEMP1
	movei	#A1_CLIP,TEMP2
	store	TEMP1,(TEMP2)

	;; clear unused registers
	movei	#0,TEMP1	
	movei	#PITCH1|PIXEL8|WID320|XADDINC,TEMP1
	store	TEMP1,(B_A1_FLAGS)
	
	movei	#PATDSEL|UPDA1|UPDA1F|CLIP_A1|LFU_S,TEMP1
	store	TEMP1,(B_B_CMD)

	;; wait for blit to complete
	WAIT_FOR_BLITTER_IDLE
	
blit_line_done:	
	UNLOCK_BLITTER

	GPU_REG_BANK_1
	GPU_RTS
	
	.phrase
_ptr_vertex_array::		dcb.l	1,0
_ptr_current_triangle:		dcb.l	1,0
	.phrase
_gpu_register_dump::		dcb.l	32,0

;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Draw triangle on the screen routine
	.phrase
_gpu_mvp_result_ptr:	dc.l	0
_gpu_mvp_vector_ptr:	dc.l	0
_gpu_mvp_matrix_ptr:	dc.l	0
_gpu_mvp_matrix:	dcb.l	16,0

	.phrase			; Three Vector4FX for the triangle points.
_gpu_tri_point_1:	dcb.l	4,0
_gpu_tri_point_2:	dcb.l	4,0
_gpu_tri_point_3:	dcb.l	4,0
	
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

	;; TODO: Why does this flip signs when incrementing the X rotation?
	;; That shouldn't affect visibility at all - it's clockwise rotation.
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
	;; Normalize the vector at r2-r4.
	;; Store it in the other register bank at r10-r12.
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

	movei	#.advance_triangle,r30

	;; Checked against R. Cross product and normalization are correct.
	;; But the polygon flickers so the normal or dot product can't be right

	;; Result is (r2,r3,r4).
	;; Now create a vector from the camera to the triangle's p1.
	movei	#_gpu_tri_point_1,r10
	load	(r10),r11
	addq	#4,r10
	load	(r10),r12
	addq	#4,r10
	load	(r10),r13

	movei	#_VIEW_EYE,r19
	load	(r19),r20
	addq	#4,r19
	load	(r19),r21
	addq	#4,r19
	load	(r19),r22
	
	sub	r11,r20
	sub	r12,r21
	sub	r13,r22

	;; Calculate the dot product of V and p1 vector
	FIXED_DOT_PRODUCT	r2,r3,r4, r20,r21,r22, r6

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
	GPU_JSR	#_blit_triangle

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

	movei	#stack_bank_1_end,SP
	movei	#.calculate_row,r30
	moveq	#4,r3

.calculate_row:
	load	(MV_MATRIX_OFFSET+MV_MATRIX),r17
	load	(MV_VECTOR),r18	
	GPU_JSR	FIXED_PRODUCT	; matrix->data[0][0] * vector->x
	move	r5,MV_ACCUMULATOR

	or	r5,r5
	
	addq	#4,MV_MATRIX_OFFSET
	addq	#4,MV_VECTOR
	load	(MV_MATRIX_OFFSET+MV_MATRIX),r17
	load	(MV_VECTOR),r18
	GPU_JSR FIXED_PRODUCT	; matrix->data[0][1] * vector->y
	add	r5,MV_ACCUMULATOR

	or	r5,r5

	addq	#4,MV_MATRIX_OFFSET
	addq	#4,MV_VECTOR
	load	(MV_MATRIX_OFFSET+MV_MATRIX),r17
	load	(MV_VECTOR),r18
	GPU_JSR FIXED_PRODUCT	; matrix->data[0][2] * vector->z
	add	r5,MV_ACCUMULATOR

	or	r5,r5

	addq	#4,MV_MATRIX_OFFSET
	load	(MV_MATRIX_OFFSET+MV_MATRIX),r17
	add	r17,MV_ACCUMULATOR ; matrix->data[0][3] * 1
	store	MV_ACCUMULATOR,(MV_RESULT)

	move	r5,r5

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
	nop
	nop
	GPU_RTS

	.include "fixed.risc.inc"
	
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
stack_bank_0:	dcb.l	32,0
stack_bank_0_end:

	.phrase
stack_bank_1:	dcb.l	32,0
stack_bank_1_end:

	
	.68000
_blit_triangle_end::
