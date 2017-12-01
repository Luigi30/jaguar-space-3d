#include "dsp.h"

#include "jaglib.h"

void DSP_LOAD_MATRIX_PROGRAM() {
  skunkCONSOLEWRITE("DSP_LOAD_MATRIX_PROGRAM(): beginning upload\n");
  jag_dsp_load(D_RAM, dsp_matrix_functions, dsp_matrix_functions_end-dsp_matrix_functions);
  skunkCONSOLEWRITE("DSP_LOAD_MATRIX_PROGRAM(): upload complete\n");
}

void DSP_START(uint8_t *function) {
  MMIO32(D_PC) = (uint32_t)(0xF1B000 + function - dsp_matrix_functions_start);  
  MMIO32(D_CTRL) = MMIO32(D_CTRL) | 0x01;
}

#define DSP_WAIT() ( jag_dsp_wait() )
