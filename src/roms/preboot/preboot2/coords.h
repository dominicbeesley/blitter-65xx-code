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

extern bool rectangles_overlap(const rectangle *r1, const rectangle *r2);
extern coord coord_min(coord c1, coord c2);
extern coord coord_max(coord c1, coord c2);
extern void rectangle_surround(const rectangle *r1, const rectangle *r2, rectangle *r3);


#endif