#ifndef __WINDOW_H__
#define __WINDOW_H__

#include "types.h"
#include "screen.h"
#include <stddef.h>
#include "coords.h"
#include "event.h"

#define WINDOW_OPT_NOCLEAR 	0x01

typedef struct win_struct_def win_def;

#define WIN_EVENT_RENDER		0
#define WIN_EVENT_KEYPRESS		1
#define WIN_EVENT_COUNT			2

struct win_struct_def {

	//position
	rectangle screenrect;
	point scroll;

	void *userdata;

	bool open;

	event_handler event_handlers[WIN_EVENT_COUNT];

	unsigned char options;

	win_def	*next;
};

extern win_def *win_list;

extern void win_init(win_def *w, unsigned char options, const rectangle *screenrect, void *userdata);
extern void win_open(win_def *w, bool top);
extern void win_redrwaw_all(void);
extern void win_refresh(win_def *w);
extern event_handler win_register_event(win_def *w, int event_index, event_handler handler);

extern bool win_event_dispatch(unsigned char event_index, void *arg);
extern void win_scroll(win_def *w, point *scroll);

#endif