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
static bool app_rs_init(void *sender, void *arg);
static bool app_rs_kp(void *sender, void *arg);

extern char buf[];

ui_app app_romset = {
	0,
	{
		&app_rs_init,	//init
		NULL,			//poll
		&app_rs_kp,		//keypress
		NULL			//render main
	}
};

static lb_def l_list; //TODO: make this global and share between apps?

#pragma code-name (push, "OVERLAY0")

bool l_list_render(void *sender, void *args) {
	romset romset_g;
	char *p, *t;
	unsigned long addr;
	const romset_cpu_def *cpu;
	point pp;
	lb_def *l;
	lb_item_render_args *lbi_args = (lb_item_render_args *)args;
	surface *s = lbi_args->surface;
	int ix = lbi_args->index;
	
	l = (lb_def *)sender;

	if (l->selected_index == ix) {
		p = "\x86\x9D\x83";
	} else {
		p = "   ";
	}

	addr = romset_get_index(ix, &romset_g);
	if (addr) {
		t = &romset_g.title[0];
	} else {
		t = "?";
	}

	sprintf(buf, "%s%s", p, t);
	
	surface_render_str(s, &point0, buf, 1);
	
	cpu = romset_cpu_def_from_code(romset_g.cpu);
	pp.X = 0;
	pp.Y = 1;
	surface_render_str(s, &pp, "\x86", 0);
	pp.X = 4;
	sprintf(buf, "ROMS:%d, CPU:%s\n", (long)romset_g.len, cpu?cpu->label:"UNKNOWN");
	surface_render_str(s, &pp, buf, 1);

	return 1;
}

bool app_rs_init(void *sender, void *arg) {
	lb_init(&w_main, &l_list, &l_list_render, romset_count(), 2);
	l_list.selected_index = 0;
	set_head_title(str_head_mainmenu, str_head_pleaseselect);
	return 1;
}

bool app_rs_kp(void *sender, void *arg) {
	char c = *(char *)arg;
	int ix = l_list.selected_index;
	if (c == 13) {
		if (ix >= 0 && ix < l_list.item_count)
			ui_start_app(&app_romset_list, &ix);
		return 1;
	}
	return 0;
}

#pragma code-name (pop)