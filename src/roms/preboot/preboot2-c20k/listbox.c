#include "window.h"
#include "surface.h"
#include "listbox.h"
#include "hex.h"
#include "keyboard.h"
#include "debug.h"

bool lb_render_item_int(lb_def *lb, surface *sw, int ix, rectangle *drawrect) {
	surface sw_i;

	if (drawrect->topleft.Y < sw->scroll.Y + sw->screenrect.size.H && 
		ix < lb->item_count && ix >= 0) {

		if (surface_from_rect(sw, &sw_i, drawrect))
		{
			surface_clear(&sw_i, 0);
			(*lb->event_handler_render)(lb->window, lb, &sw_i, ix);
		}
		return 1;
	} else 
		return 0;
}

void lb_render_item_surface(lb_def *lb, surface *sw, int ix, rectangle *drawrect) {
	surface_from_window(sw, lb->window);

	drawrect->topleft.X = sw->scroll.X;
	drawrect->topleft.Y = ix * lb->item_height;
	drawrect->size.W = sw->screenrect.size.W;
	drawrect->size.H = lb->item_height;

}

bool lb_render_win(win_def *w, void *arg) {	
	surface sw;
	lb_def *lb;
	int ix;
	bool ret;
	rectangle drawrect;

	ret = 0;
	lb = (lb_def *)w->userdata;

	if ( lb->event_handler_render == NULL)
		return 0;

	if (w->scroll.Y > 0)
		ix = w->scroll.Y /  lb->item_height;
	else
		ix = 0;

	lb_render_item_surface(lb, &sw, ix, &drawrect);

	while (lb_render_item_int(lb, &sw, ix, &drawrect)) {
		ret = 1;
		
		ix++;
		drawrect.topleft.Y += drawrect.size.H;
	}

	// clear rest of surface
	drawrect.size.H = sw.screenrect.size.H - (drawrect.topleft.Y - sw.scroll.Y);
	if (drawrect.size.H > 0)
		surface_clear_rect(&sw, &drawrect, 0);

	return ret;
}

bool render_item(lb_def *lb, int ix) {
	surface sw;
	rectangle drawrect; //TODO: LB width?

	if ( lb->event_handler_render == NULL)
		return 0;

	lb_render_item_surface(lb, &sw, ix, &drawrect);

	return lb_render_item_int(lb, &sw, ix, &drawrect);
}

void set_selected_index(lb_def *lb, int nexix) {
	int oldix;

	if (nexix >= lb->item_count)
		nexix = lb->item_count - 1;
	if (nexix < 0)
		nexix = -1;

	oldix = lb->selected_index;
	if (nexix != oldix) {
		lb->selected_index = nexix;
		render_item(lb, oldix);
		render_item(lb, nexix);
	}

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

