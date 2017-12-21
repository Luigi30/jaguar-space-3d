	xdef _GPU_Precalculate_Start

G_PC = $F30000
	
	even
_GPU_Precalculate_Start:
	move.l #G_PC,a0
	
	rts