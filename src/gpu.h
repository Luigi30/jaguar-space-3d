#ifndef GPU_H
#define GPU_H

#include <jagcore.h>

#include "shared.h"
#include "fixed.h"
#include <stdio.h>
#include <stdint.h>
#include <string.h>

void GPU_LOAD_LINEDRAW_PROGRAM();
void GPU_LOAD_MMULT_PROGRAM();
void GPU_START(uint8_t *function);
void GPU_MMULT_START();

extern char skunkoutput[128];

extern uint8_t blit_wireframe_triangle[];
extern uint8_t blit_wireframe_triangle_end[];

extern uint8_t blit_triangle_program_start[];

extern uint16_t Line_X1;
extern uint16_t Line_X2;
extern uint16_t Line_Y1;
extern uint16_t Line_Y2;
extern uint32_t line_x1_value;
extern uint32_t line_x2_value;
extern uint32_t line_y1_value;
extern uint32_t line_y2_value;
extern uint32_t line_clut_color;
void gpu_blit_triangle(Vector3FX *vertexes, uint32_t color);

extern uint8_t gpu_matrix_multiply_program_start[];
extern uint8_t gpu_matrix_multiply_program_end[];

extern const uint8_t gpu_matrix_multiply[];
extern const uint8_t gpu_matrix_multiply_end[];

typedef struct matrix44_t Matrix44;
extern Matrix44 gpu_matrix_operand_1;
extern Matrix44 gpu_matrix_operand_2;
extern Matrix44 gpu_matrix_result;

extern Vector3FX *ptr_vertex_array;

void GPU_BUILD_TRANSFORMATION_START();
extern const uint8_t gpu_build_transformation_matrix[];
extern const uint8_t gpu_build_transformation_matrix_end[];

extern Matrix44 *gpu_ptr_translation_matrix;
extern Matrix44 *gpu_ptr_rotation_matrix;
extern Matrix44 *gpu_ptr_camera_matrix;
extern Matrix44 *gpu_ptr_transformation_matrix;

/* Object drawing */
extern Matrix44 *object_M;
extern Vector3FX **object_Triangle;

void GPU_PROJECT_AND_DRAW_TRIANGLE();

extern const uint8_t gpu_project_and_draw_triangle[];
extern const uint8_t gpu_project_and_draw_triangle_end[];

extern Vector4FX gpu_tri_point_1;
extern Vector4FX gpu_tri_point_2;
extern Vector4FX gpu_tri_point_3;

extern uint32_t gpu_tri_facing_ratio;

extern Vector4FX *tri_ndc_1;
extern Vector4FX *tri_ndc_2;
extern Vector4FX *tri_ndc_3;

#endif
