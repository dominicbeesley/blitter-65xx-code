#include <string.h>
#include "ui.h"
#include "window.h"
#include "listbox.h"
#include "util.h"
#include "buffer.h"
#include "debug.h"
#include "apps.h"
#include "spi.h"

#define APP_OVERLAY_SPI_BASE 0x704000
#define APP_OVERLAY_MEM 0x8000
#define APP_OVERLAY_SIZE 0x4000

extern char buf[];

ui_app_inst *cur_app = NULL;

rectangle r_head = {{3, 4}, {35, 3}};
rectangle r_status = {{0, 24}, {40, 1}};
rectangle r_main = {{0, 8}, {40, 16}};
win_def w_main;
win_def w_head;
win_def w_status;

static void ui_start_old(ui_app_inst *app, void *args);


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

	surface_render_str(&s, &p, head_title, 1);
	p.Y++;
	surface_render_str(&s, &p, head_title, 1);

	p.Y = 2;
	surface_render_str(&s, &p, head_subtitle, 1);

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
		surface_render_str(&s, &point0, status, 1);

	return 1;
}

void set_status(const char *s) {
	strncpy(status, s, sizeof(status));
	status[sizeof(status) - 1] = '0';
	win_refresh(&w_status);
}

ui_app_inst app_inst_clearbb = {
	&app_clearbb,
	NULL
};

ui_app_inst app_inst_reboot = {
	&app_reboot,
	NULL
};


const struct app_main_menu_mmi main_menu_items [] = {
	{"Clear Memory", &app_inst_clearbb},
	{"REBOOT", &app_inst_reboot}
};

const struct app_main_menu_data main_menu = {
	main_menu_items,
	sizeof(main_menu_items) / sizeof(struct app_main_menu_mmi)
};


ui_app_inst app_inst_main_menu = {
	&app_main_menu,
	NULL,
	&main_menu
};

void ui_exit(void) {
	if (cur_app != NULL && cur_app->parent != NULL)
		ui_start_old(cur_app->parent, NULL);
	else {
		cur_app = NULL;
		ui_start_app(&app_inst_main_menu, NULL);		
	}
}

void ui_poll() {

	char c;

	if (buffer_get(BUFFER_KEYBOARD, &c) >= 0) {
		if (!win_event_dispatch(WIN_EVENT_KEYPRESS, &c)) {
			if (
					!cur_app
				 || !cur_app->def->event_handlers[UI_EVENT_KEYPRESS]
				 || !cur_app->def->event_handlers[UI_EVENT_KEYPRESS](cur_app, &c)
				)
				{
					switch (c) {
						case 0x1B:
							//escape
							ui_exit();
					}
				}
		}
	}
}


void ui_init() {
	win_init(&w_head, WINDOW_OPT_NOCLEAR, &r_head, NULL);
	win_register_event(&w_head, WIN_EVENT_RENDER, &render_head);
	win_open(&w_head, 0);

	win_init(&w_status, WINDOW_OPT_NOCLEAR, &r_status, NULL);
	win_register_event(&w_status, WIN_EVENT_RENDER, &render_status);
	win_open(&w_status, 1);



	win_init(&w_main, WINDOW_OPT_NOCLEAR, &r_main, NULL);
	win_open(&w_main, 1);

	cur_app = NULL;
	ui_start_app(&app_inst_main_menu, NULL);
}

void ui_start_app(ui_app_inst *app, void *args) {
	app->parent = cur_app;
	ui_start_old(app, args);
}

void ui_start_old(ui_app_inst *app, void *args) {
	unsigned char cksum;
	unsigned char *p;
	int i;

	w_main.scroll = point0;
	w_status.scroll = point0;
	w_head.scroll = point0;

	set_status("");
	set_head_title("", "");

	if (app == NULL)
	{
		set_status("App NULL");
		cur_app = NULL;
		return;
	}

	if (cur_app == NULL || cur_app->def->overlay_ix != app->def->overlay_ix) {
		set_status("loading...");
		spi_read_buf(
			(void *)APP_OVERLAY_MEM, 
			(unsigned long)APP_OVERLAY_SPI_BASE + (unsigned long)app->def->overlay_ix*(long)APP_OVERLAY_SIZE,
			APP_OVERLAY_SIZE
			);
		cksum = 0;
		for (p = (char *)0x8000; p < (char *)0xC000; p++)
			cksum += *p;
		if (cksum != 0)
		{
			sprintf(buf, "Bad CKSUM %X : %02X", 
				(long)app->def->overlay_ix, 
				(long)cksum);
			set_status(buf);
			cur_app = NULL;
			return;
		}

		//checksum check
	}

	set_status("");
	cur_app = app;

	for (i = 0; i < WIN_EVENT_COUNT; i++) {
		win_register_event(&w_main, i, NULL);
	}

	app->def->event_handlers[UI_EVENT_INIT](app, args);	
	win_refresh(&w_main);
	win_refresh(&w_head);
	win_refresh(&w_status);
}
