#include "screen.h"
#include "surface.h"
#include "window.h"
#include "hex.h"
#include "debug.h"

void surface_from_window(surface *surface, win_def *w) {
	surface->screenrect = w->screenrect;
	surface->scroll = w->scroll;
}

bool surface_client_to_screen(surface *s, const point *clientpoint, point *sp) {
	point p;			//point relative to surface viewport

	p = *clientpoint;

	// make client coord relative to top-left
	p.X = p.X - s->scroll.X;
	p.Y = p.Y - s->scroll.Y;

	if (p.Y < 0 || p.Y >= s->screenrect.size.H)
		return 0;

	// screen coord
	sp->X = s->screenrect.topleft.X + p.X;
	sp->Y = s->screenrect.topleft.Y + p.Y;
	if (p.X >= 0 && p.X < s->screenrect.size.W)
		return 1;
	else
		return 0;
}

void surface_render_char(surface *s, const point *clientpoint, char c) {
	point sp;
	if (surface_client_to_screen(s, clientpoint, &sp)) {
		screen_print_at(&sp, c);
	}
}

void surface_cursor_at(surface *s, const point *clientpoint) {
	point sp;
	if (surface_client_to_screen(s, clientpoint, &sp)) {
		screen_cursor_at(&sp);
		screen_cursor(1);
	} else
		screen_cursor(0);
}


int surface_render_str(surface *s, const point *clientpoint, const char *str, bool cleareol) {
	point sp; 			//screen point
	point p;			//point relative to surface viewport
	const char *pc = str;
	int ret = 0;

	p = *clientpoint;

	// make client coord relative to top-left
	p.X = p.X - s->scroll.X;
	p.Y = p.Y - s->scroll.Y;

	if (p.Y < 0 || p.Y >= s->screenrect.size.H)
		return -1;


	// screen coord
	sp.X = s->screenrect.topleft.X + p.X;
	sp.Y = s->screenrect.topleft.Y + p.Y;


	while (*pc) {
		if (p.X >= 0 && p.X < s->screenrect.size.W)
			screen_print_at(&sp, *pc);
		pc++;
		p.X++;
		sp.X++;
		ret ++;
	}

	if (cleareol)
		while (sp.X < s->screenrect.topleft.X + s->screenrect.size.W)
		{
			screen_print_at(&sp, ' ');
			sp.X++;
		}
	return ret;
}


void surface_clear(surface *s, char c) {

	screen_clear(&s->screenrect, c);

}


void surface_clear_rect(surface *s, const rectangle *r, char c) {

	surface sw;

	surface_from_rect(s, &sw, r);
	surface_clear(&sw, c);	
}

bool surface_from_rect(surface *parent, surface *new, const rectangle *clientrect) {

	char *p;
	coord diff;
	coord SX, SY;
	coord SCX, SCY;
	rectangle r;		//modified to fit in viewport bounds

	r = *clientrect;

	SCX = 0;
	SCY = 0;
	SX = r.topleft.X + parent->screenrect.topleft.X - parent->scroll.X;
	SY = r.topleft.Y + parent->screenrect.topleft.Y - parent->scroll.Y;

	//left bound check
	diff = parent->screenrect.topleft.X + parent->screenrect.size.W - (SX + r.size.W);
	if (diff < 0)
		r.size.W += diff;

	if (r.size.W < 0) goto bad;

	//bottom bound check
	diff = (parent->screenrect.topleft.Y + parent->screenrect.size.H) - (SY + r.size.H);
	if (diff < 0)
		r.size.H += diff;

	if (r.size.H < 0) goto bad;

	//right bound check
	diff = SX - parent->screenrect.topleft.X;
	if (diff < 0) {
		r.size.W += diff;
		SX -= diff;
		SCX = -diff;
	}

	if (r.size.W < 0) goto bad;

	//top bound check
	diff = SY - parent->screenrect.topleft.Y;
	if (diff < 0) {
		r.size.H += diff;
		SY -= diff;
		SCY = -diff;
	}

	if (r.size.H < 0) goto bad;

	new->screenrect.topleft.X = SX;
	new->screenrect.topleft.Y = SY;
	new->screenrect.size.W = r.size.W;
	new->screenrect.size.H = r.size.H;
	new->scroll.X = SCX;
	new->scroll.Y = SCY;

	return 1;

bad:	

	new->screenrect.topleft.X = 0;
	new->screenrect.topleft.Y = 0;
	new->screenrect.size.W = 0;
	new->screenrect.size.H = 0;
	new->scroll.X = 0;
	new->scroll.Y = 0;
	return 0;


}
