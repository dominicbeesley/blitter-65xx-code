#ifndef __WINDOW_H__
#define __WINDOW_H__

#include "screen.h"
#include <stddef.h>

typedef struct win_struct_def win_def;

typedef screen_bool (*win_event_handler)(win_def *win);

#define EVENT_RENDER 0
#define EVENT_COUNT 1

struct win_struct_def {

	//position
	screen_coord left;
	screen_coord top;
	screen_coord width;
	screen_coord height;

	void *userdata;

	screen_bool open;

	win_event_handler event_handlers[EVENT_COUNT];

	win_def	*next;
};

extern win_def *win_list;

extern void win_init(win_def *w, screen_coord left, screen_coord top, screen_coord width, screen_coord height, void *userdata);
extern void win_open(win_def *w, screen_bool top);
extern void win_redrwaw_all(void);
extern void win_refresh(win_def *w);
extern win_event_handler win_register_event(win_def *w, int event_index, win_event_handler handler);

#endif