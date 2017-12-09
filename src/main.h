#include <jaglib.h>
#include <jagcore.h>

#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <time.h>

#include "matrix.h"
#include "shared.h"

#include "gfx/blit.h"
#include "gfx/palette.h"

#include "utils/list.h"

#include "images.h"
#include "mobj.h"
#include "fixed.h"

#include "gpu.h"

#define FILL_LONG_WITH_BYTE(b) (b<<24 | b<<16 | b<<8 | b)

#define SCREEN_WIDTH  320
#define SCREEN_HEIGHT 200

extern void DSP_LoadSoundEngine();
extern void DSP_StartSoundEngine();
extern void DSP_PlayModule();

typedef struct shape_t {
  Vector3FX translation, rotation, scale;
  Vector3FX **triangles;	//Pointer to the triangles array of the shape.
} Shape;

/* background pixel buffers - 8bpp */
uint8_t background_frame_0[SCREEN_WIDTH * SCREEN_HEIGHT];
uint8_t background_frame_1[SCREEN_WIDTH * SCREEN_HEIGHT];
uint8_t *front_buffer;
uint8_t *back_buffer;

/* text buffer - 1bpp */
uint8_t text_buffer[(SCREEN_WIDTH * SCREEN_HEIGHT) / 8];

/* sprite buffer - 1bpp */
uint8_t sprite_buffer[(SCREEN_WIDTH * SCREEN_HEIGHT)];

//GPU programs
extern uint8_t blank_screen[];
extern uint8_t blank_screen_end[];

extern uint8_t create_scanline_table[];
extern uint8_t create_scanline_table_end[];

//Filled in by the GPU. Each entry is the pixel offset of the scanline N.
uint32_t scanline_offset_table[200];

MotionObject mobj_background;
MotionObject mobj_font;
MotionObject mobj_sprites;

Matrix44 *m, *mTranslation, *mRotation, *mCamera, *mView, *mPerspective, *mModel;

Vector3FX *mvp_vector, *mvp_result;
Matrix44 *mvp_matrix;

Vector3FX VIEW_EYE, VIEW_CENTER, VIEW_UP;

/*
 * TOM REGISTERS
 */

#define HC    		(vuint16_t *)(BASE+4)		/* Horizontal Count */
#define VC    		(vuint16_t *)(BASE+6)		/* Vertical Count */
#define LPH   		(vuint16_t *)(BASE+8)		/* Horizontal Lightpen */
#define LPV   		(vuint16_t *)(BASE+0x0A)	/* Vertical Lightpen */
#define OB0   		(vuint16_t *)(BASE+0x10)	/* Current Object Phrase */
#define OB1   		(vuint16_t *)(BASE+0x12)
#define OB2   		(vuint16_t *)(BASE+0x14)
#define OB3   		(vuint16_t *)(BASE+0x16)
#define OLP   		(vuint32_t *)(BASE+0x20)	/* Object List Pointer */
#define OBF   		(vuint16_t *)(BASE+0x26)	/* Object Processor Flag */
#define VMODE 		(vuint16_t *)(BASE+0x28)	/* Video Mode */
#define BORD1 		(vuint16_t *)(BASE+0x2A)	/* Border Color (Red & Green) */
#define BORD2 		(vuint16_t *)(BASE+0x2C)	/* Border Color (Blue) */
#define HP			(vuint16_t *)(BASE+0x2E)
#define HBB			(vuint16_t *)(BASE+0x30)
#define HBE			(vuint16_t *)(BASE+0x32)
#define HS			(vuint16_t *)(BASE+0x34)
#define HVS			(vuint16_t *)(BASE+0x36)
#define HDB1  		(vuint16_t *)(BASE+0x38)	/* Horizontal Display Begin One */
#define HDB2  		(vuint16_t *)(BASE+0x3A)	/* Horizontal Display Begin Two */
#define HDE   		(vuint16_t *)(BASE+0x3C)	/* Horizontal Display End */
#define VP			(vuint16_t *)(BASE+0x3E)
#define VBB			(vuint16_t *)(BASE+0x40)
#define VBE			(vuint16_t *)(BASE+0x42)
#define VS    		(vuint16_t *)(BASE+0x44)	/* Vertical Sync */
#define VDB   		(vuint16_t *)(BASE+0x46)	/* Vertical Display Begin */
#define VDE   		(vuint16_t *)(BASE+0x48)	/* Vertical Display End */
#define VEB			(vuint16_t *)(BASE+0x4A)
#define VEE			(vuint16_t *)(BASE+0x4C)
#define VI    		(vuint16_t *)(BASE+0x4E)	/* Vertical Interrupt */
#define PIT0  		(vuint16_t *)(BASE+0x50)	/* Programmable Interrupt Timer (Lo) */
#define PIT1  		(vuint16_t *)(BASE+0x52)	/* Programmable Interrupt Timer (Hi) */
#define BG    		(vuint16_t *)(BASE+0x58)	/* Background Color */

#define INT1  		(vuint16_t *)(BASE+0xE0)	/* CPU Interrupt Control Register */
#define INT2  		(vuint16_t *)(BASE+0xE2)	/* CPU Interrupt Resume Register */

#define CLUT  		(vuint16_t *)(BASE+0x400)	/* Color Lookup Table */

#define LBUFA 		(vuint32_t *)(BASE+0x800)	/* Line Buffer A */
#define LBUFB 		(vuint32_t *)(BASE+0x1000)	/* Line Buffer B */
#define LBUFC 		(vuint32_t *)(BASE+0x1800)	/* Line Buffer Current */
