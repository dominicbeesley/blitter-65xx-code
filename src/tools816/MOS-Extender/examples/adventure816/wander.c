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
#include <stdlib.h>
#include <stdint.h>

#include "oslib-ext.h"

#include "hardware.h"
#include "adv_globals.h"
#include "dma.h"

#include "sprite.h"
#include "screenmaths.h"
#include "text.h"
#include "tile_map.h"

#include "mapdef.h"
#include "all_maps.h"



///TODO: move this to a library
size_t __write(int h, const char *p, size_t l) {
        size_t i = 0;
        while (i < l) {
                char c = *p++;
                if (c == '\n')
                        xos_newl();
                else
                        xos_wrch(c);
                i++;
        }
        return i;
}


uint16_t framectr;


#define NUM_CHARS	79

typedef struct {
	int16_t x;
	int8_t dx;
	int16_t y;
	int8_t dy; 
	uint8_t off;
} charstuff;

charstuff chars[NUM_CHARS];


void debug(unsigned int x)
{
	// FE35 now used for ROM mapping!
	//*((byte *)0xFE35) = x;
}

void dma_shadow2_scr(void) {
	dma_copy_block(0,DMA_SCR_SHADOW,(void *)0xFF3000,0x5000);
}			


void wait_vsync() {
	xos_byte(19, 0, 0);
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

uint8_t char_keyspressed;
uint8_t char_facing;
uint8_t joystick_facing;
uint8_t char_mask_tmp;

uint8_t tmp_ix, tmp_iy;

uint8_t keys[] = { 0xE8, 0xC2, 0xC8, 0xE1 };

uint8_t charspr_ix;
int16_t x, y;

int16_t i;
uint8_t offswap;

uint16_t rndctr = 0;
uint16_t donumchars = 5;
charstuff *curchar;


unsigned char diroff(int8_t x, int8_t y) {
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

	offswap = 0;
	x = curchar->x;
	x += curchar->dx;
	y = curchar->y;
	y += curchar->dy;

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


uint8_t getkey(void) {
	uint8_t X, Y;
	X=0;
	Y=0;
	xos_byte_ret(0x81, &X, &Y);
	return X;
}

uint8_t prev_cfs_to;

int main(void) {

	setvbuf(stdout, NULL, _IONBF, 0);

	xos_wrch(22);
	xos_wrch(2);

	uint16_t room_exit = 0;

	curchar = chars;
	for (i = 0; i < NUM_CHARS; i++)
	{
		curchar->x = rand() % 128;
		curchar->y = rand() % 200;
		randdir();
		curchar++;
	}

	dma_clear(DMA_SCR_SHADOW, 0, 0x5000-1);

	dma_copy_block(1, DMA_TILE_MAP, tilemap, TILE_MAP_SZ);

	set_map(&home_def);
	set_offset(0,0);


	spr_init();
	// draw background
	draw_map(map_ptr_offset);
	//draw_front_nosave(0x03);


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
		plot_hex8(prev_cfs_to - *((volatile uint8_t *)0x0000240));
		prev_cfs_to = *((volatile uint8_t *)0x0000240);

		while (dma_act()) {};

		spr_restore();

		spr_save_start();

		charac_spr_plot_start();
		curchar = chars;
		for (i = 0; i < donumchars; i++)
		{
			charac_spr_plot(curchar->x, curchar->y, curchar->off + ((i + charspr_ix >> 2) & 0x3));
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

	return 0;
}



