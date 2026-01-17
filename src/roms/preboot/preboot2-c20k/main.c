#include <string.h>

#include "screen.h"
#include "window.h"
#include "surface.h"
#include "listbox.h"
#include "hex.h"
#include "keyboard.h"

extern char main_head[];

const char *w_main_data = "HELLO WORLD";

win_def w_main;
win_def w_head;
win_def w_status;
lb_def l_list;

char buf[100];


screen_bool render_main(win_def *w) {
	screen_coord Y;
	surface s;

	surface_from_window(&s, w);

	for (Y = 0; Y < 23; Y ++) {
		*hex_str(buf, 6, Y) = '\0';
		surface_render_str(&s, 0, Y, buf);
	}

	return 1;
}

void spi_read_buf(void *p, unsigned long spi_addr, unsigned count) {

	__asm__(" jsr spi_reset");
	__asm__(" ldy #%o", count);
	__asm__(" lda (sp), Y");
	__asm__(" sta zp_spi_len");
	__asm__(" iny");
	__asm__(" lda (sp), Y");
	__asm__(" sta zp_spi_len+1");
	__asm__(" iny");
	__asm__(" lda (sp), Y");
	__asm__(" sta zp_spi_addr");
	__asm__(" iny");
	__asm__(" lda (sp), Y");
	__asm__(" sta zp_spi_addr+1");
	__asm__(" iny");
	__asm__(" lda (sp), Y");
	__asm__(" sta zp_spi_addr+2");
	__asm__(" iny");
	__asm__(" iny");				// 32 bit pointer!
	__asm__(" lda (sp), Y");
	__asm__(" sta zp_spi_memptr");
	__asm__(" iny");
	__asm__(" lda (sp), Y");
	__asm__(" sta zp_spi_memptr+1");
	__asm__(" jsr spi_read_buf");

}

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

	if (l->selected_index == ix) {
		*p++ = 0x86;
		*p++ = 0x9D;
		*p++ = 0x83;
	} else {
		*p++ = ' ';
		*p++ = ' ';
		*p++ = ' ';
	}

	addr = romset_find(ix);
	if (addr) {
		strncpy(p, romset_g.title, 32);
		p[32] = 0;
	} else {
		*p++ = '?';
		*p++ = 0;
	}

	surface_render_str(s, 0, 0, buf);

	surface_render_str(s, 0, 1, "~-~-~-~-~-~-~-~-~-~-~-");
}

void wait() {
	__asm__("ldx #0");
	__asm__("ldy #0");
	__asm__("@lp: dex");
	__asm__("bne @lp");
	__asm__("dey");
	__asm__("bne @lp");
}

int main(void) {

	int i;

	screen_init();


	memcpy((char *)0x7C00, main_head, 8*40);

	screen_cursor_at(13,21);
	screen_cursor(1);

	win_init(&w_main, WINDOW_OPT_NOCLEAR, 0, 8, 40, 16, NULL);
	//win_register_event(&w_main, EVENT_RENDER, &render_main);
	win_open(&w_main, 1);

	win_init(&w_head, 0, 3, 4, 35, 3, NULL);
	win_open(&w_head, 0);

	win_init(&w_status, 0, 0, 24, 40, 1, NULL);
	win_open(&w_status, 1);
	
	lb_init(&w_main, &l_list, &l_list_render, 5, 2);
	wait();
	wait();
	wait();
	wait();
	wait();
	wait();
	wait();
	wait();
	wait();
	wait();
	wait();
	wait();
	wait();
	wait();
	wait();
	l_list.selected_index = 3;
	win_refresh(&w_main);

	for (i = 0; i < 10; i++) {
		w_main.scroll_Y = i;	
		win_refresh(&w_main);
	}

	do { 
		if (keyboard_scan(1))
			*((char *)0x7C00) ='1';
		else
			*((char *)0x7C00) ='0';

		if (keyboard_scan(0))
			*((char *)0x7C01) ='1';
		else
			*((char *)0x7C01) ='0';
	} while (1);

	return 0;

}