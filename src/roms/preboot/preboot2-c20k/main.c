#include <string.h>

#include "screen.h"
#include "window.h"



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

screen_bool render_main(win_def *w) {
	screen_coord Y;

	for (Y = 0; Y < 16; Y ++) {
		buf[0] = hex_nyb(Y);
		buf[1] = 0;
		win_render_str(w, 0, Y, buf);
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

	win_render_str(&w_main, 4, 5, "HELLO");
	win_render_str(&w_over, 0, 0, "Dominic Beesley");
	win_render_str(&w_head, 0, 0, "\x86Randomness");
	win_render_str(&w_status, 0, 0, "STATUS BAR");

	return 0;

}