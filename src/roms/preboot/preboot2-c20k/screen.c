#include "hardware.h"
#include "screen.h"
#include <string.h>

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

	memset((char *)0x7C00, '+', 0x400);

}

char *screen_addr(screen_coord x, screen_coord y) {
	if (x > 0 && x < SCREEN_WIDTH && y > 0 && y < SCREEN_HEIGHT)
		return (char *)0x7C00+x+40*y;
	else
		return SCREEN_ADDR_BAD;
}

void screen_print_at(screen_coord x, screen_coord y, char c) {
	char *p = screen_addr(x, y);
	if (p != SCREEN_ADDR_BAD)
 		*p = c;
}

void screen_cursor_at(screen_coord x, screen_coord y) {
	char *p = screen_addr(x, y);

	if (p != SCREEN_ADDR_BAD)
	{
		int p = x+40*y;
		R_P(sheila_CRTC_IX) = 14;
		R_P(sheila_CRTC_DAT) = ((unsigned int )p) >> 8;
		R_P(sheila_CRTC_IX) = 15;
		R_P(sheila_CRTC_DAT) = ((unsigned int )p);
	}
}

void screen_cursor(screen_bool b) {
	R_P(sheila_CRTC_IX) = 10;
	if (b) {
		R_P(sheila_CRTC_DAT) = 0x72;
	} else {
		R_P(sheila_CRTC_DAT) = 0x7A;		
	}
}
