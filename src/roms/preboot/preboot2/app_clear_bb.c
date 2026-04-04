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
#pragma local-strings(1)
#pragma rodata-name (push, "OVERLAY0_RO")

const char str_head_clearbb[] = "\x01" "Clear Sideways ROMs";
const char str_whichmap[] = "\x86Which map 0, 1, (B)oth";
const char str_flashram[] = "\x86(F)lash, (R)am, (B)oth";
const char str_start[] = "\x81Start (Y/N)";

static void do_erase(struct app_clearbb_data *opts);

bool clearbb_w_main_redraw(void *sender, void *arg) {
	surface s;
	point p;
	win_def *w = (win_def *)sender;
	ui_app_inst *appi = (ui_app_inst *)w->userdata;
	struct app_clearbb_data *data = (struct app_clearbb_data *)appi->data;
	unsigned char state = data->ui_state;

	p = point0;

	surface_from_window(&s, w);
	surface_clear(&s, ' ');

	if (state < 3) {
		p.X = surface_render_str(&s, &p, str_whichmap, 1);
		if (state >= 1) {
			surface_render_str(&s, &p, 
				(data->map == (ROMLOC_FLAGS_MAP0|ROMLOC_FLAGS_MAP1))?"->Both":
				(data->map == ROMLOC_FLAGS_MAP0)?"->Map 0":
				(data->map == ROMLOC_FLAGS_MAP1)?"->Map 1":
				"??",
				1);
			p.X = 0;
			p.Y++;
			p.X = surface_render_str(&s, &p, str_flashram, 1);
		}
		if (state >= 2) {
			surface_render_str(&s, &p, 
				(data->flash == (ROMLOC_FLAGS_BBRAM|ROMLOC_FLAGS_FLASH))?"->Both":
				(data->flash == ROMLOC_FLAGS_BBRAM)?"->Ram (BB)":
				(data->flash == ROMLOC_FLAGS_FLASH)?"->Flash":
				"??",
				1);
			p.X = 0;
			p.Y++;
			p.X = surface_render_str(&s, &p, str_start, 1);
		}
		surface_render_char(&s, &p, '?');
		p.X++;
		surface_cursor_at(&s, &p);
	} else {
		screen_cursor(0);
	}
	
	return 1;
}


bool app_clearbb_init(void *sender, void *arg) {

	ui_app_inst *appi = (ui_app_inst *)sender;
	struct app_clearbb_data *data = (struct app_clearbb_data *)appi->data;
	data->ui_state = 0;

	set_head_title(str_head_clearbb, "");

	win_register_event(&w_main, WIN_EVENT_RENDER, &clearbb_w_main_redraw);

	return 1;
}



bool app_clearbb_kp(void *sender, void *arg) {
	char c = *(char *)arg;
	ui_app_inst *appi = (ui_app_inst *)sender;
	struct app_clearbb_data *data = (struct app_clearbb_data *)appi->data;
	unsigned char state = data->ui_state;

	c = tolower(c);

	switch (state) {
		case 0:
			switch (c) {
				case '0':
					data->map = ROMLOC_FLAGS_MAP0;
					state = 1;
					break;
				case '1':
					data->map = ROMLOC_FLAGS_MAP1;
					state = 1;
					break;
				case 'b':
					data->map = ROMLOC_FLAGS_MAP1|ROMLOC_FLAGS_MAP1;
					state = 1;
					break;
			}
			break;
		case 1:
			switch (c) {
				case 'f':
					data->flash = ROMLOC_FLAGS_FLASH;
					state = 2;
					break;
				case 'r':
					data->flash = ROMLOC_FLAGS_BBRAM;
					state = 2;
					break;
				case 'b':
					data->flash = ROMLOC_FLAGS_FLASH|ROMLOC_FLAGS_BBRAM;
					state = 2;
					break;
			}
			break;
		case 2:
			switch (c) {
				case 'y':
					do_erase(data);
					set_status("Finished! Press a key...");
					state = 3;
					break;
				case 'n':
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
		if (state != 3)
			win_refresh(&w_main);
		return 1;
	} else
		return 0;
}

static void do_erase(struct app_clearbb_data *opts) {
	surface s;
	const romloc *rl;
	unsigned char skip;
	point p;
	point p2;

	p = point0;

	surface_from_window(&s, &w_main);
	surface_clear(&s, ' ');

	set_head_title(str_head_clearbb, "\x06" "Clearing...");
	screen_cursor(0);

	rl = cur_layout;
	while (rl && rl->flags) {
		if (rl->flags & opts->map && rl->flags & opts->flash) {
			if (rl->flags & ROMLOC_FLAGS_PREBOOT)
				skip = 2;
			else
				skip = 0;
		} else {
			skip = 1;
		}

		sprintf(buf, "%cM%cS%1x:", 
			(skip==0)?'\x86':
			(skip==1)?'\x84':
			'\x81', 
			(rl->flags & ROMLOC_FLAGS_MAP0)?'0':
			'1',
			(long)rl->slot);
		p2.Y = p.Y;
		p2.X = p.X + 1 + surface_render_str(&s, &p, buf, 0);

		if (skip == 0) {
			erase_slot(rl);
			surface_render_str(&s, &p2, "ERASED", 0);
		} else if (skip == 1) {
			surface_render_str(&s, &p2, "SKIP", 0);
		} else {
			surface_render_str(&s, &p2, "IN USE", 0);
		}

		p.Y ++;
		if (p.Y >= 16)
		{
			p.Y = 0;
			p.X += 13;
		}
		rl++;
	}

}

#pragma rodata-name (pop)
#pragma code-name (pop)