#include "gpu.h"
#include "jaglib.h"

void GPU_LOAD_LINEDRAW_PROGRAM() {
  skunkCONSOLEWRITE("GPU_LOAD_LINEDRAW_PROGRAM(): beginning upload.\n");
  jag_memcpy32p(G_RAM, blit_triangle, 1, 1024);
  jag_wait_blitter_ready();
  skunkCONSOLEWRITE("GPU_LOAD_LINEDRAW_PROGRAM(): upload complete\n");
}

void GPU_LOAD_MMULT_PROGRAM() {
  skunkCONSOLEWRITE("GPU_LOAD_MMULT_PROGRAM(): beginning upload.\n");
  jag_memcpy32p(G_RAM, gpu_matrix_multiply_program_start, 1, 1024);
  jag_wait_blitter_ready();
  skunkCONSOLEWRITE("GPU_LOAD_MMULT_PROGRAM(): upload complete\n");
}

void GPU_START(uint8_t *function) {
	MMIO32(G_PC) = (uint32_t)(0xF03000 + function - blit_triangle);  
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

#define GPU_WAIT() ( jag_gpu_wait() )

/* GPU routines! */
uint32_t line_clut_color;

void gpu_blit_triangle(Vector3FX *vertexes, uint32_t color)
{
	jag_gpu_wait(); //wait for any operations in progress to finish

	ptr_vertex_array = vertexes;
	line_clut_color = color;

	GPU_START(blit_triangle);
}