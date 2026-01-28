#include <string.h>
#include "types.h"
#include "screen.h"
#include "debug.h"
#include "keyboard.h"
#include "hw.h"
#include "ui.h"
#include "apps.h"
#include "sound.h"

extern char main_head[];

char buf[100];


int main(void) {

	debug_printf("HELLO\n");

	screen_init();
	hw_init();
	keyb_init();
	sound_init();

	memcpy((char *)0x7C00, main_head, 8*40);
	ui_init();
	ui_start_app(&app_main_menu, NULL);

	screen_cursor_at(&point0);
	screen_cursor(0);

	do { 
		ui_poll();
	} while (1);

	return 0;

}