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

#include "hardware.h"
#include "adv_globals.h"
#include "dma.h"
#include "myos.h"
#include "tile_map.h"

#include "brk.h"
#include "adval.h"
#include "sprite.h"
#include "screenmaths.h"

#include "mapdef.h"
#include "all_maps.h"



// 		setdp	0

// 		org	$70				; zero page - basic compat
// zp_dm_ct_x	equ	$70
// zp_dm_ct_y	equ	$71
// zp_spr_save_pt	equ	$72				; points at entry in save area
// zp_spr_save_ram	equ	$74				; points at chip ram containing the save (only ls 2 bytes!)


extern int char_x;
extern int char_y;

int char_new_y, char_new_x;
unsigned char charspr_ix, charspr_offs;
unsigned int framectr;


void debug(unsigned int x)
{
	// FE35 now used for ROM mapping!
	//*((byte *)0xFE35) = x;
}

void dma_shadow2_scr(void) {
	dma_copy_block(1,DMA_SCR_SHADOW,0xFF3000,0x5000);
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
#define KEY_JOY 0x10

unsigned char char_keyspressed;
unsigned char char_facing;
char joy = 0;						//disabled
unsigned char joystick_facing;
unsigned char char_mask_tmp;

unsigned char tmp_ix, tmp_iy;

const char keys[] = { 
	0xE8, // ?
	0xC2, // X
	0xC8, // *
	0xE1, // Z 
	0xC5  // J
};

void char_init() {
	charspr_ix = 0;
	charspr_offs = 0;
	char_facing = 0;
	char_x = X_START;
	char_y = Y_START;
}



#define SPEED_X 2
#define SPEED_Y 3

#define REDUCE_DX {if (dx>1) dx=1; else if (dx<-1) dx=-1; else dx = 0;}
#define REDUCE_DY {if (dy>1) dy=1; else if (dy<-1) dy=-1; else dx = 0;}

unsigned char mag(signed char x) {
	if (x > 0)
		return x;
	else
		return -x;
}

void face(unsigned char direction)
{
	char_facing = 1;
	char_mask_tmp = 1;
	charspr_offs = 0;
	tmp_iy = 0;
	while (char_mask_tmp & 0x0F) {
		if (direction & char_mask_tmp)
		{
			char_facing = char_mask_tmp;
			charspr_offs = tmp_iy;
			return;
		}
		tmp_iy+=4;
		char_mask_tmp = char_mask_tmp << 1;
	}
}



void char_move(void) {

	unsigned char ret = 0;
	signed char dx = 0;
	signed char dy = 0;

	/* scan keys */
	char_keyspressed = 0;
	char_mask_tmp = 1;
	for (tmp_ix = 0; tmp_ix < sizeof(keys) / sizeof(keys[0]); tmp_ix++)
	{
		if (my_os_byteAXYretX(0x79, keys[tmp_ix], 0) & 0x80) {
			char_keyspressed |= char_mask_tmp;
		}

		char_mask_tmp = char_mask_tmp << 1;
		tmp_iy += 4;
	}

	// work out which way we are facing and if still going that way stay facing that way
	// facing is always _one_ of up,down,left,rt
	if (char_keyspressed) {
		if (!(char_keyspressed & char_facing)) {
			face(char_keyspressed);
		}
	}

	//get rid of conflicting keys
	if (((KEY_LT + KEY_RT) & char_keyspressed) == (KEY_LT + KEY_RT))
	{
		char_keyspressed &= (~(KEY_LT + KEY_RT)) | char_facing;
	}
	if (((KEY_UP + KEY_DN) & char_keyspressed) == (KEY_UP + KEY_DN))
	{
		char_keyspressed &= (~(KEY_UP + KEY_DN)) | char_facing;
	}

	
	if (KEY_JOY & char_keyspressed) {
		if (!(joy & 2)) {
			joy ^= 1;
		}
		joy |= 2;
	} else {
		joy = joy & ~2;
	}


	if (joy) {
		/* joystick control */
		dx = adval8(1);
		if (dx > 0)
			dx--;
		else if (dx < 0)
			dx++;
		dy = adval8(2);
		if (dy > 0)
			dy--;
		else if (dy < 0)
			dy++;
		
		if (dx != 0 || dy != 0)
		{
			joystick_facing = 0;
			if (mag(dx) > mag(dy)) {
				if (dx > 0)
					joystick_facing |= KEY_RT;
				else if (dx < 0)
					joystick_facing |= KEY_LT;
			}
			else {
				if (dy > 0)
					joystick_facing |= KEY_DN;
				else if (dy < 0)
					joystick_facing |= KEY_UP;
			}
			if (!joystick_facing)
				joystick_facing = 1;
			face(joystick_facing);
		}
	}
	


	if (char_keyspressed & KEY_RT)
		dx = SPEED_X;
	else if (char_keyspressed & KEY_LT)
		dx = -SPEED_X;

	if (char_keyspressed & KEY_DN)
		dy = SPEED_Y;
	else if (char_keyspressed & KEY_UP)
		dy = -SPEED_Y;

	if (dx || dy) {
		char_new_y = char_y + dy;
		char_new_x = char_x + dx;

		if (!colcheck_at(char_x, char_y, char_new_x, char_new_y))
			goto donemove;


		REDUCE_DX
		REDUCE_DY

		if (dx & !dy) {
			char_new_x = char_x + dx;
			char_new_y = char_y + dx;
			if (!colcheck_at(char_x, char_y, char_new_x, char_new_y))
				goto donemove;
			char_new_y = char_y - dx;
			if (!colcheck_at(char_x, char_y, char_new_x, char_new_y))
				goto donemove;			
		} else if (dy & !dx) {
			char_new_y = char_y + dy;
			char_new_x = char_x + dy;
			if (!colcheck_at(char_x, char_y, char_new_x, char_new_y))
				goto donemove;
			char_new_x = char_x - dy;
			if (!colcheck_at(char_x, char_y, char_new_x, char_new_y))
				goto donemove;			
		}


		if (dx && dy)
		{
			//try slower in same direction
			char_new_x = char_x + dx;
			char_new_y = char_y + dy;
			if (!colcheck_at(char_x, char_y, char_new_x, char_new_y))
				goto donemove;

			if (char_facing & (KEY_UP | KEY_DN))
			{
				char_new_x = char_x;
				char_new_y = char_y + dy;
				if (!colcheck_at(char_x, char_y, char_new_x, char_new_y))
					goto donemove;

				char_new_x = char_x + dx;
				char_new_y = char_y;
				if (!colcheck_at(char_x, char_y, char_new_x, char_new_y))
					goto donemove;
			}
			else
			{
				char_new_x = char_x + dx;
				char_new_y = char_y;
				if (!colcheck_at(char_x, char_y, char_new_x, char_new_y))
					goto donemove;
				
				char_new_x = char_x;
				char_new_y = char_y + dy;
				if (!colcheck_at(char_x, char_y, char_new_x, char_new_y))
					goto donemove;
			}



		} else if (dx || dy) {
			char_new_x = char_x + dx;
			char_new_y = char_y + dy;
			if (!colcheck_at(char_x, char_y, char_new_x, char_new_y))
				goto donemove;
		}


		charspr_ix=0;
		goto nomove;
donemove:

		if (room_exit)
			return;

		char_x = char_new_x;
		char_y = char_new_y;	

		charspr_ix++;
		charspr_ix&=0xF;

nomove:
		if (char_x > ROOM_SZ_X*TILE_X_SZ)
		{
			char_x -= ROOM_SZ_X * TILE_X_SZ;
			set_offset(tile_off_x + ROOM_SZ_X, tile_off_y);
			room_exit = 1;
			return;
		}
		else if (char_x < -TILE_X_SZ)
		{
			char_x += ROOM_SZ_X * TILE_X_SZ;
			set_offset(tile_off_x - ROOM_SZ_X, tile_off_y);
			room_exit = 1;
			return;
		}
		else if (char_y > ROOM_SZ_Y*TILE_Y_SZ)
		{
			char_y -= ROOM_SZ_Y * TILE_Y_SZ;
			set_offset(tile_off_x, tile_off_y + ROOM_SZ_Y);
			room_exit = 1;
			return;
		}
		else if (char_y < -TILE_Y_SZ)
		{
			char_y += ROOM_SZ_Y * TILE_Y_SZ;
			set_offset(tile_off_x, tile_off_y - ROOM_SZ_Y);
			room_exit = 1;
			return;
		}
	} else {
		charspr_ix=0;
	}

}


void main(void) {

	room_exit = 0;

	//naughty - set jim devno but don't save old
	*((unsigned char *)0xEE) = JIM_DEVNO_BLITTER;
	*((unsigned char *)fred_JIM_DEVNO) = JIM_DEVNO_BLITTER;
	*((unsigned char *)fred_JIM_PAGE_LO) = jim_page_DMAC & 0xFF;
	*((unsigned char *)fred_JIM_PAGE_HI) = jim_page_DMAC >> 8;


	set_map(&home_def);
	set_offset(0,0);


	dma_clear(DMA_SCR_SHADOW, 0, 0x5000-1);

	spr_init();

	// draw background
	draw_map(map_ptr_offset);
	draw_front_nosave(0x02);

	char_init();

	// clear restore
	spr_restore_init();

	while (1) {
		wait_vsync();

		dma_shadow2_scr();

		spr_restore();

		if (room_exit)
		{
			// re draw background
			draw_map(map_ptr_offset);
			draw_front_nosave(0x02);

			room_exit = 0;
		}

		spr_save_start();


		char_move();

		charac_spr_plot_start();
		charac_spr_plot(char_x, char_y, 16);
		charac_spr_plot(char_x, char_y, charspr_offs + (charspr_ix >> 2));

		draw_front(0x01);


		framectr++;
	}
}



