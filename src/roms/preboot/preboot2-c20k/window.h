#ifndef __WINDOW_H__
#define __WINDOW_H__

#include "screen.h"
#include <stddef.h>

typedef struct win_struct_def win_def;

typedef screen_bool (*event_handler)(win_def *win);


struct win_struct_def {

	//position
	screen_coord left;
	screen_coord top;
	screen_coord width;
	screen_coord height;

	screen_coord scroll_left;	//positive values move _content_ left
	screen_coord scroll_top;	//positive values move _content_ up

	void *userdata;

	screen_bool open;

	win_def	*next;
};

extern win_def *win_list;

extern void win_init(win_def *w, screen_coord left, screen_coord top, screen_coord width, screen_coord height, void *userdata);
extern void win_open(win_def *w, screen_bool top);
extern void win_redrwaw_all(void);

#endif