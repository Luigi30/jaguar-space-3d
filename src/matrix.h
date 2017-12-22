#ifndef MATRIX_H
#define MATRIX_H

#include <jagcore.h>
#include <jaglib.h>

#include <math.h>
#include <string.h>

#include "dsp.h"
#include "gpu.h"
#include "fixed.h"
#include "log.h"

typedef struct matrix44_t {
  FIXED_32 data[4][4];
} Matrix44;

extern char skunkoutput[256];

//C functions, some of which call DSP functions
Matrix44 *Matrix44_Alloc();
void Matrix44_Free(Matrix44 *m);
//extern void Matrix44_Identity(__reg("a0") Matrix44 *m);
void Matrix44_Identity(Matrix44 *m);

void Matrix44_Multiply_Matrix44(Matrix44 *left, Matrix44 *right, Matrix44 *result);
void Matrix44_VectorProduct(Matrix44 *matrix, Vector3FX *vector, Vector4FX *destination);

void Matrix44_Translation(Vector3FX translation, Matrix44 *result);
void Matrix44_Rotation(Vector3FX rotation, Matrix44 *result);

void Matrix44_X_Rotation(Vector3FX rotation, Matrix44 *result);
void Matrix44_Y_Rotation(Vector3FX rotation, Matrix44 *result);
void Matrix44_Z_Rotation(Vector3FX rotation, Matrix44 *result);

extern void CopyMatrix44(__reg("a0") Matrix44 *destination, __reg("a1") Matrix44 *source);

extern Matrix44 MATRIX_PRESET_IDENTITY;

extern Vector3FX *mvp_vector;
extern Matrix44  *mvp_matrix;
extern Vector3FX *mvp_result;

extern Matrix44 *M_CopySource;
extern Matrix44 *M_CopyDestination;

extern Matrix44 *M_MultLeft;
extern Matrix44 *M_MultRight;
extern Matrix44 *M_MultResult;

extern Matrix44 *mViewTranslate;

void buildViewMatrix(Matrix44 *mView, Vector3FX EYE, Vector3FX CENTER, Vector3FX UP);
void buildPerspectiveMatrix(Matrix44 *mPerspective);

#endif
