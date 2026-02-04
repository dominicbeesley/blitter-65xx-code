#include "window.h"
#include "surface.h"
#include <string.h>
#include "debug.h"

win_def *win_list=NULL;

void win_init(
	win_def *w, 
	unsigned char options,
	const rectangle *screenrect,
	void *userdata) {

	w->screenrect = *screenrect;
	w->scroll.X = 0;
	w->scroll.Y = 0;
	
	w->userdata = userdata;

	w->open = 0;
	w->next = 0;

	w->options = options;

	memset(w->event_handlers, 0, sizeof(event_handler) * WIN_EVENT_COUNT);
}

event_handler win_register_event(win_def *w, int event_index, event_handler handler) {
	event_handler ret;

	if (event_index < 0 || event_index >= WIN_EVENT_COUNT)
		return NULL;

	ret = w->event_handlers[event_index];
	w->event_handlers[event_index] = handler;
	return ret;
}

void win_redraw_from(win_def *w) {
	surface s;
	rectangle r;
	r = w->screenrect;
	while (w) {
		if (rectangles_overlap(&w->screenrect, &r)) {
			surface_from_window(&s, w);
			if (!(w->options & WINDOW_OPT_NOCLEAR) || !w->event_handlers[WIN_EVENT_RENDER])
				surface_clear(&s, 0);
			if (w->event_handlers[WIN_EVENT_RENDER])
				(*w->event_handlers[WIN_EVENT_RENDER])(w, NULL);
			else
				surface_clear(&s, 0);
			rectangle_surround(&r, &w->screenrect, &r);
		}

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


win_def *win_get_focused(void) {
	//currently just returns top
	win_def *ret = win_list;
	while (ret && ret->next) {
		ret = ret->next;
	}
	return ret;
}

bool win_event_dispatch(unsigned char event_index, void *arg) {

	win_def *focused = win_get_focused();
	if (focused) {
		//NOT sure about this - maybe should dispatch all events, just user events for now
		switch (event_index) {
			case WIN_EVENT_KEYPRESS:
				if (focused->event_handlers[event_index])
					return(*focused->event_handlers[event_index])(focused, arg);
				break;
		}

		//TODO: should bubble events?		
	}

	return 0;
}

void win_scroll(win_def *w, point *scroll) {
	w->scroll = *scroll;
	win_refresh(w);
}