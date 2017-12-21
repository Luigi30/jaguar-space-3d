#ifndef PALDATA_H
#define PALDATA_H

#include "stdio.h"
#include "jaglib.h"

static uint8_t PaletteCount = 0;

typedef struct rgbcolor_t {
	uint8_t r, g, b;
} RGBColor;

typedef struct palette_t {
	RGBColor colors[256];
} Palette;

extern uint8_t vga_palettes[];
extern uint8_t vga_palettes_end[];

extern Palette *jaguar_palettes;

void PALETTES_initialize();
void PALETTES_select(uint8_t palette_num);
void PALETTES_load_from_array(uint16_t *colordata);

#endif