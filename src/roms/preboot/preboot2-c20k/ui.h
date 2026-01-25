#ifndef __UI_H__
#define __UI_H__

#include "event.h"
#include "window.h"

#define UI_EVENT_INIT			0
#define UI_EVENT_POLL			1
#define UI_EVENT_KEYPRESS 		2
#define UI_EVENT_RENDER_MAIN	3
#define UI_EVENT_COUNT			4

typedef struct ui_app {
	event_handler event_handlers[UI_EVENT_COUNT];
	
} ui_app;

extern void ui_start_app(ui_app *app);

extern void ui_poll(void);
extern void ui_init(void);

extern void set_head_title(const char *title, const char *subtitle);

extern win_def w_main;

#endif