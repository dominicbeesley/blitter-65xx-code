#include <string.h>
#include "ui.h"
#include "window.h"
#include "listbox.h"
#include "event.h"
#include "romset.h"
#include "util.h"
#include "strings.h"
#include "apps.h"
#include "hw.h"
#include "hardware.h"
#include "debug.h"
#include "apps.h"

static bool l_list_render(void *sender, void *args);
static bool app_mm_init(void *sender, void *arg);
static bool app_mm_kp(void *sender, void *arg);

extern char buf[];

const ui_app app_main_menu = {
	0,
	{
		&app_mm_init,	//init
		NULL,			//poll
		&app_mm_kp		//keypress
	}
};

static lb_def l_list; //TODO: make this global and share between apps?

#pragma code-name (push, "OVERLAY0")


bool l_list_render(void *sender, void *args) {
	lb_def *l = (lb_def *)sender;
	ui_app_inst *appi = (ui_app_inst *)l->data;
	struct app_main_menu_data *menu = (struct app_main_menu_data *)appi->data;
	lb_item_render_args *lbi_args = (lb_item_render_args *)args;
	surface *s = lbi_args->surface;

	int ix = lbi_args->index;
	char *p;

	if (l->selected_index == ix) {
		p = "\x86\x9D\x83";
	} else {
		p = "   ";
	}
	sprintf(buf, "%s%d.%s", p, (long)ix, menu->items[ix].label);

	surface_render_str(s, &point0, buf, 1);

	return 1;
}

bool app_mm_init(void *sender, void *arg) {
	ui_app_inst *appi = (ui_app_inst *)sender;
	struct app_main_menu_data *menu = (struct app_main_menu_data *)appi->data;

	lb_init(&w_main, &l_list, &l_list_render, menu->item_count, 1);
	l_list.data = sender;
	l_list.selected_index = 0;
	set_head_title(str_head_mainmenu, str_head_pleaseselect);

	sprintf(buf, "%02X %02X %02X %02X"
		, (long)peek(sheila_MEM_LOMEMTURBO)
		, (long)peek(sheila_MEM_TURBO2)
		, (long)peek(sheila_ROM_THROTTLE_0)
		, (long)peek(sheila_ROM_THROTTLE_1)		
		);
	set_status(buf);
	return 1;
}

bool app_mm_kp(void *sender, void *arg) {
	ui_app_inst *appi = (ui_app_inst *)sender;
	struct app_main_menu_data *menu = (struct app_main_menu_data *)appi->data;

	char c = *(char *)arg;
	int ix = l_list.selected_index;

	if (c == 13) {
		if (ix >= 0 && ix < menu->item_count)
			ui_start_app(menu->items[ix].app, NULL);
		return 1;
	}
	return 0;
}

#pragma code-name (pop)