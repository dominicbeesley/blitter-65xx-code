#ifndef __SURFACE_H__
#define __SURFACE_H__

#include "coords.h"
#include "types.h"
#include "window.h"

typedef struct surf_struct_def surface;

struct surf_struct_def {
	//viewport position on screen
	rectangle screenrect;

	point scroll;
};


extern void surface_from_window(surface *surface, win_def *);
extern void surface_render_str(surface *w, const point *clientpoint, const char *str);
extern void surface_clear(surface *surface, char c);
extern bool surface_from_rect(surface *parent, surface *new, const rectangle *r);
extern void surface_clear_rect(surface *surface, const rectangle *r, char c);

#endif