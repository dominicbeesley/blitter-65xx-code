#include <string.h>
#include "ui.h"
#include "window.h"
#include "listbox.h"
#include "util.h"
#include "buffer.h"

extern char buf[];

ui_app *cur_app;

rectangle r_head = {{3, 4}, {35, 3}};
rectangle r_status = {{0, 24}, {40, 1}};
rectangle r_main = {{0, 8}, {40, 16}};
win_def w_main;
win_def w_head;
win_def w_status;

static void ui_start_old(ui_app *app, void *args);


char head_title[34];
char head_subtitle[34];
char status[34];
bool render_head(void *sender, void *arg) {
	surface s;
	point p;
	win_def *w;

	w = (win_def *)sender;

	p = point0;

	surface_from_window(&s, w);

	surface_render_str(&s, &p, head_title);
	p.Y++;
	surface_render_str(&s, &p, head_title);

	p.Y = 2;
	surface_render_str(&s, &p, head_subtitle);

	return 1;	
}

void set_head_title(const char *title, const char *subtitle) {
	strncpy(head_title, title, sizeof(head_title));
	head_title[sizeof(head_title)-1] = 0;
	strncpy(head_subtitle, subtitle, sizeof(head_subtitle));
	head_subtitle[sizeof(head_subtitle)-1] = 0;
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
	strncpy(status, s, sizeof(status));
	status[sizeof(status) - 1] = '0';
	win_refresh(&w_status);
}


void ui_poll() {

	char c;

	if (buffer_get(BUFFER_KEYBOARD, &c) >= 0) {
		if (!win_event_dispatch(WIN_EVENT_KEYPRESS, &c)) {
			if (
					!cur_app
				 || !cur_app->event_handlers[UI_EVENT_KEYPRESS]
				 || !cur_app->event_handlers[UI_EVENT_KEYPRESS](cur_app, &c)
				)
				{
					switch (c) {
						case 0x1B:
							//escape
							if (cur_app != NULL && cur_app->parent != NULL) {
								ui_start_old(cur_app->parent, NULL);
							}
					}
				}
		}
	}

}


void ui_init() {
	win_init(&w_head, 0, &r_head, NULL);
	win_register_event(&w_head, WIN_EVENT_RENDER, &render_head);
	win_open(&w_head, 0);

	win_init(&w_status, WINDOW_OPT_NOCLEAR, &r_status, NULL);
	win_register_event(&w_status, WIN_EVENT_RENDER, &render_status);
	win_open(&w_status, 1);



	win_init(&w_main, WINDOW_OPT_NOCLEAR, &r_main, NULL);
	win_open(&w_main, 1);

}

void ui_start_app(ui_app *app, void *args) {
	app->parent = cur_app;
	ui_start_old(app, args);
}
void ui_start_old(ui_app *app, void *args) {
	cur_app = app;

	w_main.scroll = point0;
	w_status.scroll = point0;
	w_head.scroll = point0;
	set_status("");
	set_head_title("", "");

	win_register_event(&w_main, WIN_EVENT_RENDER, app->event_handlers[UI_EVENT_RENDER_MAIN]);
	app->event_handlers[UI_EVENT_INIT](app, args);	
	win_refresh(&w_main);
	win_refresh(&w_head);
	win_refresh(&w_status);
}