#ifndef DSP_H
#define DSP_H

#include <jagcore.h>
#include <jaglib.h>

#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <time.h>

#include "shared.h"
#include "fixed.h"

void DSP_LOAD_MATRIX_PROGRAM();
void DSP_START(uint8_t *function);
void DSP_Matrix_Start_ASM(__reg("a0") uint8_t *function);

extern char skunkoutput[128];

/**************************
 * Matrix stuff
 **************************/
typedef struct matrix44_t Matrix44;

/* Matrix functions */

extern uint8_t dsp_matrix_pc_test[];
extern uint8_t dsp_matrix_pc_test_end[];

extern uint8_t dsp_matrix_identity_set[];
extern uint8_t dsp_matrix_identity_set_end[];

extern uint8_t dsp_matrix_functions[];
extern uint8_t dsp_matrix_functions_start[];
extern uint8_t dsp_matrix_functions_end[];

extern uint8_t dsp_matrix_add[];
extern uint8_t dsp_matrix_add_end[];

extern uint8_t dsp_matrix_sub[];
extern uint8_t dsp_matrix_sub_end[];

extern uint8_t dsp_matrix_translation[];
extern uint8_t dsp_matrix_translation_end[];

extern uint8_t dsp_matrix_rotation[];
extern uint8_t dsp_matrix_rotation_end[];

extern uint8_t dsp_matrix_vector_product[];
extern uint8_t dsp_matrix_vector_product_end[];

extern uint8_t dsp_matrix_copy[];
extern uint8_t dsp_matrix_copy_end[];
extern Matrix44 *M_CopyDestination;
extern Matrix44 *M_CopySource;

extern Matrix44 *dsp_matrix_ptr_m1;
extern Matrix44 *dsp_matrix_ptr_m2;

/* Matrix operand storage */
extern Matrix44 dsp_matrix_operand_1;
extern Matrix44 dsp_matrix_operand_2;
extern Matrix44 dsp_matrix_result;
extern Vector3FX dsp_matrix_vector;

extern Matrix44 *dsp_matrix_ptr_result;

/* Vector operand storage */
extern Vector3FX dsp_vector_operand_1;
extern Vector3FX dsp_vector_operand_2;
extern Vector3FX dsp_vector_result;

#endif
