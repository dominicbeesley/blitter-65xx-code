#ifndef __UI_H__
#define __UI_H__

#include "event.h"
#include "window.h"

#define UI_EVENT_INIT			0
#define UI_EVENT_POLL			1
#define UI_EVENT_KEYPRESS 		2
#define UI_EVENT_COUNT			4

typedef struct ui_app {
	unsigned char overlay_ix;
	event_handler event_handlers[UI_EVENT_COUNT];
	struct ui_app *parent;	
} ui_app;

typedef struct ui_app_inst {
	const ui_app *def;
	struct ui_app_inst *parent;
	void *data;
} ui_app_inst;

extern void ui_start_app(ui_app_inst *app, void *args);

extern void ui_poll(void);
extern void ui_init(void);
extern void ui_exit(void);

extern void set_head_title(const char *title, const char *subtitle);
extern void set_status(const char *s);

extern win_def w_main;

#endif