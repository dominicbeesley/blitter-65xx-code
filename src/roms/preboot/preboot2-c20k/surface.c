#include "screen.h"
#include "surface.h"
#include "window.h"

void surface_from_window(surface *surface, win_def *w) {
	surface->left = w->left;
	surface->top = w->top;
	surface->width = w->width;
	surface->height = w->height;
}

void surface_render_str(surface *s, screen_coord X, screen_coord Y, const char *str) {
	screen_coord SX, SY;
	const char *p = str;

	if (Y < 0 || Y >= s->height)
		return;

	SX = s->left + X;
	SY = s->top + Y;
	while (*p) {
		if (X >= 0 && X < s->width)
			screen_print_at(SX, SY, *p);
		p++;
		SX++;
		X++;
	}
}


void surface_clear(surface *s, char c) {

	screen_coord SX, SY, SW, SH;
	
	SX = s->left;
	SY = s->top;
	SW = s->width;
	SH = s->height;

	screen_clear(SX, SY, SW, SH, c);

}