#include "hardware.h"
#include "screen.h"
#include <string.h>
#include "debug.h"

void screen_print_at(const point *sp, char c) {
	char *p = screen_addr(sp);

	if (p != SCREEN_ADDR_BAD)
 		*p = c;
}

void screen_cursor_at(const point *sp) {
	char *p = screen_addr(sp);

	if (p != SCREEN_ADDR_BAD)
	{
		int p = sp->X+40*sp->Y;
		R_P(sheila_CRTC_IX) = 14;
		R_P(sheila_CRTC_DAT) = ((unsigned int )p) >> 8;
		R_P(sheila_CRTC_IX) = 15;
		R_P(sheila_CRTC_DAT) = ((unsigned int )p);
	}
}

void screen_cursor(bool b) {
	R_P(sheila_CRTC_IX) = 10;
	if (b) {
		R_P(sheila_CRTC_DAT) = 0x72;
	} else {
		R_P(sheila_CRTC_DAT) = 0x7A;		
	}
}


void screen_clear(const rectangle *sr, char c) {

	char *scr;
	rectangle r;

	r = *sr;
	
	if (r.topleft.X < 0) {
		r.size.W += r.topleft.X;
		r.topleft.X = 0;
	}
	if (r.topleft.X >= SCREEN_WIDTH) 
		return;
	if (r.topleft.X + r.size.W > SCREEN_WIDTH) 
		r.size.W = SCREEN_WIDTH - r.topleft.X;
	if (r.size.W <= 0)
		return;

	if (r.topleft.Y < 0) {
		r.size.H += r.topleft.Y;
		r.topleft.Y = 0;
	}
	if (r.topleft.Y >= SCREEN_HEIGHT) 
		return;
	if (r.topleft.Y + r.size.H > SCREEN_HEIGHT) 
		r.size.H = SCREEN_HEIGHT - r.topleft.Y;
	if (r.size.H <= 0)
		return;

	scr = screen_addr(&r.topleft);
	while (r.size.H) {
		memset(scr, c, r.size.W);
		scr += SCREEN_WIDTH;
		r.size.H--;
	}
}