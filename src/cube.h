#ifndef CUBE_H
#define CUBE_H

#include "shared.h"
#include "fixed.h"

static Vector3FX triangle1[3] = { VERTEX_CREATE(-1, -1, -1), VERTEX_CREATE( 1, -1,  1), VERTEX_CREATE(-1, -1,  1) }; //CW
static Vector3FX triangle2[3] = { VERTEX_CREATE(-1, -1, -1), VERTEX_CREATE( 1, -1, -1), VERTEX_CREATE( 1, -1,  1) }; //CW
static Vector3FX triangle3[3] = { VERTEX_CREATE( -1, 1,  1), VERTEX_CREATE(-1, -1,  1), VERTEX_CREATE( 1, -1,  1) }; //CW
static Vector3FX triangle4[3] = { VERTEX_CREATE( 1, 1, 1), VERTEX_CREATE( -1, 1, 1), VERTEX_CREATE(1, -1, 1) }; //CW
static Vector3FX triangle5[3] = { VERTEX_CREATE( 1, -1, -1), VERTEX_CREATE(1, 1, 1), VERTEX_CREATE(1, -1, 1) }; //CW

static Vector3FX triangle6[3] = { VERTEX_CREATE( 1, 1, -1), VERTEX_CREATE( 1, 1, 1), VERTEX_CREATE(1, -1, -1) };
static Vector3FX triangle7[3] = { VERTEX_CREATE( -1, 1, -1), VERTEX_CREATE(1, -1, -1), VERTEX_CREATE(-1, -1, -1) };
static Vector3FX triangle8[3] = { VERTEX_CREATE(-1, 1, -1), VERTEX_CREATE(1, 1, -1 ), VERTEX_CREATE(1, -1, -1) };
static Vector3FX triangle9[3] = { VERTEX_CREATE(-1, 1, 1), VERTEX_CREATE(-1, -1, -1), VERTEX_CREATE(-1, -1, 1) };
static Vector3FX triangle10[3]= { VERTEX_CREATE( -1, 1, 1), VERTEX_CREATE( -1, 1, -1), VERTEX_CREATE( -1, -1, -1 ) };

static Vector3FX triangle11[3]= { VERTEX_CREATE( -1, 1, -1), VERTEX_CREATE(-1, 1, 1), VERTEX_CREATE( 1, 1, 1) };
static Vector3FX triangle12[3]= { VERTEX_CREATE( 1, 1, -1), VERTEX_CREATE(-1, 1, -1), VERTEX_CREATE( 1, 1, 1) };

//This will stop when we hit a NULL.
//static Vector3FX *cube_triangles[64] = { triangle1, triangle2, triangle3, triangle4, triangle5, triangle6, triangle7, triangle8, triangle9, triangle10, triangle11, triangle12, NULL };
static Vector3FX *cube_triangles[64] = { triangle3, NULL };

#endif
