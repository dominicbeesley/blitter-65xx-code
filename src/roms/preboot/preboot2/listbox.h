#ifndef __LISTBOX_H__
#define __LISTBOX_H__

#include "window.h"
#include "surface.h"

typedef struct lb_struct_def lb_def;

typedef struct lb_item_render_args {
	surface *surface;
	int index;
} lb_item_render_args;

struct lb_struct_def {
	win_def*			window;

	int					item_count;
	unsigned char		item_height;
	int					selected_index;

	event_handler		event_handler_render;

	void*				data;
};

extern void lb_init(win_def *w, lb_def *lb, event_handler render_handler, int item_count, unsigned char item_height);
extern void lb_set_item_height(lb_def *lb, unsigned char);
extern void lb_set_count(lb_def *lb, int);
extern void lb_close(lb_def *lb);


#endif