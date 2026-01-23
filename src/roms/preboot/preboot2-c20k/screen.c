#include "hardware.h"
#include "screen.h"
#include <string.h>
#include "debug.h"

const char mo7_crtc[] = {
			0x3f,				// 0 Horizontal Total	 =64
			0x28,				// 1 Horizontal Displayed =40
			0x33,				// 2 Horizontal Sync	 =&33  Note: &31 is a better value
			0x24,				// 3 HSync Width+VSync	 =&24  VSync=2, HSync=4
			0x1e,				// 4 Vertical Total	 =30
			0x02,				// 5 Vertical Adjust	 =2
			0x19,				// 6 Vertical Displayed	 =25
			0x1b,				// 7 VSync Position	 =&1B
			0x93,				// 8 Interlace+Cursor	 =&93  Cursor=2, Display=1, Interlace=Sync+Video
			0x12,				// 9 Scan Lines/Character =19
			0x72,				// 10 Cursor Start Line	  =&72	Blink=On, Speed=1/32, Line=18
			0x13,				// 11 Cursor End Line	  =19
			0x0,
			0x0
};


void screen_init(void) {
	signed char i;

	R_P(sheila_VIDPROC) = 0x4b;

	for (i = 13; i >= 0; i--) {
		R_P(sheila_CRTC_IX) = i;
		R_P(sheila_CRTC_DAT) = mo7_crtc[i];
	}

	memset((char *)0x7C00, ' ', 0x400);

}

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