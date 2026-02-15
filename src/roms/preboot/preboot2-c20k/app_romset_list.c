#include <string.h>
#include "ui.h"
#include "window.h"
#include "listbox.h"
#include "event.h"
#include "romset.h"
#include "util.h"
#include "debug.h"

int romset_ix;

static bool l_list_render(void *sender, void *args);
static bool app_rsl_init(void *sender, void *arg);

extern char buf[];

const ui_app app_romset_list = {
	0,
	{
		&app_rsl_init,	//init
		NULL,			//poll
		NULL			//keypress
	}
};

static lb_def l_list; //TODO: make this global and share between apps?

#pragma code-name (push, "OVERLAY0")
#pragma local-strings(1)
#pragma rodata-name (push, "OVERLAY0_RO")

const char str_romsetlist[] = "\x82List Romset contents";

bool l_list_render(void *sender, void *args) {
	romset_rom_desc rd;
	char *p, *t;
	bool fnd;
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

	fnd = romset_get_rom(romset_ix, ix, &rd);
	if (fnd) {
		t = &rd.title[0];
	} else {
		t = "?";
	}

	sprintf(buf, "%s%c.%s", 
		p, 
		romset_slot_char(rd.slot),
		t);

	surface_render_str(s, &point0, buf, 1);

	cpu = romset_cpu_def_from_code(rd.cpu);

	romset_rom_type_string(buf+128, rd.ext_type, rd.rom_type);

	sprintf(buf, "\x82%16.16s %12.12s %X",
		buf+128,
		cpu?cpu->label:"?",
		(long)rd.crc);

	pp.X = 3;
	pp.Y = 1;
	surface_render_str(s, &pp, buf, 1);
	
	return 1;
}

bool app_rsl_init(void *sender, void *arg) {
	romset r;
	int ct;
	if (arg) {
		//if new invocation set arg, else remember
		romset_ix = *(int *)arg;
	}

	if (romset_get_index(romset_ix, &r))
		ct = r.len;
	else
		ct = 0;

	lb_init(&w_main, &l_list, &l_list_render, ct, 2);
	l_list.selected_index = 0;
	sprintf(buf, "\x83%s", r.title);
	set_head_title(str_romsetlist, buf);
	return 1;
}

#pragma rodata-name (pop)
#pragma code-name (pop)