#ifndef SHARED_H
#define SHARED_H

#include <jaglib.h>

#define VECTOR3FX_CREATE(a,b,c) (Vector3FX){ .x = INT_TO_FIXED(a), .y = INT_TO_FIXED(b), .z = INT_TO_FIXED(c) }
#define VERTEX_CREATE(a,b,c) { .x = INT_TO_FIXED(a), .y = INT_TO_FIXED(b), .z = INT_TO_FIXED(c) }

#define MIN(a,b) (((a)<(b))?(a):(b))
#define MAX(a,b) (((a)>(b))?(a):(b))

#define MMIO16(x)   (*(vuint16_t *)(x))
#define MMIO32(x)   (*(vuint32_t *)(x))
#define MMIO64(x)   (*(vuint64_t *)(x))

#define BRANCH_CC_EQ 0
#define BRANCH_CC_LT 1
#define BRANCH_CC_GT 2
#define BRANCH_CC_OPFLAG 3

extern void WriteEmuLog(__reg("d0") unsigned char c);

typedef struct coordinate_t {
  uint16_t x, y;
} Coordinate;

typedef Coordinate Size2D;

typedef struct spritegraphic_t {
  char name[16];
  Coordinate location; //Upper left coordinate of the sprite on the sheet
  Size2D size;         //Size of the sprite.
} SpriteGraphic;

 /* STOP object ends the object list */
 extern op_stop_object *stopobj;

#endif
