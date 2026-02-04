#include <string.h>
#include <ctype.h>
#include "ui.h"
#include "window.h"
#include "listbox.h"
#include "event.h"
#include "romset.h"
#include "util.h"
#include "strings.h"
#include "apps.h"
#include "debug.h"
#include "hw.h"
#include "hardware.h"
#include "layout.h"

extern char buf[];

extern void app_clearbb_reboot(void);

static bool app_clearbb_init(void *sender, void *arg);
static bool app_clearbb_kp(void *sender, void *arg);

const ui_app app_clearbb = {
	0,
	{
		&app_clearbb_init,	//init
		NULL,				//poll
		&app_clearbb_kp		//keypress
	}
};

#pragma code-name (push, "OVERLAY0")

const char *str_head_clearbb = "\x01" "Clear BB RAM";

bool app_clearbb_init(void *sender, void *arg) {
	surface s;
	point p;
	set_head_title(str_head_clearbb, str_head_areyousure);
	surface_from_window(&s, &w_main);
	surface_clear(&s, ' ');
	p = point0;
	surface_render_str(&s, &p, "The whole of BB RAM will be cleared in", 1);
	p.Y++;
	surface_render_str(&s, &p, "both maps!", 1);

	return 1;
}



bool app_clearbb_kp(void *sender, void *arg) {
	char c = *(char *)arg;
	point p;
	surface s;
	romloc *rl;

	switch (tolower(c)) {
		case 'y':

			set_head_title(str_head_clearbb, "\x06" "Clearing...");

			surface_from_window(&s, &w_main);
			surface_clear(&s, ' ');


			p = point0;
			rl = cur_layout;
			while (rl && rl->flags) {

				if (rl->flags & ROMLOC_FLAGS_BBRAM && !(rl->flags & ROMLOC_FLAGS_PREBOOT)) {
					sprintf(buf, "%02X %04X %02X", (long)rl->slot, (long)rl->page, (long)rl->flags);
					surface_render_str(&s, &p, buf, 0);
					erase_slot(rl);
					debug_printf("XX\n");
					p.Y ++;
				}

				rl++;
			}

			break;
		case 'n':
			ui_exit();
			break;
	}

	return 1;
}

#pragma code-name (pop)