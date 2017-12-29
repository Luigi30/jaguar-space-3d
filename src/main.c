/* Note: All malloc() objects or anything on the heap is phrase-aligned.
   Objects on the stack are word-aligned. */

#include "main.h"
#include <stdbool.h>

#include "cube.h"
#include "script.h"

Vector3FX cameraTranslation;

Matrix44 *object_M;
Vector3FX **object_Triangle;

struct List *scene_Shapes;
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
  EmuLog_String("main(): Begin space.\n");
  
  //set correct endianness
  MMIO32(G_END) = 0x00070007;

  tri_ndc_1 = calloc(1, sizeof(Vector4FX));
  tri_ndc_2 = calloc(1, sizeof(Vector4FX));
  tri_ndc_3 = calloc(1, sizeof(Vector4FX));
  
  DSP_LoadSoundEngine();
  DSP_StartSoundEngine();
  //DSP_PlayModule();

  EmuLog_String("main(): DSP sound engine initialized\n");
  
  GPU_LOAD_MMULT_PROGRAM(); //Switch GPU to matrix operations

  
  srand(8675309);
  jag_console_hide();
  
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
  
  //16-shade grayscale
  jag_set_indexed_color(0, toRgb16(0,0,0));
  for(int i=1;i<16;i++){
	  jag_set_indexed_color(i, toRgb16((i*16)-1,(i*16)-1,(i*16)-1));
  }

  EmuLog_String("main(): Palette initialized.\n");

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

  EmuLog_String("Graphic layers initialized\n");

  //Start the list here.
  jag_attach_olp(mobj_background.graphic);
		
  uint32_t stick0, stick0_lastread;
  uint16_t framecounter = 0;
  uint32_t framenumber = 0;

  EmuLog_String("main(): Constructing scene\n");
  NewList((struct List *)scene_Shapes);

  /* Shapes. */
  {
    Shape *cube_ptr = calloc(1, sizeof(Shape));
    cube_ptr->translation = (Vector3FX){ .x = INT_TO_FIXED(0), .y = INT_TO_FIXED(0), .z = INT_TO_FIXED(0) };
    cube_ptr->rotation    = (Vector3FX){ .x = INT_TO_FIXED(0), .y = INT_TO_FIXED(0), .z = INT_TO_FIXED(0) };
    cube_ptr->scale       = (Vector3FX){ .x = INT_TO_FIXED(1), .y = INT_TO_FIXED(1), .z = INT_TO_FIXED(1) };
    //cube_ptr->triangles = MODEL_cube_tri_list;
    cube_ptr->triangles = &MODEL_cone_tri_list;
    ShapeListEntry *sle = calloc(1, sizeof(ShapeListEntry));
    sle->shape_Data = cube_ptr;
    sle->shape_Node.ln_Name = malloc(10);
    strcpy(sle->shape_Node.ln_Name, "CUBE");
    AddHead((struct List*)scene_Shapes, (struct Node *)sle);
  }

  /*
  {
    Shape *sphere_ptr = calloc(1, sizeof(Shape));
    sphere_ptr->translation = (Vector3FX){ .x = INT_TO_FIXED(0), .y = INT_TO_FIXED(0), .z = INT_TO_FIXED(0) };
    sphere_ptr->rotation    = (Vector3FX){ .x = INT_TO_FIXED(0), .y = INT_TO_FIXED(0), .z = INT_TO_FIXED(0) };
    sphere_ptr->scale       = (Vector3FX){ .x = INT_TO_FIXED(1), .y = INT_TO_FIXED(1), .z = INT_TO_FIXED(1) };
    sphere_ptr->triangles = MODEL_sphere_tri_list;
    ShapeListEntry *sle = calloc(1, sizeof(ShapeListEntry));
    sle->shape_Data = sphere_ptr;
    sle->shape_Node.ln_Name = malloc(10);
    strcpy(sle->shape_Node.ln_Name, "SPHERE");
    AddHead((struct List*)scene_Shapes, (struct Node *)sle);
  }
  */

  {
    Shape *cube_ptr = calloc(1, sizeof(Shape));
    cube_ptr->translation = (Vector3FX){ .x = INT_TO_FIXED(0), .y = INT_TO_FIXED(0), .z = INT_TO_FIXED(5) };
    cube_ptr->rotation    = (Vector3FX){ .x = INT_TO_FIXED(0), .y = INT_TO_FIXED(0), .z = INT_TO_FIXED(0) };
    cube_ptr->scale       = (Vector3FX){ .x = INT_TO_FIXED(1), .y = INT_TO_FIXED(1), .z = INT_TO_FIXED(1) };
    cube_ptr->triangles = cube_triangles;
    ShapeListEntry *sle = calloc(1, sizeof(ShapeListEntry));
    sle->shape_Data = cube_ptr;
    sle->shape_Node.ln_Name = malloc(10);
    strcpy(sle->shape_Node.ln_Name, "PLAYER");
    AddHead((struct List*)scene_Shapes, (struct Node *)sle);
  }

  EmuLog_String("main(): initializing transformation matrix\n");
 
  //Init transformation matrix
  m = calloc(1, sizeof(Matrix44));
  mTranslation = calloc(1, sizeof(Matrix44));
  mRotation = calloc(1, sizeof(Matrix44));
  mModel = calloc(1, sizeof(Matrix44));

  mPerspective = calloc(1, sizeof(Matrix44));
  buildPerspectiveMatrix(mPerspective);

  //Init Matrix44_VectorProduct
  mvp_vector = calloc(1, sizeof(Vector3FX));
  mvp_matrix = calloc(1, sizeof(Matrix44));
  mvp_result = calloc(1, sizeof(Vector3FX));
	
  mView = calloc(1, sizeof(Matrix44));
  mViewTranslate = calloc(1, sizeof(Matrix44));
	
  Vector3FX transformedVertexList[4];
	
  //Init view parameters
  VIEW_EYE 	= (Vector3FX){ 0x00000000, 0x00000000, 0x00050000 };
  VIEW_CENTER   = (Vector3FX){ 0x00000000, 0x00000000, 0x00000000 };
  VIEW_UP 	= (Vector3FX){ 0x00000000, 0x00010000, 0x00000000 };

  Matrix44 *player_mForward = calloc(1, sizeof(Matrix44));
  Matrix44 *player_mRight = calloc(1, sizeof(Matrix44));

  EmuLog_String("main(): entering frame loop\n");
  
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

    GPU_LOAD_MMULT_PROGRAM(); //Switch GPU to matrix operations
    ShapeListEntry *player = (ShapeListEntry *)FindName(scene_Shapes, "PLAYER");
    Shape *player_orientation = player->shape_Data;

    EmuLog_String("main(): building view\n");
    VIEW_EYE = player->shape_Data->translation;

    //The center point is 1 unit forward from the translation.
    Vector3FX FORWARD = (Vector3FX){0, 0, 0xFFFF0000};
    Vector3FX RIGHT = (Vector3FX){0x00010000, 0, 0};
    //Rotate this vector by the player's rotation to produce the local FORWARD and RIGHT vectors.
    Matrix44_Rotation(player_orientation->rotation, player_mForward);
    Matrix44_Rotation(player_orientation->rotation, player_mRight);
    
    Vector3FX f;
    f.x = FIXED_MUL(player_mForward->data[0][0], FORWARD.x) + FIXED_MUL(player_mForward->data[0][1], FORWARD.y) + FIXED_MUL(player_mForward->data[0][2], FORWARD.z);
    f.y = FIXED_MUL(player_mForward->data[1][0], FORWARD.x) + FIXED_MUL(player_mForward->data[1][1], FORWARD.y) + FIXED_MUL(player_mForward->data[1][2], FORWARD.z);
    f.z = FIXED_MUL(player_mForward->data[2][0], FORWARD.x) + FIXED_MUL(player_mForward->data[2][1], FORWARD.y) + FIXED_MUL(player_mForward->data[2][2], FORWARD.z);

    Vector3FX r;
    r.x = FIXED_MUL(player_mRight->data[0][0], RIGHT.x) + FIXED_MUL(player_mRight->data[0][1], RIGHT.y) + FIXED_MUL(player_mRight->data[0][2], RIGHT.z);
    r.y = FIXED_MUL(player_mRight->data[1][0], RIGHT.x) + FIXED_MUL(player_mRight->data[1][1], RIGHT.y) + FIXED_MUL(player_mRight->data[1][2], RIGHT.z);
    r.z = FIXED_MUL(player_mRight->data[2][0], RIGHT.x) + FIXED_MUL(player_mRight->data[2][1], RIGHT.y) + FIXED_MUL(player_mRight->data[2][2], RIGHT.z);

    EmuLog_String("main(): f and r vectors built\n");

    /*
    sprintf(skunkoutput, "Player rotation is %08X %08X %08X\n", player_orientation->rotation.x, player_orientation->rotation.y, player_orientation->rotation.z);
    EmuLog_String(skunkoutput);

    sprintf(skunkoutput, "*** mForward ***\n%08X %08X %08X %08X\n%08X %08X %08X %08X\n%08X %08X %08X %08X\n%08X %08X %08X %08X\n",
	    mForward->data[0][0], mForward->data[0][1], mForward->data[0][2], mForward->data[0][3],
	    mForward->data[1][0], mForward->data[1][1], mForward->data[1][2], mForward->data[1][3],
	    mForward->data[2][0], mForward->data[2][1], mForward->data[2][2], mForward->data[2][3],
	    mForward->data[3][0], mForward->data[3][1], mForward->data[3][2], mForward->data[3][3]);
    EmuLog_String(skunkoutput);
    
    sprintf(skunkoutput, "Forward vector is %08X %08X %08X\n", f.x, f.y, f.z);
    EmuLog_String(skunkoutput);

    while(true) {};
    */
    
    VIEW_CENTER = player->shape_Data->translation;
    VIEW_CENTER.x += f.x;
    VIEW_CENTER.y += f.y;
    VIEW_CENTER.z += f.z;
    
    buildViewMatrix(mView, VIEW_EYE, VIEW_CENTER, VIEW_UP);
    EmuLog_String("main(): view matrix built\n");

    Shape *cube = ((ShapeListEntry *)FindName(scene_Shapes, "CUBE"))->shape_Data;
    //cube->rotation.x = (cube->rotation.x + 0x00010000) % 0x01680000;
    //cube->rotation.y = (cube->rotation.y + 0x00010000) % 0x01680000;
    //cube->rotation.z = (cube->rotation.z + 0x00010000) % 0x01680000;
    
    framecounter = (framecounter + 1) % 60;

    if((framecounter % 60) == 0)
      {

      }
    
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
	    player_orientation->translation.y += 0x00010000;
	  }
	break;
      case STICK_DOWN:
	if(~stick0_lastread & STICK_DOWN)
	  {
	    player_orientation->translation.y -= 0x00010000;
	  }
	break;
      case STICK_LEFT:
	if(~stick0_lastread & STICK_LEFT)
	  {
	    player_orientation->translation.x -= r.x;
	    player_orientation->translation.y -= r.y;
	    player_orientation->translation.z -= r.z;
	  }
	break;
      case STICK_RIGHT:
	if(~stick0_lastread & STICK_RIGHT)
	  {
	    player_orientation->translation.x += r.x;
	    player_orientation->translation.y += r.y;
	    player_orientation->translation.z += r.z;
	  }
	break;
      case STICK_A:
	if(~stick0_lastread & STICK_A)
	  {
	    player_orientation->translation.x -= f.x;
	    player_orientation->translation.y -= f.y;
	    player_orientation->translation.z -= f.z;
	  }
	break;
      case STICK_B:
	if(~stick0_lastread & STICK_B)
	  player_orientation->rotation.y = (player_orientation->rotation.y + 0x00050000) % 0x01680000;
	break;
      case STICK_C:
	if(~stick0_lastread & STICK_C)
	  {
	    player_orientation->translation.x += f.x;
	    player_orientation->translation.y += f.y;
	    player_orientation->translation.z += f.z;
	  }
	break;
      case STICK_7:
	{
	  if(~stick0_lastread & STICK_7)
	  {
	    player_orientation->rotation.y = (player_orientation->rotation.y - 0x00050000) % 0x01680000;
	  }
	  break;
	}
      case STICK_9:
	{
	  player_orientation->rotation.y = (player_orientation->rotation.y + 0x00050000) % 0x01680000;
	  break;
	}
      }
	  
    stick0_lastread = stick0;

    EmuLog_String("running draw loop\n");

    for(ShapeListEntry *entry = (ShapeListEntry *)scene_Shapes->lh_Head; entry->shape_Node.ln_Succ != NULL; entry = (ShapeListEntry *)entry->shape_Node.ln_Succ)
      {
	sprintf(skunkoutput, "drawing shape %s\n", entry->shape_Node.ln_Name);
	EmuLog_String(skunkoutput);
	
	if(strcmp(entry->shape_Node.ln_Name, "PLAYER") == 0)
	  continue; //Don't render the player object.
	
	shape_Current = entry->shape_Data;

	GPU_LOAD_MMULT_PROGRAM();
	GPU_BUILD_TRANSFORMATION_START();
	jag_gpu_wait();
	GPU_LOAD_LINEDRAW_PROGRAM(); //Switch GPU to line blitting

	Vector4FX projectedPoints[3];
	
	object_M = m;
	object_Triangle = &entry->shape_Data->triangles[0];	
	
	GPU_PROJECT_AND_DRAW_TRIANGLE();
	jag_gpu_wait();

	//while (true) {};
      }

    FIXED_PRINT_TO_BUFFER(text_buffer, 8, 8,  "TRANS  X: %s", player_orientation->translation.x);
    FIXED_PRINT_TO_BUFFER(text_buffer, 8, 16, "TRANS  Y: %s", player_orientation->translation.y);
    FIXED_PRINT_TO_BUFFER(text_buffer, 8, 24, "TRANS  Z: %s", player_orientation->translation.z);

    FIXED_PRINT_TO_BUFFER(text_buffer, 8, 40, "ROTATE X: %s", player_orientation->rotation.x);
    FIXED_PRINT_TO_BUFFER(text_buffer, 8, 48, "ROTATE Y: %s", player_orientation->rotation.y);
    FIXED_PRINT_TO_BUFFER(text_buffer, 8, 56, "ROTATE Z: %s", player_orientation->rotation.z);
  }
}
