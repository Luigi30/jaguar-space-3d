#include "matrix.h"

static Matrix44 M_IDENTITY = {	.data[0][0] = 0x00010000, .data[0][1] = 0x00000000, .data[0][2] = 0x00000000, .data[0][3] = 0x00000000, 
								.data[1][0] = 0x00000000, .data[1][1] = 0x00010000, .data[1][2] = 0x00000000, .data[1][3] = 0x00000000, 
								.data[2][0] = 0x00000000, .data[2][1] = 0x00000000, .data[2][2] = 0x00010000, .data[2][3] = 0x00000000, 
								.data[3][0] = 0x00000000, .data[3][1] = 0x00000000, .data[3][2] = 0x00000000, .data[3][3] = 0x00010000
};

Matrix44 *dsp_matrix_ptr_m1;
Matrix44 *dsp_matrix_ptr_m2;

Matrix44 *M_CopySource;
Matrix44 *M_CopyDestination;

Matrix44 *M_MultLeft;
Matrix44 *M_MultRight;
Matrix44 *M_MultResult;

Matrix44 *Matrix44_Alloc(){
  return calloc(1, sizeof(Matrix44));
}

void Matrix44_Free(Matrix44 *m){
  free(m); 
}

void Matrix44_Identity(Matrix44 *m)
{
  jag_memcpy32p(m, &M_IDENTITY, 1, 16);
}

void Matrix44_Multiply_Matrix44(Matrix44 *left, Matrix44 *right, Matrix44 *result)
{	
	Matrix44 *buffer = calloc(1, sizeof(Matrix44));

	jag_gpu_wait();

	M_MultLeft = left;
	M_MultRight = right;
	M_MultResult = result;

	sprintf(skunkoutput, "M_MultLeft: %p, M_MultRight: %p, M_MultResult: %p, gpu_matrix_result: %p\n", M_MultLeft, M_MultRight, M_MultResult, &gpu_matrix_result);
	skunkCONSOLEWRITE(skunkoutput);
	
	sprintf(skunkoutput, "MMULT: Left\n %08x %08x %08x %08x\n %08x %08x %08x %08x\n %08x %08x %08x %08x\n %08x %08x %08x %08x\n",
		left->data[0][0], left->data[0][1], left->data[0][2], left->data[0][3], 
		left->data[1][0], left->data[1][1], left->data[1][2], left->data[1][3], 
		left->data[2][0], left->data[2][1], left->data[2][2], left->data[2][3], 
		left->data[3][0], left->data[3][1], left->data[3][2], left->data[3][3]
	);
	skunkCONSOLEWRITE(skunkoutput);
	
	sprintf(skunkoutput, "MMULT: Right\n %08x %08x %08x %08x\n %08x %08x %08x %08x\n %08x %08x %08x %08x\n %08x %08x %08x %08x\n",
		right->data[0][0], right->data[0][1], right->data[0][2], right->data[0][3], 
		right->data[1][0], right->data[1][1], right->data[1][2], right->data[1][3], 
		right->data[2][0], right->data[2][1], right->data[2][2], right->data[2][3], 
		right->data[3][0], right->data[3][1], right->data[3][2], right->data[3][3]
	);
	skunkCONSOLEWRITE(skunkoutput);
	
	sprintf(skunkoutput, "GPU_MMULT_START: left %p right %p result %p\n", left, right, result);
	skunkCONSOLEWRITE(skunkoutput);
	
	GPU_MMULT_START();
	jag_gpu_wait();
	
	sprintf(skunkoutput, "MMULT: GPU Left\n %08x %08x %08x %08x\n %08x %08x %08x %08x\n %08x %08x %08x %08x\n %08x %08x %08x %08x\n",
		M_MultLeft->data[0][0], M_MultLeft->data[0][1], M_MultLeft->data[0][2], M_MultLeft->data[0][3], 
		M_MultLeft->data[1][0], M_MultLeft->data[1][1], M_MultLeft->data[1][2], M_MultLeft->data[1][3], 
		M_MultLeft->data[2][0], M_MultLeft->data[2][1], M_MultLeft->data[2][2], M_MultLeft->data[2][3], 
		M_MultLeft->data[3][0], M_MultLeft->data[3][1], M_MultLeft->data[3][2], M_MultLeft->data[3][3]
	);
	skunkCONSOLEWRITE(skunkoutput);
	
	sprintf(skunkoutput, "MMULT: GPU Right\n %08x %08x %08x %08x\n %08x %08x %08x %08x\n %08x %08x %08x %08x\n %08x %08x %08x %08x\n",
		M_MultRight->data[0][0], M_MultRight->data[0][1], M_MultRight->data[0][2], M_MultRight->data[0][3], 
		M_MultRight->data[1][0], M_MultRight->data[1][1], M_MultRight->data[1][2], M_MultRight->data[1][3], 
		M_MultRight->data[2][0], M_MultRight->data[2][1], M_MultRight->data[2][2], M_MultRight->data[2][3], 
		M_MultRight->data[3][0], M_MultRight->data[3][1], M_MultRight->data[3][2], M_MultRight->data[3][3]
	);
	skunkCONSOLEWRITE(skunkoutput);
	
	sprintf(skunkoutput, "MMULT: gpu_matrix_result\n %08x %08x %08x %08x\n %08x %08x %08x %08x\n %08x %08x %08x %08x\n %08x %08x %08x %08x\n",
		(&gpu_matrix_result)->data[0][0], (&gpu_matrix_result)->data[0][1], (&gpu_matrix_result)->data[0][2], (&gpu_matrix_result)->data[0][3], 
		(&gpu_matrix_result)->data[1][0], (&gpu_matrix_result)->data[1][1], (&gpu_matrix_result)->data[1][2], (&gpu_matrix_result)->data[1][3], 
		(&gpu_matrix_result)->data[2][0], (&gpu_matrix_result)->data[2][1], (&gpu_matrix_result)->data[2][2], (&gpu_matrix_result)->data[2][3], 
		(&gpu_matrix_result)->data[3][0], (&gpu_matrix_result)->data[3][1], (&gpu_matrix_result)->data[3][2], (&gpu_matrix_result)->data[3][3]
	);
	skunkCONSOLEWRITE(skunkoutput);
	
	sprintf(skunkoutput, "MMULT: Result\n %08x %08x %08x %08x\n %08x %08x %08x %08x\n %08x %08x %08x %08x\n %08x %08x %08x %08x\n",
		result->data[0][0], result->data[0][1], result->data[0][2], result->data[0][3], 
		result->data[1][0], result->data[1][1], result->data[1][2], result->data[1][3], 
		result->data[2][0], result->data[2][1], result->data[2][2], result->data[2][3], 
		result->data[3][0], result->data[3][1], result->data[3][2], result->data[3][3]
	);
	skunkCONSOLEWRITE(skunkoutput);
}

const FIXED_32 ONE_DEGREE = (uint32_t)1143; //1 degree in radians == ~0.0174533 == ~1143/65535
inline FIXED_32 degreesToRadians( FIXED_32 degrees )
{
  return FIXED_MUL(degrees, ONE_DEGREE);
}

void Matrix44_Translation(Vector3FX translation, Matrix44 *result)
{
  jag_dsp_wait();
  memcpy(&dsp_matrix_vector, &translation, sizeof(Vector3FX));
  dsp_matrix_ptr_result = result;
  
  DSP_Matrix_Start_ASM(dsp_matrix_translation);
}
	
void Matrix44_Rotation(Vector3FX rotation, Matrix44 *result)
{
	FIXED_32 xDeg, yDeg, zDeg;
	xDeg = (rotation.x >> 16) % 360;
	yDeg = (rotation.y >> 16) % 360;
	zDeg = (rotation.z >> 16) % 360;

	dsp_matrix_vector.x = xDeg;
	dsp_matrix_vector.y = yDeg;
	dsp_matrix_vector.z = zDeg;
	dsp_matrix_ptr_result = result;

	DSP_Matrix_Start_ASM(dsp_matrix_rotation);
	jag_dsp_wait();
}

void Matrix44_VectorProduct(Matrix44 *matrix, Vector3FX *vector, Vector4FX *destination)
{
	//w = 0 for rotate in space
	//w = 1 for move in space

	//const float w = 1;

	destination->x = FIXED_MUL(matrix->data[0][0], vector->x) + FIXED_MUL(matrix->data[0][1], vector->y) + FIXED_MUL(matrix->data[0][2], vector->z) + matrix->data[0][3]; //* w = 1
	destination->y = FIXED_MUL(matrix->data[1][0], vector->x) + FIXED_MUL(matrix->data[1][1], vector->y) + FIXED_MUL(matrix->data[1][2], vector->z) + matrix->data[1][3]; //* w = 1
	destination->z = FIXED_MUL(matrix->data[2][0], vector->x) + FIXED_MUL(matrix->data[2][1], vector->y) + FIXED_MUL(matrix->data[2][2], vector->z) + matrix->data[2][3]; //* w = 1
	destination->w = FIXED_MUL(matrix->data[3][0], vector->x) + FIXED_MUL(matrix->data[3][1], vector->y) + FIXED_MUL(matrix->data[3][2], vector->z) + matrix->data[3][3]; //* w = 1
}

//TODO: Find a better place for this.
void buildViewMatrix(Matrix44 *mView, Vector3FX EYE, Vector3FX CENTER, Vector3FX UP)
{
	Vector3FX F  = { CENTER.x - EYE.x, CENTER.y - EYE.y, CENTER.z - EYE.z }; //Center of screen
	
	Vector3FX f = Vector3FX_Normalize(F);
	Vector3FX up_normalized = Vector3FX_Normalize(UP);
	Vector3FX s = Vector3FX_CrossProduct(f, up_normalized);
	Vector3FX s_normalized = Vector3FX_Normalize(s);
	Vector3FX u = Vector3FX_CrossProduct(s_normalized, f);

	mView->data[0][0] = s.x; mView->data[0][1] = s.y; mView->data[0][2] = s.z; mView->data[0][3] = 0;
	mView->data[1][0] = u.x; mView->data[1][1] = u.y; mView->data[1][2] = u.z; mView->data[1][3] = 0;
	mView->data[2][0] = -f.x; mView->data[2][1] = -f.y; mView->data[2][2] = -f.z; mView->data[2][3] = 0;
	mView->data[3][0] = s.x; mView->data[3][1] = s.y; mView->data[3][2] = s.z; mView->data[3][3] = 0x00010000;
	
	Matrix44 *mViewTranslate = calloc(1, sizeof(Matrix44));
	Matrix44_Identity(mViewTranslate);
	mViewTranslate->data[0][3] = -EYE.x; mViewTranslate->data[1][3] = -EYE.y; mViewTranslate->data[2][3] = -EYE.z;
	Matrix44_Multiply_Matrix44(mView, mViewTranslate, mView);
}

void buildPerspectiveMatrix(Matrix44 *mPerspective)
{
	Matrix44_Identity(mPerspective);

	FIXED_32 NEAR_CLIP 	= 0x00010000; // 1.0
	FIXED_32 FAR_CLIP 	= 0x00640000; // 100.0
	FIXED_32 f = 0x000191D4; // cot(65 degrees/2) = 1.56968

	mPerspective->data[0][0] = 0x0000FB25; // (f / 1.6) = 0.98105
	mPerspective->data[1][1] = f;
	mPerspective->data[2][2] = FIXED_DIV(FAR_CLIP, (FAR_CLIP-NEAR_CLIP));
	mPerspective->data[3][2] = 0x00010000;
	mPerspective->data[2][3] = -FIXED_DIV(FIXED_MUL(NEAR_CLIP, FAR_CLIP), FAR_CLIP-NEAR_CLIP);
	mPerspective->data[3][3] = 0;
}