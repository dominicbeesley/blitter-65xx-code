#include <string.h>
#include "ui.h"
#include "window.h"
#include "listbox.h"
#include "event.h"
#include "romset.h"
#include "util.h"
#include "strings.h"

static bool l_list_render(void *sender, void *args);
static bool app_rs_init(void *sender, void *arg);

extern char buf[];

ui_app app_romset = {
	{
		&app_rs_init,	//init
		NULL,			//poll
		NULL,			//keypress
		NULL			//render main
	}
};

static lb_def l_list; //TODO: make this global and share between apps?


bool l_list_render(void *sender, void *args) {
	romset romset_g;
	char *p = buf;
	unsigned long addr;
	const romset_cpu_def *cpu;
	point pp;
	lb_def *l;
	lb_item_render_args *lbi_args = (lb_item_render_args *)args;
	surface *s = lbi_args->surface;
	int ix = lbi_args->index;
	
	l = (lb_def *)sender;

	if (l->selected_index == ix) {
		*p++ = 0x86;
		*p++ = 0x9D;
		*p++ = 0x83;
	} else {
		*p++ = ' ';
		*p++ = ' ';
		*p++ = ' ';
	}

	addr = romset_get_index(ix, &romset_g);
	if (addr) {
		strncpy(p, romset_g.title, 32);
		p[32] = 0;
	} else {
		*p++ = '?';
		*p++ = 0;
	}

	surface_render_str(s, &point0, buf);
	
	cpu = romset_cpu_def_from_code(romset_g.cpu);
	pp.X = 0;
	pp.Y = 1;
	surface_render_str(s, &pp, "\x86");
	pp.X = 4;
	sprintf(buf, "ROMS:%d, CPU:%s\n", (long)romset_g.len, cpu?cpu->label:"UNKNOWN");
	surface_render_str(s, &pp, buf);

	return 1;
}

bool app_rs_init(void *sender, void *arg) {
	lb_init(&w_main, &l_list, &l_list_render, romset_count(), 2);
	l_list.selected_index = 0;
	set_head_title(str_head_mainmenu, str_head_pleaseselect);
	return 1;
}
