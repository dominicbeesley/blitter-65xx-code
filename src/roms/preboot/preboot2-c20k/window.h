#ifndef __WINDOW_H__
#define __WINDOW_H__

#include "types.h"
#include "screen.h"
#include <stddef.h>
#include "coords.h"

#define WINDOW_OPT_NOCLEAR 	0x01

typedef struct win_struct_def win_def;

typedef bool (*win_event_handler)(win_def *win, void *arg);

#define EVENT_RENDER 0
#define EVENT_KEYPRESS 1
#define EVENT_COUNT 2

struct win_struct_def {

	//position
	rectangle screenrect;
	point scroll;

	void *userdata;

	bool open;

	win_event_handler event_handlers[EVENT_COUNT];

	unsigned char options;

	win_def	*next;
};

extern win_def *win_list;

extern void win_init(win_def *w, unsigned char options, const rectangle *screenrect, void *userdata);
extern void win_open(win_def *w, bool top);
extern void win_redrwaw_all(void);
extern void win_refresh(win_def *w);
extern win_event_handler win_register_event(win_def *w, int event_index, win_event_handler handler);

extern void win_event_dispatch(unsigned char event_index, void *arg);

#endif