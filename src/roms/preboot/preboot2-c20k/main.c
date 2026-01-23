#include <string.h>
#include "types.h"
#include "screen.h"
#include "window.h"
#include "surface.h"
#include "listbox.h"
#include "hex.h"
#include "keyboard.h"
#include "hw.h"
#include "debug.h"
#include "util.h"
#include "romset.h"
#include "buffer.h"
#include "coords.h"

extern char main_head[];

const char *w_main_data = "HELLO WORLD";

rectangle r_head = {{3, 4}, {35, 3}};
rectangle r_status = {{0, 24}, {40, 1}};
rectangle r_main = {{0, 8}, {40, 16}};
win_def w_main;
win_def w_head;
win_def w_status;
lb_def l_list;

char buf[100];


const char *str_head_mainmenu = "\x02Main Menu";
const char *str_head_pleaseselect = "\x06" "Cursor selects item, press return.";

const char *head_title;
const char *head_subtitle;
const char *status;
bool render_head(win_def *w, void *arg) {
	surface s;
	point p;

	debug_printf("RP\n");

	p = point0;

	surface_from_window(&s, w);

	if (head_title) {
		surface_render_str(&s, &p, head_title);
		p.Y++;
		surface_render_str(&s, &p, head_title);
	}

	if (head_subtitle) {
		p.Y = 2;
		surface_render_str(&s, &p, head_subtitle);
	}
	return 1;	
}

void set_head_title(const char *title, const char *subtitle) {
	head_title = title;
	head_subtitle = subtitle;
	win_refresh(&w_head);
}


bool render_status(win_def *w, void *arg) {
	surface s;
	surface_from_window(&s, w);

	if (status) 
		surface_render_str(&s, &point0, status);

	return 1;
}

void set_status(const char *s) {
	status = s;
	win_refresh(&w_status);
}

romset romset_g;

void l_list_render(win_def *w, lb_def *l, surface *s, int ix) {
	char *p = buf;
	unsigned long addr;
	const romset_cpu_def *cpu;
	point pp;
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
}


int main(void) {

	char c;

	debug_printf("HELLO\n");

	screen_init();
	hw_init();
	keyb_init();

	memcpy((char *)0x7C00, main_head, 8*40);

	screen_cursor_at(&point0);
	screen_cursor(0);

	win_init(&w_head, 0, &r_head, NULL);
	win_register_event(&w_head, EVENT_RENDER, &render_head);
	win_open(&w_head, 0);

	win_init(&w_status, WINDOW_OPT_NOCLEAR, &r_status, NULL);
	win_register_event(&w_status, EVENT_RENDER, &render_status);
	win_open(&w_status, 1);



	win_init(&w_main, WINDOW_OPT_NOCLEAR, &r_main, NULL);
//	win_register_event(&w_main, EVENT_RENDER, &render_main);
	win_open(&w_main, 1);
	

	lb_init(&w_main, &l_list, &l_list_render, romset_count(), 2);
	l_list.selected_index = 0;
	win_refresh(&w_main);

	set_head_title(str_head_mainmenu, str_head_pleaseselect);

	do { 

		if (buffer_get(BUFFER_KEYBOARD, &c) >= 0) {
			win_event_dispatch(EVENT_KEYPRESS, &c);
		}

		//win_refresh(&w_main);
		win_refresh(&w_status);

	} while (1);

	return 0;

}