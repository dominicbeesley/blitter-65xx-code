#include <string.h>
#include "types.h"
#include "screen.h"
#include "window.h"
#include "surface.h"
#include "listbox.h"
#include "hex.h"
#include "keyboard.h"
#include "hw.h"
#include "debug.h"
#include "util.h"
#include "spi.h"
#include "buffer.h"
#include "coords.h"

extern char main_head[];

const char *w_main_data = "HELLO WORLD";

win_def w_main;
win_def w_head;
win_def w_status;
lb_def l_list;

char buf[100];


bool render_status(win_def *w, void *arg) {
	surface s;

	surface_from_window(&s, w);

	sprintf(buf, "TIME: %d", (long)get_time());
	surface_render_str(&s, &point0, buf);

	return 1;
}

#pragma bss-name (push,"ZEROPAGE")
extern unsigned int zp_spi_len;
extern void * zp_spi_memptr;
extern unsigned long zp_spi_addr;
#pragma bss-name (pop)

typedef struct romset_struct_romset romset;

struct romset_struct_romset {
	unsigned char len;
	unsigned char cpu;
	char title[32];	
};

#define ROMSET_BASE 0x720000
#define ROMSET_SIZE 64
#define ROMDESCR_SIZE 64
#define ROM_SIZE 16384

romset romset_g;

unsigned long romset_find(int ix) {
	unsigned long addr;
	addr = ROMSET_BASE;
	ix++;
	while (ix) {
		spi_read_buf(&romset_g, addr, sizeof(romset));
		if (!romset_g.len)
			return 0;
		ix--;
		if (ix)
			addr += 
				(unsigned long)ROMSET_SIZE 
				+ (unsigned long)((ROMDESCR_SIZE + ROM_SIZE) 
					* (unsigned long)romset_g.len);
	}
	return addr;
}

void l_list_render(win_def *w, lb_def *l, surface *s, int ix) {
	char *p = buf;
	unsigned long addr;
	point point01 = {0, 1};

	if (l->selected_index == ix) {
		*p++ = 0x86;
		*p++ = 0x9D;
		*p++ = 0x83;
	} else {
		*p++ = '.';
		*p++ = '.';
		*p++ = '.';
	}

	addr = romset_find(ix);
	if (addr) {
		strncpy(p, romset_g.title, 32);
		p[32] = 0;
	} else {
		*p++ = '?';
		*p++ = 0;
	}

	surface_render_str(s, &point0, buf);

	surface_render_str(s, &point01, "~-~-~-~-~-~-~-~-~-~-~-");
}

void wait() {
	__asm__("ldx #0");
	__asm__("ldy #0");
	__asm__("@lp: dex");
	__asm__("bne @lp");
	__asm__("dey");
	__asm__("bne @lp");
}

extern unsigned char testval;
surface surf_test;
rectangle r_head = {{3, 4}, {25, 3}};
rectangle r_status = {{0, 24}, {40, 1}};
rectangle r_main = {{0, 8}, {40, 16}};

int main(void) {

	char *p;
	int i;
	char c;

	debug_printf("HELLO\n");

	screen_init();
	hw_init();
	keyb_init();

	debug_printf("HELLO2\n");

	memcpy((char *)0x7C00, main_head, 8*40);

	screen_cursor_at(&point0);
	screen_cursor(1);

//TODO: why have to cast here function arguments should be copied so wtf?
//	win_init(&w_head, 0, &r_head, NULL);
//	win_open(&w_head, 0);

	win_init(&w_status, 0, &r_status, NULL);
	win_register_event(&w_status, EVENT_RENDER, &render_status);
	win_open(&w_status, 1);



//	win_init(&w_main, WINDOW_OPT_NOCLEAR, &r_main, NULL);
	//win_register_event(&w_main, EVENT_RENDER, &render_main);
//	win_open(&w_main, 1);
	
debug_printf("HERE1\n");

//	lb_init(&w_main, &l_list, &l_list_render, 5, 2);
//	wait();
//	wait();
//	wait();
//	wait();
//	wait();
//	wait();
//	wait();
//	wait();
//	wait();
//	wait();
//	wait();
//	wait();
//	wait();
//	wait();
//	wait();
//	l_list.selected_index = 3;
//	win_refresh(&w_main);

	do { 

		if (buffer_get(BUFFER_KEYBOARD, &c) >= 0) {
			win_event_dispatch(EVENT_KEYPRESS, &c);
		}

		//win_refresh(&w_main);
		win_refresh(&w_status);

	} while (1);

	return 0;

}