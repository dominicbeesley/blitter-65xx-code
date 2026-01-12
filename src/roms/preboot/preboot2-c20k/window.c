#include "window.h"

win_def *win_list=NULL;

void win_init(win_def *w, screen_coord left, screen_coord top, screen_coord width, screen_coord height, void *userdata) {

	*((char *)0x7C00) = 'I';


	w->left = left;
	w->top = top;
	w->width = width;
	w->height = height;

	w->userdata = userdata;

	w->open = 0;
	w->next = 0;
}

char r = 'a';
void win_redraw_from(win_def *w) {
	
	screen_coord x, y;
	
	*((char *)0x7C00) = 'R';

	for (y = w->top; y < w->top + w->height; y++)
		for (x = w->left; x < w->left + w->width; x++)
			screen_print_at(x, y, r);

	r++;
	if (r> 'z')
		r = 'a';
}

void win_redraw_all(void) {
	win_redraw_from(win_list);
}


void win_open(win_def *w, screen_bool top) {
	win_def **ww = &win_list;
	
	if (!win_list)
		win_list = w;
	else {

		*((char *)0x7C00) = 'O';

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

	win_redraw_from(w);
}


