#include "window.h"
#include "surface.h"
#include "listbox.h"
#include "hex.h"
#include "keyboard.h"
#include "debug.h"
#include "event.h"

bool lb_render_item_int(lb_def *lb, surface *sw, int ix, rectangle *drawrect) {
	lb_item_render_args args;
	surface sw_i;

	if (drawrect->topleft.Y < sw->scroll.Y + sw->screenrect.size.H && 
		ix < lb->item_count && ix >= 0) {

		if (surface_from_rect(sw, &sw_i, drawrect))
		{
			args.surface = &sw_i;
			args.index = ix;
			(*lb->event_handler_render)(lb, &args);
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

bool lb_render_win(void *sender, void *arg) {	
	win_def *w;
	surface sw;
	lb_def *lb;
	int ix;
	bool ret;
	rectangle drawrect;

	w = (win_def *)sender;
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
	coord Y, WH, MY;
	point np;
	int d = 0;

	np.X = 0;

	if (nexix >= lb->item_count)
		nexix = lb->item_count - 1;
	if (nexix < 0)
		nexix = -1;

	oldix = lb->selected_index;
	if (nexix != oldix) {
		lb->selected_index = nexix;

		WH = lb->window->screenrect.size.H;
		d = 2;
		while (d * 2 * lb->item_height > WH && d > 0)
			d --;

		// check in bounds and if no need to scroll update individual items
		Y = (nexix - d) * lb->item_height - lb->window->scroll.Y;

		if (Y < 0) {
			np.Y = (nexix - 2) * lb->item_height;
			if (np.Y < 0)
				np.Y = 0;
		} 
		Y = (nexix + d) * lb->item_height - lb->window->scroll.Y;
		if (Y > WH) {
			
			np.Y = (lb->selected_index + 2) * lb->item_height - WH;

			// calc max Y scroll
			MY = lb->item_height * lb->item_count - WH;
			if (np.Y > MY)
				np.Y = MY;
		}

		if (np.Y != lb->window->scroll.Y) {
			win_scroll(lb->window, &np);
		} else {
			render_item(lb, oldix);
			render_item(lb, nexix);
		}
	}

}

bool lb_keypress(void *sender, void *arg) {
	char c = *(char *)arg;
	lb_def *lb;
	int nexix;
	win_def *w;

	w = (win_def *)sender;
	lb = (lb_def *)w->userdata;

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

	return 0;
}

void lb_init(win_def *w, lb_def *lb, event_handler render_handler, int item_count, unsigned char item_height) {
	lb->window = w;
	lb->item_count = item_count;
	lb->item_height = item_height;
	lb->event_handler_render = render_handler;
	lb->selected_index = -1;
	
	w->userdata = lb;
	win_register_event(w, WIN_EVENT_RENDER, &lb_render_win);	
	win_register_event(w, WIN_EVENT_KEYPRESS, &lb_keypress);	

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

