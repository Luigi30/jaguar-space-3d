#include "gpu.h"
#include "jaglib.h"

Vector4FX *tri_ndc_1;
Vector4FX *tri_ndc_2;
Vector4FX *tri_ndc_3;

void GPU_LOAD_LINEDRAW_PROGRAM() {
  //skunkCONSOLEWRITE("GPU_LOAD_LINEDRAW_PROGRAM(): beginning upload.\n");
  int bytes = 4096;
  memcpy(G_RAM, blit_triangle_program_start, bytes);
  //skunkCONSOLEWRITE("GPU_LOAD_LINEDRAW_PROGRAM(): upload complete\n");
}

void GPU_LOAD_MMULT_PROGRAM() {
	int bytes = 4096;
	//sprintf(skunkoutput, "GPU_LOAD_MMULT_PROGRAM(): Uploading %d bytes at %p to %p\n", bytes, gpu_matrix_multiply_program_start, G_RAM);	
	//skunkCONSOLEWRITE(skunkoutput);
	memcpy(G_RAM, gpu_matrix_multiply_program_start, bytes);
	//skunkCONSOLEWRITE("GPU_LOAD_MMULT_PROGRAM(): upload complete\n");
}

void GPU_START(uint8_t *function) {
	MMIO32(G_PC) = (uint32_t)(0xF03000 + function - blit_wireframe_triangle);  
	MMIO32(G_CTRL) = MMIO32(G_CTRL) | 0x01;
}

void GPU_MMULT_START() {
	MMIO32(G_PC) = (uint32_t)(0xF03000);  
	MMIO32(G_CTRL) = MMIO32(G_CTRL) | 0x01;
}

#define BUILD_TRANSFORMATION (0xF03000 + gpu_build_transformation_matrix - gpu_matrix_multiply)
void GPU_BUILD_TRANSFORMATION_START() {
	MMIO32(G_PC) = (uint32_t)(BUILD_TRANSFORMATION);
	MMIO32(G_CTRL) = MMIO32(G_CTRL) | 0x01;
}

#define PROJECT_AND_DRAW_TRIANGLE (0xF03000 + gpu_project_and_draw_triangle - blit_wireframe_triangle)
void GPU_PROJECT_AND_DRAW_TRIANGLE() {
	MMIO32(G_PC) = (uint32_t)(PROJECT_AND_DRAW_TRIANGLE);
	MMIO32(G_CTRL) = MMIO32(G_CTRL) | 0x01;
}

#define MATRIX_ROTATION_ENTRY (0xF03000 + gpu_matrix_rotation_entry - gpu_matrix_multiply)
void GPU_ROTATION_MATRIX_ENTRY() {
	MMIO32(G_PC) = (uint32_t)(MATRIX_ROTATION_ENTRY);
	MMIO32(G_CTRL) = MMIO32(G_CTRL) | 0x01;
}

#define GPU_WAIT() ( jag_gpu_wait() )

/* GPU routines! */
uint32_t line_clut_color;

void gpu_blit_triangle(Vector3FX *vertexes, uint32_t color)
{
	jag_gpu_wait(); //wait for any operations in progress to finish

	ptr_vertex_array = vertexes;
	line_clut_color = color;

	GPU_START(blit_wireframe_triangle);
}
