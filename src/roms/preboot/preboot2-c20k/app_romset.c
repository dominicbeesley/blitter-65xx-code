#include <ctype.h>
#include <string.h>
#include "ui.h"
#include "window.h"
#include "listbox.h"
#include "event.h"
#include "romset.h"
#include "util.h"
#include "apps.h"
#include "layout.h"

static bool l_list_render(void *sender, void *args);
static bool app_rs_init(void *sender, void *arg);
static bool app_rs_kp(void *sender, void *arg);
static void do_loadromset(struct app_romset_data *opt, bool check);
static void do_askmap(void);

extern char buf[];

const ui_app app_romset = {
	0,
	{
		&app_rs_init,	//init
		NULL,			//poll
		&app_rs_kp		//keypress
	}
};

static lb_def l_list; //TODO: make this global and share between apps?

#pragma code-name (push, "OVERLAY0")
#pragma local-strings(1)
#pragma rodata-name (push, "OVERLAY0_RO")

static const char str_head_romset[] = "\x82" "ROMSET load";
static const char str_head_pick_map[] = "\x82" "Which map?";
static const char str_head_areyousure[] = "\x88\x87" "Are you sure (Y/N)?\x89";
static const char str_head_pleaseselect[] = "\x86" "Cursor selects item, press return.";
static const char str_main_map[] ="\x87" "Map 0/1";


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
	surface s;
	ui_app_inst *appi = (ui_app_inst *)sender;
	struct app_romset_data *data = (struct app_romset_data *)appi->data;
	data->ui_state = 0;

	surface_from_window(&s,&w_main);
	surface_clear(&s, ' ');
	lb_init(&w_main, &l_list, &l_list_render, romset_count(), 2);
	l_list.selected_index = 0;
	set_head_title(str_head_romset, str_head_pleaseselect);
	return 1;
}

ui_app_inst app_romset_list_inst = {
	&app_romset,
	NULL
};

bool app_rs_kp(void *sender, void *arg) {
	char c = *(char *)arg;
	ui_app_inst *appi = (ui_app_inst *)sender;
	struct app_romset_data *data = (struct app_romset_data *)appi->data;
	unsigned char state = data->ui_state;
	int ix;

	c = tolower(c);

	switch (state)
	{
		case 0:
			ix = l_list.selected_index;
			if (c == 13) {
				if (ix >= 0 && ix < l_list.item_count) {
					state = 1;
					lb_close(&l_list);
					data->romset_ix = ix;
					do_askmap();
				}
			}
			break;
		case 1:
			if (c == '0') {
				data->map = ROMLOC_FLAGS_MAP0;
				do_loadromset(data, 1);
				state = 2;
			} else if (c == '1') {
				data->map = ROMLOC_FLAGS_MAP1;
				do_loadromset(data, 1);				
				state = 2;
			}
			break;
		case 2:
			if (c == 'y')
			{
				state = 3;
				do_loadromset(data, 0);
			} else if (c == 'n') {
				ui_exit();
				return 1;
			}
			break;
		case 3:
			ui_exit();
			return 1;
	}

	if (state != data->ui_state) {
		data->ui_state = state;
		win_refresh(&w_main);
		return 1;
	} else
		return 0;
}

static void do_askmap() {
	surface s;
	surface_from_window(&s, &w_main);
	surface_clear(&s, ' ');
	set_head_title(str_head_romset, str_head_pick_map);
	surface_render_str(&s, &point0, str_main_map, 1);
}

static void do_loadromset(struct app_romset_data *opt, bool check) {
	surface s;
	const romloc *rl;
	point p;
	point p2;
	unsigned long addr;
	romset romset_g;
	romset_rom_desc rom_g;
	int ix;

	p = point0;

	surface_from_window(&s, &w_main);
	surface_clear(&s, ' ');

	set_head_title(str_head_romset, (check)?"\x88\x87" "Are you sure?" "\x89":"\x06" "Loading...");
	set_status((opt->map == ROMLOC_FLAGS_MAP0)?"Romset will be loaded to map 0":"Romset will be loaded to map 1");
	screen_cursor(0);

	addr = romset_get_index(opt->romset_ix, &romset_g);
	if (!addr) {
		surface_render_str(&s, &p, "\x81" "Failed to locate ROMSET!", 0);
		return;
	} else {
		sprintf(buf, "\x82%31.31s %07X", romset_g.title, addr);
		surface_render_str(&s, &p, buf, 0);
	}
	p.Y++;

	for (ix = 0; ix < romset_g.len; ix++) {
		addr = romset_get_rom(opt->romset_ix, ix, &rom_g);
		if (!addr) {
			sprintf(buf, "\x81" "UNEX: ROM %s %d", (long)opt->romset_ix, (long)ix);
			surface_render_str(&s, &p, buf, 0);
			return;
		}
		sprintf(buf, "\x82" "%c %12.12s %24.24s", 
			romset_slot_char(rom_g.slot), 
			romset_rom_type_string(buf + 128, rom_g.ext_type, rom_g.rom_type), 
			rom_g.title);
		surface_render_str(&s, &p, buf, 0);
		p.Y++;

		//find a matching romloc
		rl = layout_find_romset(&rom_g, opt->map);
		if (!rl)
			sprintf(buf, "\x86WARN: no matching slot!");
		else
			sprintf(buf, "\x85 -- Write  \x85%08x to %04x00", addr, (long)rl->page);
		surface_render_str(&s, &p, buf, 0);

		if (!check) {
			p.X = 4;
			surface_render_char(&s, &p, '\x81');
			write_slot_from_spi(rl, addr);
			surface_render_char(&s, &p, '\x87');
			p.X = 9;
			surface_render_str(&s, &p, "ten", 0);
			p.X = 0;
		}
		p.Y++;

	}
	


}


#pragma rodata-name (pop)
#pragma code-name (pop)