#include <string.h>

#include "screen.h"
#include "window.h"
#include "surface.h"



extern char main_head[];

const char *w_main_data = "HELLO WORLD";

win_def w_main;
win_def w_head;
win_def w_over;
win_def w_status;

char buf[100];

char hex_nyb(unsigned char x) {
	x = x & 0xF;
	if (x < 10)
		return '0' + x;
	else
		return 'A' + x - 10;
}

char * hex_str(char *buf, unsigned char w, unsigned long n) {
	unsigned char i = w;
	while (i > 0) {
		i--;
		buf[i] = hex_nyb(n);
		n = n >> 4;
	}

	return buf + w;
}


screen_bool render_main(win_def *w) {
	screen_coord Y;
	surface s;

	surface_from_window(&s, w);

	for (Y = 0; Y < 23; Y ++) {
		*hex_str(buf, 6, Y) = '\0';
		surface_render_str(&s, 0, Y, buf);
	}

	return 1;
}

int main(void) {

	screen_init();


	memcpy((char *)0x7C00, main_head, 8*40);

	screen_cursor_at(13,21);
	screen_cursor(1);

	win_init(&w_main, 0, 8, 40, 16, NULL);
	win_register_event(&w_main, EVENT_RENDER, &render_main);
	win_open(&w_main, 1);

	win_init(&w_head, 3, 4, 35, 3, NULL);
	win_open(&w_head, 0);

	win_init(&w_over, 10, 10, 4, 4, NULL);
	win_open(&w_over, 1);

	win_init(&w_status, 0, 24, 40, 1, NULL);
	win_open(&w_status, 1);

	return 0;

}