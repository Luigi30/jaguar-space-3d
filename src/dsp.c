#include "dsp.h"

#include "jaglib.h"

void DSP_LOAD_MATRIX_PROGRAM() {
	int bytes = dsp_matrix_functions_end-dsp_matrix_functions_start;
	sprintf(skunkoutput, "DSP_LOAD_MATRIX_PROGRAM(): Uploading %d bytes at %p to %p\n", bytes, dsp_matrix_functions, D_RAM);
	skunkCONSOLEWRITE(skunkoutput);
	
	memcpy(D_RAM, dsp_matrix_functions, bytes);
	skunkCONSOLEWRITE("DSP_LOAD_MATRIX_PROGRAM(): upload complete\n");
}

void DSP_START(uint8_t *function) {
	sprintf(skunkoutput, "DSP_START: executing DSP function at %p", (0xF1B000 + function - dsp_matrix_functions_start));
	skunkCONSOLEWRITE(skunkoutput);
	
	MMIO32(D_PC) = (uint32_t)(0xF1B000 + function - dsp_matrix_functions_start);  
	MMIO32(D_CTRL) = MMIO32(D_CTRL) | 0x01;
}

#define DSP_WAIT() ( jag_dsp_wait() )
