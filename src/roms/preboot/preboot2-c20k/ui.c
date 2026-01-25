#include <string.h>
#include "ui.h"
#include "window.h"
#include "listbox.h"
#include "util.h"
#include "buffer.h"

extern char buf[];

rectangle r_head = {{3, 4}, {35, 3}};
rectangle r_status = {{0, 24}, {40, 1}};
rectangle r_main = {{0, 8}, {40, 16}};
win_def w_main;
win_def w_head;
win_def w_status;

const char *head_title;
const char *head_subtitle;
const char *status;
bool render_head(void *sender, void *arg) {
	surface s;
	point p;
	win_def *w;

	w = (win_def *)sender;

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


bool render_status(void *sender, void *arg) {
	surface s;
	win_def *w;

	w = (win_def *)sender;

	surface_from_window(&s, w);

	if (status) 
		surface_render_str(&s, &point0, status);

	return 1;
}

void set_status(const char *s) {
	status = s;
	win_refresh(&w_status);
}


void ui_poll() {

	char c;

	if (buffer_get(BUFFER_KEYBOARD, &c) >= 0) {
		win_event_dispatch(WIN_EVENT_KEYPRESS, &c);
	}

}

extern ui_app app_romset;

void ui_init() {
	win_init(&w_head, 0, &r_head, NULL);
	win_register_event(&w_head, WIN_EVENT_RENDER, &render_head);
	win_open(&w_head, 0);

	win_init(&w_status, WINDOW_OPT_NOCLEAR, &r_status, NULL);
	win_register_event(&w_status, WIN_EVENT_RENDER, &render_status);
	win_open(&w_status, 1);



	win_init(&w_main, WINDOW_OPT_NOCLEAR, &r_main, NULL);
	win_register_event(&w_main, WIN_EVENT_RENDER, app_romset.event_handlers[UI_EVENT_RENDER_MAIN]);
	win_open(&w_main, 1);

	app_romset.event_handlers[UI_EVENT_INIT](&app_romset, NULL);
	
	
}