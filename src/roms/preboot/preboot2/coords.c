#include "coords.h"

const point point0 = {0, 0};

coord coord_min(coord c1, coord c2) {
	if (c1 < c2)
		return c1;
	else
		return c2;
}

coord coord_max(coord c1, coord c2) {
	if (c1 > c2)
		return c1;
	else
		return c2;
}

bool rectangles_overlap(const rectangle *r1, const rectangle *r2) {

	if (r1->topleft.X < r2->topleft.X + r2->size.W
		&& r1->topleft.X + r1->size.W > r2->topleft.X
		&& r1->topleft.Y < r2->topleft.Y + r2->size.H
		&& r1->topleft.Y + r1->size.H > r2->topleft.Y)
		return 1;
	else
		return 0;
}

void rectangle_surround(const rectangle *r1, const rectangle *r2, rectangle *r3) {
	rectangle ret; // make a copy in case r3 is one of r1 or r2
	ret.topleft.X = coord_min(r1->topleft.X, r2->topleft.X);
	ret.topleft.Y = coord_min(r1->topleft.Y, r2->topleft.Y);
	ret.size.W = coord_max(r1->topleft.X + r1->size.W, r2->topleft.X + r2->size.W) - r3->topleft.X;
	ret.size.H = coord_max(r1->topleft.Y + r1->size.H, r2->topleft.Y + r2->size.H) - r3->topleft.Y;
	*r3 = ret;
}