* void DSP_START(uint8_t *function) {
*  MMIO32(D_PC) = (uint32_t)(0xF1B000 + function - dsp_matrix_functions_start);  
*  MMIO32(D_CTRL) = MMIO32(D_CTRL) | 0x01;
* }
*
	xdef	_DSP_Matrix_Start_ASM
	xref	_dsp_matrix_functions_start

D_PC 	= $F1A110
D_CTRL	= $F1A114
D_RAM 	= $F1B000

	even
_DSP_Matrix_Start_ASM:
	;a0 = function ptr to execute	
	move.l	a0,d0
	move.l	#D_PC,a0
	move.l	d0,(a0)
	
	move.l	#D_CTRL,a0
	move.l	(a0),d0
	bset	#0,d0
	move.l	d0,(a0)
	
	rts