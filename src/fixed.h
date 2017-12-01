#ifndef FIXED_H
#define FIXED_H

#include <jaglib.h>
#include <jagcore.h>

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>

#include "shared.h"

/*                                                                                                                                          
	The blitter uses unsigned 32-bit fixed-point numbers for subpixel precision. No FPU!
	FIXED_32
	31...16 == integer component
	15...0  == fractional component
*/
/* FIXED_INT: uint16_t containing the integer component of a FIXED_32 */
#define FIXED_INT(x)   ( (int16_t)( (x & 0xFFFF0000) >> 16 ) )
/* FIXED_FRAC: uint16_t containing the fractional component of a FIXED_32 */
#define FIXED_FRAC(x)  ( (uint16_t)( x & 0xFFFF ) )
/* INT_TO_FIXED: convert a uint16_t to a FIXED_32 */
#define INT_TO_FIXED(x) ( (uint32_t)(x << 16) )

typedef uint32_t FIXED_32;

typedef struct vector3fx_t {
	FIXED_32 x, y, z;
} Vector3FX;

typedef struct vector4fx_t {
	FIXED_32 x, y, z, w;
} Vector4FX;

Vector3FX Vector3FX_Normalize(Vector3FX v);
Vector3FX Vector3FX_CrossProduct(Vector3FX a, Vector3FX b);

FIXED_32 FIXED_ADD(FIXED_32 a, FIXED_32 b);
FIXED_32 FIXED_SUB(FIXED_32 a, FIXED_32 b);
FIXED_32 FIXED_MUL(FIXED_32 a, FIXED_32 b);
FIXED_32 FIXED_DIV(const FIXED_32 a, const FIXED_32 b);
FIXED_32 FIXED_SQRT(FIXED_32 val);

void FIXED_PRINT(FIXED_32 val);

/* Lookup tables */

extern FIXED_32 FIXED_SINE_TABLE[];
extern FIXED_32 FIXED_COSINE_TABLE[];

#endif
