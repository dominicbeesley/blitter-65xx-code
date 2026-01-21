#ifndef __COORDS_H__
#define __COORDS_H__

#include "types.h"

typedef struct s_point {
	coord X;
	coord Y;
} point;

extern const point point0;

typedef struct s_size {
	coord W;
	coord H;
} size;

typedef struct s_rect {
	point topleft;
	size size;
} rectangle;

#endif