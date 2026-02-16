#include <string.h>
#include "types.h"
#include "screen.h"
#include "debug.h"
#include "keyboard.h"
#include "hw.h"
#include "ui.h"
#include "apps.h"
#include "sound.h"
#include "overlay.h"

extern char main_head[];

char buf[100];


int main(void) {

	screen_init();
	hw_init();
	keyb_init();
	sound_init();
	screen_cursor_at(&point0);
	screen_cursor(0);

	overlay_init();
	ui_init();

	overlay_ensure(0);
	memcpy((char *)0x7C00, main_head, 8*40);

	do { 
		ui_poll();
	} while (1);

	return 0;

}

