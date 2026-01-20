#ifndef __SURFACE_H__
#define __SURFACE_H__

#include "types.h"
#include "window.h"

typedef struct surf_struct_def surface;

struct surf_struct_def {
	//viewport position on screen
	coord left;
	coord top;
	coord width;
	coord height;

	coord scroll_X;
	coord scroll_Y;

};


extern void surface_from_window(surface *surface, win_def *);
extern void surface_render_str(surface *w, coord X, coord Y, const char *str);
extern void surface_clear(surface *surface, char c);
extern bool surface_from_rect(surface *parent, surface *new, coord X, coord Y, coord W, coord H);
extern void surface_clear_rect(surface *surface, coord X, coord Y, coord W, coord H, char c);

#endif