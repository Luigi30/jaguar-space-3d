#ifndef BLIT_H
#define BLIT_H

#include <jaglib.h>
#include <jagcore.h>

#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <time.h>

#include "shared.h"
#include "fixed.h"

#define BLIT_XY(x,y) ( (vuint32_t)( (y << 16) | x ) )

#define SWAP(T, a, b) do { T tmp = a; a = b; b = tmp; } while (0)

extern uint8_t BLITTER_LOCK_CPU;
extern uint8_t BLITTER_LOCK_GPU;
extern uint8_t BLITTER_LOCK_ALLOW;

void BLIT_init_blitter();

void BLIT_16x16_text_string(uint8_t *destination, uint16_t x, uint16_t y, char *str);
void BLIT_8x8_text_string(uint8_t *destination, uint16_t x, uint16_t y, char *str);

void BLIT_8x8_font_glyph(uint8_t *destination, uint16_t x, uint16_t y, uint8_t *source, uint8_t c);
void BLIT_16x16_font_glyph(uint8_t *destination, uint16_t x, uint16_t y, uint8_t *source, uint8_t c);

void BLIT_rectangle_solid(uint8_t *buffer, uint16_t topleft_x, uint16_t topleft_y, uint16_t width, uint16_t height, uint64_t pattern);
void BLIT_line(uint8_t *buffer, uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2, uint16_t color_index);

#endif
