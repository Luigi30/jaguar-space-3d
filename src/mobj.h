#ifndef MOBJ_H
#define MOBJ_H

#include <stdio.h>
#include <jaglib.h>
#include <jagcore.h>

#include "images.h"

/* Animation */
typedef struct mobj_animation_frame_t {
	struct mobj_animation_frame_t *next;
	uint16_t framecounter_mod;
	uint8_t *pixel_data;
} MOBJ_Animation_Frame;

MOBJ_Animation_Frame *AnimationFrame_Create(MOBJ_Animation_Frame *_next, uint16_t _framecounter_mod, uint8_t *_pixel_data);

/* MOBJ */
typedef struct mobj_position_t {
	int16_t x, y;
} MOBJ_Position;

typedef struct mobj_t {
	struct mobj_t *next;
	
	op_bmp_object *graphic;
	MOBJ_Animation_Frame *animations;
	MOBJ_Animation_Frame *currentAnimation;
	MOBJ_Position position;
	
	uint16_t pxHeight;
	uint16_t pxWidth;
	
	uint64_t objType;
} MotionObject;

//Alloc and free
MotionObject *MOBJ_Alloc();
void MOBJ_Free(MotionObject *mobj);

//Debugging
void MOBJ_Print_Position(MotionObject *mobj);

#endif
