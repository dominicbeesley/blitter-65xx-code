#include <string.h>
#include "ui.h"
#include "window.h"
#include "listbox.h"
#include "event.h"
#include "romset.h"
#include "util.h"
#include "strings.h"
#include "apps.h"

static bool l_list_render(void *sender, void *args);
static bool app_mm_init(void *sender, void *arg);
static bool app_mm_kp(void *sender, void *arg);

struct mmi {
	const char *label;
	ui_app *app;
};

#define MMI_COUNT 11
struct mmi menuitems [] = {
	{"ROMSET", &app_romset},
	{"ROMSET", &app_romset},
	{"ROMSET", &app_romset},
	{"ROMSET", &app_romset},
	{"ROMSET", &app_romset},
	{"ROMSET", &app_romset},
	{"ROMSET", &app_romset},
	{"ROMSET", &app_romset},
	{"ROMSET", &app_romset},
	{"ROMSET", &app_romset},
	{"REBOOT", &app_reboot}
};


extern char buf[];

ui_app app_main_menu = {
	{
		&app_mm_init,	//init
		NULL,			//poll
		&app_mm_kp,		//keypress
		NULL			//render main
	}
};

static lb_def l_list; //TODO: make this global and share between apps?

bool l_list_render(void *sender, void *args) {
	point pp;
	lb_def *l;
	lb_item_render_args *lbi_args = (lb_item_render_args *)args;
	surface *s = lbi_args->surface;
	int ix = lbi_args->index;
	char *p;

	l = (lb_def *)sender;

	if (l->selected_index == ix) {
		p = "\x86\x9D\x83";
	} else {
		p = "   ";
	}
	sprintf(buf, "%s%d.%s", p, (long)ix, menuitems[ix].label);

	surface_render_str(s, &point0, buf);

	return 1;
}

bool app_mm_init(void *sender, void *arg) {
	lb_init(&w_main, &l_list, &l_list_render, MMI_COUNT, 2);
	l_list.selected_index = 0;
	set_head_title(str_head_mainmenu, str_head_pleaseselect);
	return 1;
}

bool app_mm_kp(void *sender, void *arg) {
	char c = *(char *)arg;
	int ix = l_list.selected_index;
	if (c == 13) {
		if (ix >= 0 && ix < MMI_COUNT)
			ui_start_app(menuitems[ix].app, NULL);
		return 1;
	}
	return 0;
}
