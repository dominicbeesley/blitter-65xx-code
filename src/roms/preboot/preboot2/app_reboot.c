#include <string.h>
#include <ctype.h>
#include "ui.h"
#include "window.h"
#include "listbox.h"
#include "event.h"
#include "romset.h"
#include "util.h"
#include "apps.h"
#include "debug.h"
#include "hw.h"
#include "coords.h"



extern void app_reboot_reboot(void);

static bool app_reboot_init(void *sender, void *arg);
static bool app_reboot_kp(void *sender, void *arg);

const ui_app app_reboot = {
	0,
	{
		&app_reboot_init,	//init
		NULL,				//poll
		&app_reboot_kp		//keypress
	}
};

#pragma code-name (push, "OVERLAY0")
#pragma local-strings(1)
#pragma rodata-name (push, "OVERLAY0_RO")

static const char str_head_reboot[] = "\x81REBOOT";
static const char str_head_areyousure[] = "\x88\x87" "Are you sure (Y/N)?\x89";

bool app_reboot_init(void *sender, void *arg) {
	
	set_head_title(str_head_reboot, str_head_areyousure);
	return 1;
}

bool app_reboot_kp(void *sender, void *arg) {
	char c = *(char *)arg;
	point p;
	surface s;
	unsigned long t;
	
	switch (tolower(c)) {
		case 'y':

			set_head_title("", "");

			p.Y = 0;
			surface_from_window(&s, &w_main);
			surface_clear(&s, ' ');
			
			for (p.X = 0; p.X < 38; p.X++) {
				t = get_time();
				surface_render_str(&s, &p, ".>", 0);
				while (get_time() == t) ;
			}

			app_reboot_reboot();
			break;
		case 'n':
			ui_exit();
			break;
	}

	return 1;
}

#pragma rodata-name (pop)
#pragma code-name (pop)