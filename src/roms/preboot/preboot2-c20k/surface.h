#ifndef __SURFACE_H__
#define __SURFACE_H__

#include "window.h"

typedef struct surf_struct_def surface;

struct surf_struct_def {
	//viewport position on screen
	screen_coord left;
	screen_coord top;
	screen_coord width;
	screen_coord height;
};


extern void surface_from_window(surface *surface, win_def *);
extern void surface_render_str(surface *w, screen_coord X, screen_coord Y, const char *str);
extern void surface_clear(surface *surface, char c);

#endif