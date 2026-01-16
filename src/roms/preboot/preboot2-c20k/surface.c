#include "screen.h"
#include "surface.h"
#include "window.h"
#include "hex.h"

void surface_from_window(surface *surface, win_def *w) {
	surface->left = w->left;
	surface->top = w->top;
	surface->width = w->width;
	surface->height = w->height;

	surface->scroll_X = w->scroll_X;
	surface->scroll_Y = w->scroll_Y;

}

void surface_render_str(surface *s, screen_coord X, screen_coord Y, const char *str) {
	screen_coord SX, SY;
	const char *p = str;

	X = X - s->scroll_X;
	Y = Y - s->scroll_Y;

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


screen_bool surface_from_rect(surface *parent, surface *new, screen_coord X, screen_coord Y, screen_coord W, screen_coord H) {

	char *p;
	screen_coord diff;
	screen_coord SX, SY;
	screen_coord SCX, SCY;

	SCX = 0;
	SCY = 0;
	SX = X + parent->left - parent->scroll_X;
	SY = Y + parent->top - parent->scroll_Y;

	//left bound check
	diff = parent->left + parent->width - (SX + W);
	if (diff < 0)
		W+= diff;

	if (W<0) goto bad;

	//bottom bound check
	diff = (parent->top + parent->height) - (SY + H);
	if (diff < 0)
		H+= diff;

	if (H<0) goto bad;

	//right bound check
	diff = SX - parent->left;
	if (diff < 0) {
		W += diff;
		SX -= diff;
		SCX = -diff;
	}

	if (W<0) goto bad;

	//top bound check
	diff = SY - parent->top;
	if (diff < 0) {
		H += diff;
		SY -= diff;
		SCY = -diff;
	}

	if (H<0) goto bad;

	new->left = SX;
	new->top = SY;
	new->width = W;
	new->height = H;
	new->scroll_X = SCX;
	new->scroll_Y = SCY;

	return 1;

bad:	

	new->left = SX;
	new->top = SY;
	new->width = 0;
	new->height = 0;
	new->scroll_X = SCX;
	new->scroll_Y = SCY;
	return 0;


}
