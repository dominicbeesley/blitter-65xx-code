#include "window.h"
#include <string.h>

win_def *win_list=NULL;

void win_init(win_def *w, screen_coord left, screen_coord top, screen_coord width, screen_coord height, void *userdata) {

	w->left = left;
	w->top = top;
	w->width = width;
	w->height = height;

	w->userdata = userdata;

	w->open = 0;
	w->next = 0;

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
	while (w) {

		if (w->event_handlers[EVENT_RENDER])
			(*w->event_handlers[EVENT_RENDER])(w);

		w = w->next;
	}

}

void win_clear(win_def *w) {
	screen_coord x, y;
	for (y = w->top; y < w->top + w->height; y++)
		for (x = w->left; x < w->left + w->width; x++)
			screen_print_at(x, y, 0);
}

void win_redraw_all(void) {
	win_redraw_from(win_list);
}

void win_refresh(win_def *w) {
	win_clear(w);
	win_redraw_from(w);
}

void win_open(win_def *w, screen_bool top) {
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

void win_render_str(win_def *w, screen_coord X, screen_coord Y, const char *str) {
	screen_coord SX, SY;
	const char *p = str;

	if (Y < 0 || Y >= w->height)
		return;

	SX = w->left + X;
	SY = w->top + Y;
	while (*p) {
		if (X >= 0 && X < w->width)
			screen_print_at(SX, SY, *p);
		p++;
		SX++;
		X++;
	}
}


