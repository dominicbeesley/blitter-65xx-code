#include <string.h>
#include "ui.h"
#include "window.h"
#include "listbox.h"
#include "event.h"
#include "romset.h"
#include "util.h"
#include "strings.h"
#include "apps.h"

static bool app_reboot_init(void *sender, void *arg);

ui_app app_reboot = {
	{
		&app_reboot_init,	//init
		NULL,				//poll
		NULL,				//keypress
		NULL				//render main
	}
};

bool app_reboot_init(void *sender, void *arg) {
	set_head_title(str_head_reboot, str_head_areyousure);
	return 1;
}
