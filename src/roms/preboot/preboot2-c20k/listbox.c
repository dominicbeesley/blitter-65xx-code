#include "window.h"
#include "surface.h"
#include "listbox.h"
#include "hex.h"

screen_bool lb_render_win(win_def *w) {	
	char *p;
	surface sw;
	surface sw_i;
	screen_coord X,Y,W; //TODO: LB width?
	lb_def *lb;
	int ix;


	lb = (lb_def *)w->userdata;

	surface_from_window(&sw, w);
	if (sw.scroll_Y > 0)
		ix = sw.scroll_Y /  lb->item_height;
	else
		ix = 0;

	X = sw.scroll_X;
	W = sw.scroll_X + sw.width;
	Y = ix * lb->item_height;

	while (Y < sw.scroll_Y + sw.height && 
		ix < lb->item_count) {

		if ( (lb->event_handler_render) )
		if (surface_from_rect(&sw, &sw_i, X, Y, W, lb->item_height))
		{
			surface_clear(&sw_i, 0);
			(*lb->event_handler_render)(w, lb, &sw_i, ix);
		}
		
		ix++;
		Y+=lb->item_height;
	}

	return 1;
}

void lb_init(win_def *w, lb_def *lb, lb_render_handler render, int item_count, unsigned char item_height) {
	lb->window = w;
	lb->item_count = item_count;
	lb->item_height = item_height;
	lb->event_handler_render = render;
	lb->selected_index = -1;
	
	w->userdata = lb;
	win_register_event(w, EVENT_RENDER, &lb_render_win);	

	win_refresh(w);
}


void lb_set_item_height(lb_def *lb, unsigned char item_height) {
	lb->item_height = item_height;
	win_refresh(lb->window);
}

void lb_set_count(lb_def *lb, int item_count) {
	lb->item_count = item_count;
	win_refresh(lb->window);
}

