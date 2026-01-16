#ifndef __LISTBOX_H__
#define __LISTBOX_H__

#include "window.h"
#include "surface.h"

typedef struct lb_struct_def lb_def;

typedef void (*lb_render_handler)(win_def *win, lb_def *, surface *, int index);

struct lb_struct_def {
	win_def*			window;

	int					item_count;
	unsigned char		item_height;
	int					selected_index;

	lb_render_handler	event_handler_render;
};

extern void lb_init(win_def *w, lb_def *lb, lb_render_handler render, int item_count, unsigned char item_height);
extern void lb_set_item_height(lb_def *lb, unsigned char);
extern void lb_set_count(lb_def *lb, int);



#endif