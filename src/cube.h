#ifndef CUBE_H
#define CUBE_H

#include "shared.h"
#include "fixed.h"

//static Vector3FX triangle1[3] = { VERTEX_CREATE(-1, -1,  1), VERTEX_CREATE(-1,  1, -1), VERTEX_CREATE(-1, -1, -1) };
static Vector3FX triangle1[3] = { VERTEX_CREATE( 1,  1,  1), VERTEX_CREATE(-1,  1,  1), VERTEX_CREATE(-1, -1,  1) };
static Vector3FX triangle2[3] = { VERTEX_CREATE(-1, -1, -1), VERTEX_CREATE( 1, -1, -1), VERTEX_CREATE( 1,  1, -1) };
static Vector3FX triangle3[3] = { VERTEX_CREATE( 1,  1, -1), VERTEX_CREATE(-1,  1, -1), VERTEX_CREATE(-1, -1, -1) };
static Vector3FX triangle4[3] = { VERTEX_CREATE( 1, -1,  1), VERTEX_CREATE( 1, -1, -1), VERTEX_CREATE(-1, -1, -1) };
static Vector3FX triangle5[3] = { VERTEX_CREATE( 1, -1,  1), VERTEX_CREATE(-1, -1,  1), VERTEX_CREATE(-1, -1, -1) };
static Vector3FX triangle6[3] = { VERTEX_CREATE( 1,  1,  1), VERTEX_CREATE( 1,  1, -1), VERTEX_CREATE(-1,  1, -1) };
static Vector3FX triangle7[3] = { VERTEX_CREATE( 1,  1,  1), VERTEX_CREATE(-1,  1,  1), VERTEX_CREATE(-1,  1, -1) };
static Vector3FX triangle8[3] = { VERTEX_CREATE(-1,  1,  1), VERTEX_CREATE(-1,  1, -1), VERTEX_CREATE(-1, -1, -1) };
static Vector3FX triangle9[3]= { VERTEX_CREATE(-1,  1,  1), VERTEX_CREATE(-1, -1,  1), VERTEX_CREATE(-1, -1, -1) };
static Vector3FX triangle10[3]= { VERTEX_CREATE( 1,  1,  1), VERTEX_CREATE( 1,  1, -1), VERTEX_CREATE( 1, -1, -1) };
static Vector3FX triangle11[3]= { VERTEX_CREATE( 1,  1,  1), VERTEX_CREATE( 1, -1,  1), VERTEX_CREATE( 1, -1, -1) };

#endif
