/*
MIT License

Copyright (c) 2023 Dossytronics
https://github.com/dominicbeesley/blitter-65xx-code

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#include <stdio.h>
#include <oslib/os.h>
#include <oslib/osfile.h>
#include <stdlib.h>

#include "hardware.h"
#include "adv_globals.h"
#include "dma.h"
#include "myos.h"

#include "brk.h"
#include "sprite.h"
#include "screenmaths.h"
#include "text.h"
#include "tile_map.h"

#include "mapdef.h"
#include "all_maps.h"


// 		setdp	0

// 		org	$70				; zero page - basic compat
// zp_dm_ct_x	equ	$70
// zp_dm_ct_y	equ	$71
// zp_spr_save_pt	equ	$72				; points at entry in save area
// zp_spr_save_ram	equ	$74				; points at chip ram containing the save (only ls 2 bytes!)


unsigned int framectr;


#define NUM_CHARS	79

typedef struct {
	signed int x;
	signed char dx;
	signed int y;
	signed char dy; 
	unsigned char off;
} charstuff;

charstuff chars[NUM_CHARS];


void debug(unsigned int x)
{
	*((byte *)0xFE35) = x;
}

void dma_shadow2_scr(void) {
	dma_copy_block(0,DMA_SCR_SHADOW,0xFF3000,0x5000);
}			


void wait_vsync() {
	my_os_byteA(19);
}

#define X_START	18
#define X_MAX	160-16
#define Y_START	28
#define Y_MAX	259


#define CHAR_TILE_DN_IX 0x00
#define CHAR_TILE_RT_IX 0x04
#define CHAR_TILE_UP_IX 0x08
#define CHAR_TILE_LT_IX 0x0C

#define KEY_DN 0x01
#define KEY_RT 0x02
#define KEY_UP 0x04
#define KEY_LT 0x08

unsigned char char_keyspressed;
unsigned char char_facing;
unsigned char joystick_facing;
unsigned char char_mask_tmp;

unsigned char tmp_ix, tmp_iy;

const char keys[] = { 0xE8, 0xC2, 0xC8, 0xE1 };

unsigned char charspr_ix;
signed x, y;

int i;
unsigned char offswap;

int rndctr = 0;
int donumchars = 5;
charstuff *curchar;


unsigned char diroff(signed char x, signed char y) {
	if (x > 0) {
		return 4;
	} else if (x < 0) {
		return 12;
	} else if (y < 0) {
		return 8;
	} else {
		return 0;
	}
}

void randdir(void) {
	int j = rand() % 8;
	switch (j) {
		case 0:
			curchar->dx = 0;
			curchar->dy = -1;
			break;
		case 1:
			curchar->dx = 1;
			curchar->dy = -1;
			break;
		case 2:
			curchar->dx = 1;
			curchar->dy = 0;
			break;
		case 3:
			curchar->dx = 1;
			curchar->dy = 1;
			break;
		case 4:
			curchar->dx = 0;
			curchar->dy = 1;
			break;
		case 5:
			curchar->dx = -1;
			curchar->dy = 1;
			break;
		case 6:
			curchar->dx = -1;
			curchar->dy = 0;
			break;
		default:
			curchar->dx = -1;
			curchar->dy = -1;
			break;
	}
	curchar->off = diroff(curchar->dx, curchar->dy);
}


void move(void) {

//
// offswap = 0
//
	asm("		ldy	#0");
	asm("		sty	_offswap");

//
// x = curchar->x;
//
	asm("		lda     _curchar+1");
	asm("		sta     ptr1+1");
	asm("		lda     _curchar");
	asm("		sta     ptr1");

	asm("		iny");
	asm("		lda	(ptr1),y");
	asm("		tax");
	asm("		dey");
	asm("		lda	(ptr1),y");

	asm("		sta     _x");
	asm("		stx     _x+1");
//
// x += curchar->dx;
//
	asm("		ldy     #$02");
	asm("		lda	(ptr1),y");
	asm("		ldx     #$00");
	asm("		cmp     #$80");
	asm("		bcc     x1");
	asm("		dex");
	asm("		clc");
	asm("x1:");
	asm("		adc     _x");
	asm("		sta     _x");
	asm("		txa");
	asm("		adc     _x+1");
	asm("		sta     _x+1");

// 
// y = curchar->y;
// 
	asm("		iny");
	asm("		iny");
	asm("		lda	(ptr1),y");
	asm("		tax");
	asm("		dey");
	asm("		lda	(ptr1),y");
	asm("		sta     _y");
	asm("		stx     _y+1");
//
// y += curchar->dy;
//
	asm("		ldy     #$05");
	asm("		lda	(ptr1),y");
	asm("		ldx     #$00");
	asm("		cmp     #$80");
	asm("		bcc     L0137");
	asm("		dex");
	asm("		clc");
	asm("L0137:	adc     _y");
	asm("		sta     _y");
	asm("		txa");
	asm("		adc     _y+1");
	asm("		sta     _y+1");


	if (x < -20)
	{
		x = -20;
		curchar->dx = -curchar->dx;
		offswap = 1;
	} else if (x > 160) {
		x = 160;
		curchar->dx = -curchar->dx;
		offswap = 1;
	}


	if (y < -20)
	{
		y = -20;
		curchar->dy = -curchar->dy;
		offswap = 1;
	} else if (y > 200) {
		y = 200;
		curchar->dy = -curchar->dy;
		offswap = 1;
	}

	if (rndctr++ >= 57) {
		offswap = 1;
		randdir();
		rndctr = 0;
	}

	if (offswap)
		curchar->off = diroff(curchar->dx, curchar->dy);

	curchar->x = x;
	curchar->y = y;

}


unsigned char getkey(void) {
	asm("lda	#$81");
	asm("ldx	#0");
	asm("ldy	#0");
	asm("jsr	$FFF4");
	asm("txa");
	asm("bcc	s1");
	asm("lda	#0");
	asm("s1:");
}


void main(void) {

	unsigned room_exit = 0;

	//naughty - set jim devno but don't save old
	*((unsigned char *)0xEE) = JIM_DEVNO_BLITTER;
	*((unsigned char *)fred_JIM_DEVNO) = JIM_DEVNO_BLITTER;
	*((unsigned char *)fred_JIM_PAGE_LO) = jim_page_DMAC & 0xFF;
	*((unsigned char *)fred_JIM_PAGE_HI) = jim_page_DMAC >> 8;

	curchar = chars;
	for (i = 0; i < NUM_CHARS; i++)
	{
		curchar->x = rand() % 128;
		curchar->y = rand() % 200;
		randdir();
		curchar++;
	}

	dma_clear(DMA_SCR_SHADOW, 0, 0x5000-1);

	set_map(&home_def);
	set_offset(0,0);


	dma_copy_block(1, DMA_TILE_MAP, 0x000000L + (long)A_TILE_MAP, TILE_MAP_SZ);

	spr_init();
	// draw background
	draw_map(map_ptr_offset);
	draw_front_nosave(0x03);


	// clear restore
	spr_restore_init();

	while (1) {
		wait_vsync();

		dma_shadow2_scr();

		curchar = chars;
		for (i = 0; i < donumchars; i++)
		{
			move();
			curchar++;
		}

		charspr_ix++;
		charspr_ix = charspr_ix & 0x0F;

		setcursor(0x4000);
		plot_hex16(framectr);
		plot_hex8(donumchars);

		while (dma_act()) {};

		spr_restore();

		spr_save_start();

		charac_spr_plot_start();
		curchar = chars;
		for (i = 0; i < donumchars; i++)
		{
			charac_spr_plot(curchar->x, curchar->y, curchar->off + (charspr_ix >> 2));
			curchar++;
		}
		
		switch (getkey()) {
			case ' ':
				framectr = 0;
				break;
			case ',':
				donumchars--;
				if (donumchars < 1)
					donumchars = 1;
				break;
			case '.':
				donumchars++;
				if (donumchars >= NUM_CHARS)
					donumchars = NUM_CHARS;
				break;
		}

		framectr++;
		if (framectr & 0x01)
			debug(255);
		else
			debug(0);
	}
}



