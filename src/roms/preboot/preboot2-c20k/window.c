#include "window.h"
#include "surface.h"
#include <string.h>

win_def *win_list=NULL;

void win_init(
	win_def *w, 
	unsigned char options,
	coord left, 
	coord top,
	coord width,
	coord height,
	void *userdata) {

	w->left = left;
	w->top = top;
	w->width = width;
	w->height = height;

	w->scroll_X = 0;
	w->scroll_Y = 0;

	w->userdata = userdata;

	w->open = 0;
	w->next = 0;

	w->options = options;

	memset(w->event_handlers, 0, sizeof(win_event_handler) * EVENT_COUNT);
}

win_event_handler win_register_event(win_def *w, int event_index, win_event_handler handler) {
	win_event_handler ret;

	if (event_index < 0 || event_index >= EVENT_COUNT)
		return NULL;

	ret = w->event_handlers[event_index];
	w->event_handlers[event_index] = handler;
	return ret;
}

void win_redraw_from(win_def *w) {
	surface s;
	while (w) {
		surface_from_window(&s, w);
		if (!(w->options & WINDOW_OPT_NOCLEAR))
			surface_clear(&s, 0);
		if (w->event_handlers[EVENT_RENDER])
			(*w->event_handlers[EVENT_RENDER])(w);

		w = w->next;
	}

}

void win_redraw_all(void) {
	win_redraw_from(win_list);
}

void win_refresh(win_def *w) {
	win_redraw_from(w);
}

void win_open(win_def *w, bool top) {
	win_def **ww = &win_list;
	
	if (!win_list)
		win_list = w;
	else {

		while (1) {
			if (*ww == w) {
				*ww = (*ww)->next;
			}
			if (!(*ww)->next)
				break;
			else
				ww = &(*ww)->next;
		}

		if (top) 
		{
			(*ww)->next = w;
			w->next = NULL;
		}
		else
		{
			w->next = win_list;
			win_list = w;
		}
	}

	w->open = 1;

	win_refresh(w);
}




