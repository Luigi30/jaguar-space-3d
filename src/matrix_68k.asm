	xdef _CopyMatrix44
	xdef _Matrix44_Identity

	even
_CopyMatrix44:
; Copy a Matrix44 from one location to another.
; A Matrix44 consists of 16 longs.
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	
	rts

	even
_Matrix44_Identity_CPU:
; Set a matrix at (a0) to the identity matrix.
	move.l #$00000000,d0
	move.l #$00010000,d1
	
	move.l d1, (a0)+
	move.l d0, (a0)+
	move.l d0, (a0)+
	move.l d0, (a0)+

	move.l d0, (a0)+
	move.l d1, (a0)+
	move.l d0, (a0)+
	move.l d0, (a0)+

	move.l d0, (a0)+
	move.l d0, (a0)+
	move.l d1, (a0)+
	move.l d0, (a0)+

	move.l d0, (a0)+
	move.l d0, (a0)+
	move.l d0, (a0)+
	move.l d1, (a0)+

	rts