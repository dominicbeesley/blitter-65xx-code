#include "window.h"
#include "surface.h"
#include "listbox.h"
#include "hex.h"
#include "keyboard.h"

bool lb_render_win(win_def *w, void *arg) {	
	surface sw;
	surface sw_i;
	coord X,Y,W,H; //TODO: LB width?
	lb_def *lb;
	int ix;

	lb = (lb_def *)w->userdata;

	if ( lb->event_handler_render == NULL)
		return 0;

	surface_from_window(&sw, w);
	if (sw.scroll_Y > 0)
		ix = sw.scroll_Y /  lb->item_height;
	else
		ix = 0;

	X = sw.scroll_X;
	W = sw.width;
	H = lb->item_height;
	Y = ix * lb->item_height;

	while (Y < sw.scroll_Y + sw.height && 
		ix < lb->item_count) {

		if (surface_from_rect(&sw, &sw_i, X, Y, W, H))
		{
			surface_clear(&sw_i, 0);
			(*lb->event_handler_render)(w, lb, &sw_i, ix);
		}
		
		ix++;
		Y += H;
	}

	// clear rest of surface
	H = sw.height - (Y - sw.scroll_Y);
	if (H > 0)
		surface_clear_rect(&sw, X, Y, W, H, '.');

	return 1;
}

void render_item(lb_def *lb, int ix) {
	surface sw;
	surface sw_i;
	coord X,Y,W,H; //TODO: LB width?
	if (ix < 0 || ix >= lb->item_count)
		return;

	if ( lb->event_handler_render == NULL)
		return;

	surface_from_window(&sw, lb->window);

	X = sw.scroll_X;
	W = sw.width;
	Y = ix * lb->item_height;
	H = lb->item_height;

	if (Y < sw.scroll_Y + sw.height && 
		Y + lb->item_height > sw.scroll_Y) {

		if (surface_from_rect(&sw, &sw_i, X, Y, W, H))
		{
			surface_clear(&sw_i, 0);
			(*lb->event_handler_render)(lb->window, lb, &sw_i, ix);
		}
	}
}

void set_selected_index(lb_def *lb, int nexix) {
	int oldix;

	if (nexix >= lb->item_count)
		nexix = lb->item_count - 1;
	if (nexix < 0)
		nexix = -1;

	oldix = lb->selected_index;
	render_item(lb, oldix);
	lb->selected_index = nexix;
	render_item(lb, nexix);

}

bool lb_keypress(win_def *w, void *arg) {
	char c = *(char *)arg;
	lb_def *lb = (lb_def *)w->userdata;
	int nexix;

	switch (c) {
		case KEYCODE_DOWN:
			nexix = lb->selected_index + 1;
			set_selected_index(lb, nexix);
			return 1;
		case KEYCODE_UP:
			nexix = lb->selected_index - 1;
			set_selected_index(lb, nexix);
			return 1;
	}
}

void lb_init(win_def *w, lb_def *lb, lb_render_handler render, int item_count, unsigned char item_height) {
	lb->window = w;
	lb->item_count = item_count;
	lb->item_height = item_height;
	lb->event_handler_render = render;
	lb->selected_index = -1;
	
	w->userdata = lb;
	win_register_event(w, EVENT_RENDER, &lb_render_win);	
	win_register_event(w, EVENT_KEYPRESS, &lb_keypress);	

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

