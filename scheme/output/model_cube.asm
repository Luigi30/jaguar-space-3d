*** MODEL: cube
*** Triangles: 12
**************************************************
	XDEF _MODEL_cube
	XDEF _MODEL_cube_tri_count
	XDEF _MODEL_cube_tri_list

	even
_MODEL_cube_tri_count:
	dc.l 12

_MODEL_cube:
MODEL_cube_triangle_0:
	dc.l $-8000
	dc.l $-8000
	dc.l $-8000

	dc.l $8000
	dc.l $-8000
	dc.l $8000

	dc.l $-8000
	dc.l $-8000
	dc.l $8000

MODEL_cube_triangle_1:
	dc.l $-8000
	dc.l $-8000
	dc.l $-8000

	dc.l $8000
	dc.l $-8000
	dc.l $-8000

	dc.l $8000
	dc.l $-8000
	dc.l $8000

MODEL_cube_triangle_2:
	dc.l $-8000
	dc.l $8000
	dc.l $8000

	dc.l $-8000
	dc.l $-8000
	dc.l $8000

	dc.l $8000
	dc.l $-8000
	dc.l $8000

MODEL_cube_triangle_3:
	dc.l $8000
	dc.l $8000
	dc.l $8000

	dc.l $-8000
	dc.l $8000
	dc.l $8000

	dc.l $8000
	dc.l $-8000
	dc.l $8000

MODEL_cube_triangle_4:
	dc.l $8000
	dc.l $-8000
	dc.l $-8000

	dc.l $8000
	dc.l $8000
	dc.l $8000

	dc.l $8000
	dc.l $-8000
	dc.l $8000

MODEL_cube_triangle_5:
	dc.l $8000
	dc.l $8000
	dc.l $-8000

	dc.l $8000
	dc.l $8000
	dc.l $8000

	dc.l $8000
	dc.l $-8000
	dc.l $-8000

MODEL_cube_triangle_6:
	dc.l $-8000
	dc.l $8000
	dc.l $-8000

	dc.l $8000
	dc.l $-8000
	dc.l $-8000

	dc.l $-8000
	dc.l $-8000
	dc.l $-8000

MODEL_cube_triangle_7:
	dc.l $-8000
	dc.l $8000
	dc.l $-8000

	dc.l $8000
	dc.l $8000
	dc.l $-8000

	dc.l $8000
	dc.l $-8000
	dc.l $-8000

MODEL_cube_triangle_8:
	dc.l $-8000
	dc.l $8000
	dc.l $8000

	dc.l $-8000
	dc.l $-8000
	dc.l $-8000

	dc.l $-8000
	dc.l $-8000
	dc.l $8000

MODEL_cube_triangle_9:
	dc.l $-8000
	dc.l $8000
	dc.l $8000

	dc.l $-8000
	dc.l $8000
	dc.l $-8000

	dc.l $-8000
	dc.l $-8000
	dc.l $-8000

MODEL_cube_triangle_10:
	dc.l $-8000
	dc.l $8000
	dc.l $-8000

	dc.l $-8000
	dc.l $8000
	dc.l $8000

	dc.l $8000
	dc.l $8000
	dc.l $8000

MODEL_cube_triangle_11:
	dc.l $8000
	dc.l $8000
	dc.l $-8000

	dc.l $-8000
	dc.l $8000
	dc.l $-8000

	dc.l $8000
	dc.l $8000
	dc.l $8000


_MODEL_cube_tri_list:
	dc.l MODEL_cube_triangle_0
	dc.l MODEL_cube_triangle_1
	dc.l MODEL_cube_triangle_2
	dc.l MODEL_cube_triangle_3
	dc.l MODEL_cube_triangle_4
	dc.l MODEL_cube_triangle_5
	dc.l MODEL_cube_triangle_6
	dc.l MODEL_cube_triangle_7
	dc.l MODEL_cube_triangle_8
	dc.l MODEL_cube_triangle_9
	dc.l MODEL_cube_triangle_10
	dc.l MODEL_cube_triangle_11

