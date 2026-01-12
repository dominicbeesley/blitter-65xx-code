#include <string.h>

#include "screen.h"
#include "window.h"



extern char main_head[];

const char *w_main_data = "HELLO WORLD";

win_def w_main;
win_def w_head;
win_def w_over;

int main(void) {

	screen_init();


	memcpy((char *)0x7C00, main_head, 8*40);

	screen_print_at(10, 20, 'b');
	screen_print_at(11, 20, 'b');
	screen_print_at(12, 20, 'c');

	screen_cursor_at(13,21);
	screen_cursor(1);


	win_init(&w_main, 3, 10, 35, 10, (void *)w_main_data);
	win_open(&w_main, 1);

	win_init(&w_head, 3, 4, 35, 3, NULL);
	win_open(&w_head, 0);

	win_init(&w_over, 10, 10, 4, 4, NULL);
	win_open(&w_over, 1);

	return 0;

}