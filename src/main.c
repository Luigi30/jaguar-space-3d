/* Note: All malloc() objects or anything on the heap is phrase-aligned.
   Objects on the stack are word-aligned. */

#include "main.h"
#include <stdbool.h>

#include "cube.h"

Vector3FX cameraTranslation;

Matrix44 *object_M;
Vector3FX **object_Triangle;

Shape *shape_Current;

extern uint32_t gpu_register_dump[32];

char skunkoutput[256];

bool GPU_loaded = false;

op_stop_object *make_stopobj() {	
  op_stop_object *stopobj = calloc(1,sizeof(op_stop_object));
  stopobj->type = STOPOBJ;
  stopobj->int_flag = 1;
  return stopobj;
}
op_stop_object *stopobj;

void OP_ResetObjects()
{
  //The height field needs to be reset each frame for each mobj. Thanks Atari.
  mobj_background.graphic->p0.height = 200;
  mobj_sprites.graphic->p0.height = 200;
  mobj_font.graphic->p0.height = 200;

  mobj_background.graphic->p0.data = (uint32_t)front_buffer >> 3;
  mobj_sprites.graphic->p0.data = (uint32_t)sprite_buffer >> 3;
  mobj_font.graphic->p0.data = (uint32_t)text_buffer >> 3;
}

uint16_t jag_custom_interrupt_handler()
{
  if (*INT1&C_VIDENA)
    {      
      MMIO16(INT2) = 0;
	  OP_ResetObjects();
      return C_VIDCLR;
    }
  return 0;
}

void clear_video_buffer(uint8_t *buffer){
  BLIT_rectangle_solid(buffer, 0, 0, 320, 200, 0);
}

int main() {
  //set correct endianness
  MMIO32(G_END) = 0x00070007;
  
  DSP_LoadSoundEngine();
  DSP_StartSoundEngine();
  //DSP_PlayModule();
  
  GPU_LOAD_MMULT_PROGRAM(); //Switch GPU to matrix operations
  
  srand(8675309);
  jag_console_hide();
  
  MMIO32(0x60000) = 0x00000000;
  
  //BLIT_init_blitter();
  BLITTER_LOCK_CPU = false;
  BLITTER_LOCK_GPU = false;
  
  skunkCONSOLEWRITE("Connected to PC.\n");
  
  GPU_loaded = true;
  
  front_buffer = background_frame_0;
  back_buffer = background_frame_1;

  //Text layer color
  jag_set_indexed_color(254, toRgb16(0,0,0));
  jag_set_indexed_color(255, toRgb16(200, 200, 200));

  BLIT_8x8_text_string(text_buffer, 32, 16, "                   ");

  stopobj = make_stopobj();

  mobj_background.graphic = calloc(1,sizeof(op_bmp_object));

  /* Font bitmap thingy */
  {
    mobj_font.graphic = calloc(1,sizeof(op_bmp_object));
    mobj_font.objType = BITOBJ;
    mobj_font.position.x = 19;
    mobj_font.position.y = 80;
    mobj_font.pxWidth = 320;
    mobj_font.pxHeight = 200;
    
    mobj_font.animations = NULL;
    
    mobj_font.graphic->p0.type	= mobj_font.objType;	       	/* BITOBJ = bitmap object */
    mobj_font.graphic->p0.ypos	= mobj_font.position.y;         /* YPOS = Y position on screen "in half-lines" */
    mobj_font.graphic->p0.height = mobj_font.pxHeight;	        /* in pixels */
    mobj_font.graphic->p0.link	= (uint32_t)stopobj >> 3;	/* link to next object */
    mobj_font.graphic->p0.data	= (uint32_t)text_buffer >> 3;	/* ptr to pixel data */
    mobj_font.graphic->p1.xpos	= mobj_font.position.x;         /* X position on screen, -2048 to 2047 */
    mobj_font.graphic->p1.depth	= O_DEPTH1 >> 12;		/* pixel depth of object */
    mobj_font.graphic->p1.pitch	= 1;				/* 8 * PITCH is added to each fetch */
    mobj_font.graphic->p1.dwidth= mobj_font.pxWidth / 64;	/* pixel data width in 8-byte phrases */
    mobj_font.graphic->p1.iwidth= mobj_font.pxWidth / 64;	/* image width in 8-byte phrases, for clipping */	
    mobj_font.graphic->p1.release= 0;				/* bus mastering, set to 1 when low-depth */
    mobj_font.graphic->p1.trans  = 1;				/* makes color 0 transparent */
    mobj_font.graphic->p1.index  = 127;
  }

  skunkCONSOLEWRITE("font layer initialized\n");

  /* Sprite layer */
  {
    mobj_sprites.graphic = calloc(1,sizeof(op_bmp_object));
    mobj_sprites.objType = BITOBJ;
    mobj_sprites.position.x = 19;
    mobj_sprites.position.y = 80;
    mobj_sprites.pxWidth = 320;
    mobj_sprites.pxHeight = 200;
    
    mobj_sprites.animations = NULL;
    
    mobj_sprites.graphic->p0.type	= mobj_sprites.objType;	       	/* BITOBJ = bitmap object */
    mobj_sprites.graphic->p0.ypos	= mobj_sprites.position.y;      /* YPOS = Y position on screen "in half-lines" */
    mobj_sprites.graphic->p0.height     = mobj_sprites.pxHeight;	        /* in pixels */
    mobj_sprites.graphic->p0.link	= (uint32_t)mobj_font.graphic >> 3;	/* link to next object */
    mobj_sprites.graphic->p0.data	= (uint32_t)sprite_buffer >> 3;	/* ptr to pixel data */
    mobj_sprites.graphic->p1.xpos	= mobj_sprites.position.x;      /* X position on screen, -2048 to 2047 */
    mobj_sprites.graphic->p1.depth	= O_DEPTH8 >> 12;		/* pixel depth of object */
    mobj_sprites.graphic->p1.pitch	= 1;				/* 8 * PITCH is added to each fetch */
    mobj_sprites.graphic->p1.dwidth     = mobj_sprites.pxWidth / 8;	/* pixel data width in 8-byte phrases */
    mobj_sprites.graphic->p1.iwidth     = mobj_sprites.pxWidth / 8;	/* image width in 8-byte phrases, for clipping */	
    mobj_sprites.graphic->p1.release= 0;				/* bus mastering, set to 1 when low-depth */
    mobj_sprites.graphic->p1.trans  = 1;				/* makes color 0 transparent */
    mobj_sprites.graphic->p1.index  = 0;
  }

   /* Background */
  {
    mobj_background.objType = BITOBJ;
    mobj_background.position.x = 19;
    mobj_background.position.y = 80;
    mobj_background.pxWidth = 320;
    mobj_background.pxHeight = 200;
    
    mobj_background.graphic->p0.type	= mobj_background.objType;	/* BITOBJ = bitmap object */
    mobj_background.graphic->p0.ypos	= mobj_background.position.y;   /* YPOS = Y position on screen "in half-lines" */
    mobj_background.graphic->p0.height  = mobj_background.pxHeight;	/* in pixels */
    mobj_background.graphic->p0.link	= (uint32_t)mobj_sprites.graphic >> 3;	/* link to next object */
    mobj_background.graphic->p0.data	= (uint32_t)front_buffer >> 3;	/* ptr to pixel data */
    
    mobj_background.graphic->p1.xpos	= mobj_background.position.x;      /* X position on screen, -2048 to 2047 */
    mobj_background.graphic->p1.depth	= O_DEPTH8 >> 12;		/* pixel depth of object */
    mobj_background.graphic->p1.pitch	= 1;				/* 8 * PITCH is added to each fetch */
    mobj_background.graphic->p1.dwidth  = mobj_background.pxWidth / 8;	/* pixel data width in 8-byte phrases */
    mobj_background.graphic->p1.iwidth  = mobj_background.pxWidth / 8;	/* image width in 8-byte phrases, for clipping */	
    mobj_background.graphic->p1.release= 0;				/* bus mastering, set to 1 when low-depth */
    mobj_background.graphic->p1.trans  = 1;				/* makes color 0 transparent */
    mobj_background.graphic->p1.index  = 0;
  }

	skunkCONSOLEWRITE("background layer initialized\n");

	//Start the list here.
	jag_attach_olp(mobj_background.graphic);

	skunkCONSOLEWRITE("object list attached\n");
		
	uint32_t stick0, stick0_lastread;
	uint16_t framecounter = 0;
	uint32_t framenumber = 0;

	//Init cube
	Shape cube;
	cube.translation = (Vector3FX){ .x = INT_TO_FIXED(0), .y = INT_TO_FIXED(0), .z = INT_TO_FIXED(0) };
	cube.rotation    = (Vector3FX){ .x = INT_TO_FIXED(0), .y = INT_TO_FIXED(0), .z = INT_TO_FIXED(0) };
	cube.scale       = (Vector3FX){ .x = INT_TO_FIXED(1), .y = INT_TO_FIXED(1), .z = INT_TO_FIXED(1) };
	cube.triangles = cube_triangles;

	//Init transformation matrix
	m = calloc(1, sizeof(Matrix44));
	mTranslation = calloc(1, sizeof(Matrix44));
	mRotation = calloc(1, sizeof(Matrix44));
	mModel = calloc(1, sizeof(Matrix44));

	mPerspective = calloc(1, sizeof(Matrix44));
	buildPerspectiveMatrix(mPerspective);

	skunkCONSOLEWRITE("Entering main loop.\n");

	//Init Matrix44_VectorProduct
	mvp_vector = calloc(1, sizeof(Vector3FX));
	mvp_matrix = calloc(1, sizeof(Matrix44));
	mvp_result = calloc(1, sizeof(Vector3FX));
	
	mView = calloc(1, sizeof(Matrix44));
	mViewTranslate = calloc(1, sizeof(Matrix44));
	
	Vector3FX transformedVertexList[4];
	
	//Init view parameters
	VIEW_EYE 	= (Vector3FX){ 0x00000000, 0x00000000, 0x00040000 };
	VIEW_CENTER = (Vector3FX){ 0x00000000, 0, 0xFFFC0000 };
	VIEW_UP 	= (Vector3FX){ 0, 0x00010000, 0 };	
		
  while(true) {
	  
    if(front_buffer == background_frame_0)
      {
	      front_buffer = background_frame_1;
	      back_buffer  = background_frame_0;
      }
    else
      {
	      front_buffer = background_frame_0;
	      back_buffer  = background_frame_1;
      }

    jag_wait_vbl();
    
    clear_video_buffer(back_buffer);
	
	buildPerspectiveMatrix(mPerspective);

    /* Buffer is now clear. */
	
	/* 3D! */
	//skunkCONSOLEWRITE("GPU_LOAD_MMULT_PROGRAM\n");
    GPU_LOAD_MMULT_PROGRAM(); //Switch GPU to matrix operations
	
	//skunkCONSOLEWRITE("Building view matrix\n");
	buildViewMatrix(mView, VIEW_EYE, VIEW_CENTER, VIEW_UP);
	
	//TODO: This crashes if we reach 180 degrees in all 3 directions?
    cube.rotation.x = (cube.rotation.x + 0x00010000) % 0x01680000;
    cube.rotation.y = (cube.rotation.y + 0x00010000) % 0x01680000;
    cube.rotation.z = (cube.rotation.z + 0x00010000) % 0x01680000;
    
    framecounter = (framecounter + 1) % 60;

    if((framecounter % 60) == 0)
	{

	}
    
	skunkCONSOLEWRITE("Reading controls\n");
    /* Triggers once per frame while these are pressed */
    if(stick0_lastread & STICK_UP) {

    }
    if(stick0_lastread & STICK_DOWN) {

    }
    if(stick0_lastread & STICK_LEFT) {

    }
    if(stick0_lastread & STICK_RIGHT) {
      
    }
 
    stick0 = jag_read_stick0(STICK_READ_ALL);
    /* Debounced - only triggers once per press */
    switch(stick0 ^ stick0_lastread)
	{
	case STICK_UP:
		if(~stick0_lastread & STICK_UP)
		{
			VIEW_EYE.y += 0x00010000;
			VIEW_CENTER.y += 0x00010000;
		}
	break;
	case STICK_DOWN:
		if(~stick0_lastread & STICK_DOWN)
		{
			VIEW_EYE.y -= 0x00010000;
			VIEW_CENTER.y -= 0x00010000;
		}
	break;
	case STICK_LEFT:
		if(~stick0_lastread & STICK_LEFT)
		{
			VIEW_EYE.x -= 0x00010000;
			VIEW_CENTER.x -= 0x00010000;
		}
	break;
	case STICK_RIGHT:
		if(~stick0_lastread & STICK_RIGHT)
		{
			VIEW_EYE.x += 0x00010000;
			VIEW_CENTER.x += 0x00010000;
		}
	break;
	case STICK_A:
		//if(~stick0_lastread & STICK_A) printf("A\n");
	if(~stick0_lastread & STICK_A)
	{
	  
	}
	break;
	case STICK_B:
		//if(~stick0_lastread & STICK_B) printf("B\n");
	break;
	case STICK_C:
		//if(~stick0_lastread & STICK_C) printf("C\n");
	break;
	}
	  
    stick0_lastread = stick0;

	shape_Current = &cube;
	
	GPU_BUILD_TRANSFORMATION_START();
	jag_gpu_wait();
	
	//while(true) {};
	
	//skunkCONSOLEWRITE("Transformation is calculated!\n");
  
	//skunkCONSOLEWRITE("Loading LINEDRAW\n");
    GPU_LOAD_LINEDRAW_PROGRAM(); //Switch GPU to line blitting
	
	Vector4FX projectedPoints[3];
	
	line_clut_color = 255;
	
	object_M = m;
	object_Triangle = cube.triangles;
	
	MMIO32(0x50010) = (uint32_t)m;
	MMIO32(0x50014) = (uint32_t)mModel;
	MMIO32(0x50018) = (uint32_t)mView;
	MMIO32(0x5001c) = (uint32_t)mPerspective;
	
	GPU_PROJECT_AND_DRAW_TRIANGLE();
	jag_gpu_wait();
	
	/*
    sprintf(skunkoutput, "R00 %08X R01 %08X R02 %08X R03 %08X\n", gpu_register_dump[0], gpu_register_dump[1], gpu_register_dump[2], gpu_register_dump[3]);
    skunkCONSOLEWRITE(skunkoutput);
    sprintf(skunkoutput, "R04 %08X R05 %08X R06 %08X R07 %08X\n", gpu_register_dump[4], gpu_register_dump[5], gpu_register_dump[6], gpu_register_dump[7]);
    skunkCONSOLEWRITE(skunkoutput);
    sprintf(skunkoutput, "R08 %08X R09 %08X R10 %08X R11 %08X\n", gpu_register_dump[8], gpu_register_dump[9], gpu_register_dump[10], gpu_register_dump[11]);
    skunkCONSOLEWRITE(skunkoutput);
    sprintf(skunkoutput, "R12 %08X R13 %08X R14 %08X R15 %08X\n", gpu_register_dump[12], gpu_register_dump[13], gpu_register_dump[14], gpu_register_dump[15]);
    skunkCONSOLEWRITE(skunkoutput);
    sprintf(skunkoutput, "R16 %08X R17 %08X R18 %08X R19 %08X\n", gpu_register_dump[16], gpu_register_dump[17], gpu_register_dump[18], gpu_register_dump[19]);
    skunkCONSOLEWRITE(skunkoutput);
    sprintf(skunkoutput, "R20 %08X R21 %08X R22 %08X R23 %08X\n", gpu_register_dump[20], gpu_register_dump[21], gpu_register_dump[22], gpu_register_dump[23]);
    skunkCONSOLEWRITE(skunkoutput);
    sprintf(skunkoutput, "R24 %08X R25 %08X R26 %08X R28 %08X\n", gpu_register_dump[24], gpu_register_dump[25], gpu_register_dump[26], gpu_register_dump[27]);
    skunkCONSOLEWRITE(skunkoutput);
    sprintf(skunkoutput, "R28 %08X R29 %08X R30 %08X R31 %08X\n", gpu_register_dump[28], gpu_register_dump[29], gpu_register_dump[30], gpu_register_dump[31]);
    skunkCONSOLEWRITE(skunkoutput);
	*/
  }
}
