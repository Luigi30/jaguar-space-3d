#include "gfx/blit.h"

#include "images.h"

enum BLITTER_LOCK_TURN { BLITTER_ALLOW_CPU, BLITTER_ALLOW_GPU };

uint8_t BLITTER_LOCK_CPU = false; //is the blitter locked by the CPU?
uint8_t BLITTER_LOCK_GPU = false; //is the blitter locked by the GPU?
uint8_t BLITTER_LOCK_ALLOW = BLITTER_ALLOW_CPU;

void BLIT_16x16_text_string(uint8_t *destination, uint16_t x, uint16_t y, char *str)
{
  for(int i=0;i<strlen(str);i++)
    {      
      BLIT_16x16_font_glyph(destination, x, y, atarifont, str[i]);
      x += 16;
    }
}

void BLIT_8x8_text_string(uint8_t *destination, uint16_t x, uint16_t y, char *str)
{
  for(int i=0;i<strlen(str);i++)
    {      
      BLIT_8x8_font_glyph(destination, x, y, atarifont8x8, str[i]);
      x += 8;
    }
}

/* Font blitting */
void BLIT_16x16_font_glyph(uint8_t *destination, uint16_t x, uint16_t y, uint8_t *source, uint8_t c)
{
  //Blit a glyph from an 16x16 font sheet.
  //A sheet is 256x256px = 16x16 glyphs.

  BLITTER_LOCK_CPU = true;
  BLITTER_LOCK_ALLOW = BLITTER_ALLOW_CPU;
  while(BLITTER_LOCK_GPU && BLITTER_LOCK_ALLOW == BLITTER_ALLOW_CPU)
    {
      skunkCONSOLEWRITE("BLIT_16x16_font_glyph: Blitter is locked by GPU\n");
    }
  
  jag_gpu_wait();
  jag_wait_blitter_ready();

  uint16_t source_x = (c * 16) % 256;
  uint16_t source_y = (c & 0xF0) + 128;
  
  MMIO32(A1_BASE)   = (long)destination;
  MMIO32(A1_PIXEL)  = BLIT_XY(x, y);
  MMIO32(A1_FPIXEL) = 0;
  MMIO32(A1_FLAGS)  = PITCH1 | PIXEL1 | WID320 | XADDPIX | YADD0;
  MMIO32(A1_STEP)   = BLIT_XY(320-16, 0);
  
  MMIO32(A2_BASE)   = (long)source;
  MMIO32(A2_PIXEL)  = BLIT_XY(source_x, source_y);
  MMIO32(A2_STEP)   = BLIT_XY(256-16, 0);
  MMIO32(A2_FLAGS)  = PITCH1 | PIXEL1 | WID256 | XADDPIX | YADD0;
  
  MMIO32(B_COUNT)   = BLIT_XY(16, 16);

  //SRCEN and DSTEN must be enabled for blits below 8bpp
  MMIO32(B_CMD)     = SRCEN | DSTEN | UPDA1 | UPDA2 | LFU_REPLACE;

  BLITTER_LOCK_CPU = false;
}

void BLIT_8x8_font_glyph(uint8_t *destination, uint16_t x, uint16_t y, uint8_t *source, uint8_t c)
{
  //Blit a glyph from an 8x8 font sheet.
  //A sheet is 128x128px = 16x16 glyphs.

  BLITTER_LOCK_CPU = true;
  BLITTER_LOCK_ALLOW = BLITTER_ALLOW_CPU;
  while(BLITTER_LOCK_GPU && BLITTER_LOCK_ALLOW == BLITTER_ALLOW_CPU)
    {
      skunkCONSOLEWRITE("BLIT_8x8_font_glyph: Blitter is locked by GPU\n");
    }
  
  jag_gpu_wait();
  jag_wait_blitter_ready();

  uint16_t source_x = (c * 8) % 128;
  uint16_t source_y = (8 * ((c & 0xF0) >> 4));
  
  MMIO32(A1_BASE)   = (long)destination;
  MMIO32(A1_PIXEL)  = BLIT_XY(x, y);
  MMIO32(A1_FPIXEL) = 0;
  MMIO32(A1_FLAGS)  = PITCH1 | PIXEL1 | WID320 | XADDPIX | YADD0;
  MMIO32(A1_STEP)   = BLIT_XY(320-8, 0);
  
  MMIO32(A2_BASE)   = (long)source;
  MMIO32(A2_PIXEL)  = BLIT_XY(source_x, source_y);
  MMIO32(A2_STEP)   = BLIT_XY(128-8, 0);
  MMIO32(A2_FLAGS)  = PITCH1 | PIXEL1 | WID128 | XADDPIX | YADD0;
  
  MMIO32(B_COUNT)   = BLIT_XY(8, 8);

  //SRCEN and DSTEN must be enabled for blits below 8bpp
  MMIO32(B_CMD)     = SRCEN | DSTEN | UPDA1 | UPDA2 | LFU_REPLACE;

  BLITTER_LOCK_CPU = false;
}

void BLIT_rectangle_solid(uint8_t *buffer, uint16_t topleft_x, uint16_t topleft_y, uint16_t width, uint16_t height, uint64_t pattern)
{
  BLITTER_LOCK_CPU = true;
  BLITTER_LOCK_ALLOW = BLITTER_ALLOW_CPU;
  while(BLITTER_LOCK_GPU && BLITTER_LOCK_ALLOW == BLITTER_ALLOW_CPU)
    {
      skunkCONSOLEWRITE("BLIT_rectangle_solid: Blitter is locked by GPU\n");
    }
  
  jag_wait_blitter_ready(); //don't do this until the blitter is available
  
  MMIO32(A1_BASE)	= (long)buffer;
  MMIO32(A1_PIXEL)	= BLIT_XY(topleft_x, topleft_y);
  MMIO32(A1_FPIXEL)	= 0;
  MMIO32(A1_INC)	= BLIT_XY(1, 0);
  MMIO32(A1_FINC)	= 0;
  MMIO32(A1_FLAGS)	= PITCH1 | PIXEL8 | WID320 | XADDPHR | YADD0;
  MMIO32(A1_STEP)	= BLIT_XY(CONSOLE_BMP_WIDTH-width, 0);
  MMIO64(B_PATD)	= pattern;
  MMIO32(B_COUNT)	= BLIT_XY(width, height);
  MMIO32(B_CMD)		= PATDSEL | UPDA1 | LFU_S;

  BLITTER_LOCK_CPU = false;
}

void BLIT_line(uint8_t *buffer, uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2, uint16_t color_index)
{	
  if(x1 > x2) //Swap the coordinates so we always go left to right.
    {
      SWAP(uint16_t, x1, x2);
      SWAP(uint16_t, y1, y2);
    }

  uint16_t x_distance = abs(x2-x1);
  uint16_t y_distance = abs(y2-y1);
  bool y_negative;
	
  if((y2 - y1) < 0) {
    y_negative = true;
  } else {
    y_negative = false;
  }
	
  FIXED_32 slope = FIXED_DIV(INT_TO_FIXED(x_distance), INT_TO_FIXED(y_distance));
	
  MMIO32(A1_BASE)	= (long)buffer;
  MMIO32(A1_PIXEL)	= BLIT_XY(x1, y1);
  MMIO32(A1_FPIXEL)	= 0;
  MMIO32(A1_INC)	= BLIT_XY(FIXED_INT(slope), 0);
  MMIO32(A1_FINC)	= BLIT_XY(FIXED_FRAC(slope), 0);
  MMIO32(A1_FLAGS)	= PITCH1 | PIXEL8 | WID320 | XADDINC;
	
  if(y_negative) 
    {
      MMIO32(A1_STEP)	= BLIT_XY(0,-1);
    }
  else
    {
      MMIO32(A1_STEP)	= BLIT_XY(0,1);
    }
	
  MMIO32(B_PATD)		= color_index;
  MMIO32(B_COUNT)		= BLIT_XY(1, y_distance+1);
  MMIO32(B_CMD)		= PATDSEL | UPDA1 | UPDA1F | LFU_S;
}

void BLIT_init_blitter(){
  //Clear the data registers
  MMIO32(B_SRCD) = 0;
  MMIO32(B_DSTD) = 0;
  MMIO32(B_DSTZ) = 0;
  MMIO32(B_SRCZ1) = 0;
  MMIO32(B_SRCZ2) = 0;
  MMIO32(B_PATD) = 0;
  MMIO32(B_IINC) = 0;
  MMIO32(B_ZINC) = 0;
  MMIO32(B_STOP) = 0;
  MMIO32(B_I3) = 0;
  MMIO32(B_I2) = 0;
  MMIO32(B_I1) = 0;
  MMIO32(B_I0) = 0;
  MMIO32(B_Z3) = 0;
  MMIO32(B_Z2) = 0;
  MMIO32(B_Z1) = 0;
  MMIO32(B_Z0) = 0;

  MMIO32(A1_BASE) = 0;
  MMIO32(A1_FLAGS) = 0;
  MMIO32(A1_CLIP) = 0;
  MMIO32(A1_PIXEL) = 0;
  MMIO32(A1_STEP) = 0;
  MMIO32(A1_FSTEP) = 0;
  MMIO32(A1_FPIXEL) = 0;
  MMIO32(A1_INC) = 0;
  MMIO32(A1_FINC) = 0;
  
  MMIO32(A2_BASE) = 0;
  MMIO32(A2_FLAGS) = 0;
  MMIO32(A2_MASK) = 0;
  MMIO32(A2_PIXEL) = 0;
  MMIO32(A2_STEP) = 0;
}
