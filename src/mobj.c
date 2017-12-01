#include "mobj.h"

//Debugging
void MOBJ_Print_Position(MotionObject *mobj) {
	jag_console_set_cursor(0,0);
	printf("X: %4d", mobj->position.x);
	jag_console_set_cursor(0,8);
	printf("Y: %4d", mobj->position.y);
}

MOBJ_Animation_Frame *AnimationFrame_Create(MOBJ_Animation_Frame *_next, uint16_t _framecounter_mod, uint8_t *_pixel_data)
{
	MOBJ_Animation_Frame *frame = calloc(1, sizeof(MOBJ_Animation_Frame));
	
	frame->framecounter_mod = _framecounter_mod;
	frame->pixel_data = _pixel_data;
	frame->next = _next;
	
	return frame;
}

/* Alloc and free */
MotionObject *MOBJ_Alloc() {
	return calloc(1, sizeof(MotionObject));
}

void MOBJ_Free(MotionObject *mobj) {
	if(mobj != NULL) {
		free(mobj);	
	}
}
