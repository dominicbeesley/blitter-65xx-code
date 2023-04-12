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

#include "hardware.h"
#include <oslib/os.h>
#include "adv_globals.h"
#include "screenmaths.h"
#include "sprite.h"
#include "mapdef.h"
#include "dma.h"

mapdef_t *map_cur = NULL;
unsigned char *map_ptr = A_TILE_MAP;
unsigned char *map_ptr_offset;
unsigned char map_width;
unsigned char map_height;
unsigned int map_layer_size;
int tile_off_x;
int tile_off_y;
char tilemap[TILE_MAP_SZ];


unsigned char get_tile_at(unsigned char layer, signed char x, signed char y) {
	signed int xx = tile_off_x + x;
	signed int yy = tile_off_y + y;
	
	if (xx < 0 || xx >= map_width)
		return 0;
	if (yy < 0 || yy >= map_height)
		return 0;
	return *(unsigned char *)(map_ptr_offset + (y * map_width) + x + (layer * map_height * map_width));
}


unsigned char getbltcon() {
	return GET_DMA_BYTE(jim_DMAC_BLITCON);
}


// calculate address of front tile sprite #A in addresses A/B
void front_spr_addr(unsigned char tileno)
{
	unsigned int a = ((unsigned int)FRONT_SPR_SZ)*((unsigned int)tileno);
	SET_DMA_WORD(jim_DMAC_ADDR_B+1, a);
	a+= FRONT_SPR_MO;
	SET_DMA_WORD(jim_DMAC_ADDR_A+1, a);
	//Assume all tiles in single bank
	SET_DMA_BYTE(jim_DMAC_ADDR_B, DMA_FRONT_SPR >> 16);
	SET_DMA_BYTE(jim_DMAC_ADDR_A, DMA_FRONT_SPR >> 16);

}

// calculate address of front tile sprite #A in addresses A/B
void coll_spr_addr(unsigned char tileno)
{
	unsigned int a = ((unsigned int)COLL_SPR_SZ)*((unsigned int)tileno);
	SET_DMA_WORD(jim_DMAC_ADDR_B+1, a);
	a+= FRONT_SPR_MO;
	SET_DMA_WORD(jim_DMAC_ADDR_A+1, a);
	//Assume all tiles in single bank
	SET_DMA_BYTE(jim_DMAC_ADDR_B, DMA_COLL_SPR >> 16);
	SET_DMA_BYTE(jim_DMAC_ADDR_A, DMA_COLL_SPR >> 16);

}

//flags & 0x01 to draw "nocollide"
//flags & 0x02 to draw others

static unsigned char nocollide;
static unsigned char *tile_ptr;	//pointer to current "front" tile
static unsigned char *coll_ptr;	//pointer to current "front" tile
static unsigned char j, i;
static unsigned int scr_addr16;
static unsigned char tileno;
static unsigned char coll;

void draw_front_nosave(unsigned char flags) {

	scr_addr16 = XY_to_dma_scr_adr(0,0);

	SET_DMA_BYTE(jim_DMAC_SHIFT, 0);
	SET_DMA_BYTE(jim_DMAC_MASK_FIRST, 0xFF);
	SET_DMA_BYTE(jim_DMAC_MASK_LAST, 0xFF);

	SET_DMA_WORD(jim_DMAC_STRIDE_A, TILE_X_SZ >> 3);
	SET_DMA_WORD(jim_DMAC_STRIDE_B, TILE_X_SZ >> 1);

	tile_ptr = (unsigned char *)(map_ptr_offset + map_layer_size);
	coll_ptr = tile_ptr + map_layer_size;

	j = ROOM_SZ_Y;
	do {
		i = ROOM_SZ_X;
		do {
			tileno = *tile_ptr++;
			coll = *coll_ptr++;
			nocollide = coll & 0x80;
			if (tileno 
				&& 
				(	nocollide && (flags & 0x01)
				||	!nocollide && (flags & 0x02)
				)) {
				front_spr_addr(tileno-1);
				spr_plot((TILE_X_SZ>>1)-1, TILE_Y_SZ-1, BLITCON_EXEC_A + BLITCON_EXEC_B + BLITCON_EXEC_C + BLITCON_EXEC_D , scr_addr16);
			}
			scr_addr16 += TILE_SCR_ADDR_STRIDE_X;
		} while (--i);

		tile_ptr += (map_width-ROOM_SZ_X);
		coll_ptr += (map_width-ROOM_SZ_X);
		scr_addr16 += TILE_SCR_ADDR_STRIDE_Y;

	} while (--j);	
}

void draw_front(unsigned char flags) {
	// specialised sprite plot - no bounds checking, all x are even

	scr_addr16 = XY_to_dma_scr_adr(0,0);

	SET_DMA_BYTE(jim_DMAC_SHIFT, 0);
	SET_DMA_BYTE(jim_DMAC_MASK_FIRST, 0xFF);
	SET_DMA_BYTE(jim_DMAC_MASK_LAST, 0xFF);

	SET_DMA_WORD(jim_DMAC_STRIDE_A, TILE_X_SZ >> 3);
	SET_DMA_WORD(jim_DMAC_STRIDE_B, TILE_X_SZ >> 1);

	tile_ptr = (char *)(map_ptr_offset + map_layer_size);
	coll_ptr = tile_ptr + map_layer_size;

	j = ROOM_SZ_Y;
	do {
		i = ROOM_SZ_X;
		do {
			tileno = *tile_ptr++;
			coll = *coll_ptr++;
			nocollide = coll & 0x80;
			if (tileno 
				&& 
				(	nocollide && (flags & 0x01)
				||	!nocollide && (flags & 0x02)
				)) {

				front_spr_addr(tileno-1);
				spr_save_and_plot((TILE_X_SZ>>1)-1, TILE_Y_SZ-1, BLITCON_EXEC_A + BLITCON_EXEC_B + BLITCON_EXEC_C + BLITCON_EXEC_D + BLITCON_EXEC_E, scr_addr16);
			}
			scr_addr16 += TILE_SCR_ADDR_STRIDE_X;
		} while (--i);

		tile_ptr += (map_width-ROOM_SZ_X);
		coll_ptr += (map_width-ROOM_SZ_X);		
		scr_addr16 += TILE_SCR_ADDR_STRIDE_Y;

	} while (--j);
}


void draw_front_collide(unsigned char x, unsigned char y, unsigned char tileno, unsigned char colourB) {

	scr_addr16 = XY_to_dma_scr_adr(x *TILE_X_SZ, y * TILE_Y_SZ);
	SET_DMA_BYTE(jim_DMAC_SHIFT, 0);
	SET_DMA_BYTE(jim_DMAC_MASK_FIRST, 0xFF);
	SET_DMA_BYTE(jim_DMAC_MASK_LAST, 0xFF);

	SET_DMA_WORD(jim_DMAC_STRIDE_A, TILE_X_SZ >> 3);
	SET_DMA_BYTE(jim_DMAC_DATA_B, colourB);

	coll_spr_addr(tileno-1);
	spr_save_and_plot((TILE_X_SZ>>1)-1, TILE_Y_SZ-1, BLITCON_EXEC_A + BLITCON_EXEC_C + BLITCON_EXEC_D + BLITCON_EXEC_E, scr_addr16);
}


unsigned char colcheck(
	unsigned char charspr_ix, 
	signed char x, 
	signed char y, 
	signed char offsx, 
	signed char offsy) {

	coll = get_tile_at(LAYER_COLL,x,y) & 0x7F;
	if (coll) {


//		unsigned int ch_addr = (DMA_CHARAC_SPR & 0xFFFF) + ((unsigned int)charspr_ix*(unsigned int)CHARAC_SPR_SZ) + CHARAC_SPR_MO; // address of character mask
		unsigned int ch_addr = (DMA_CHARAC_SPR & 0xFFFF) + ((unsigned int)16*(unsigned int)CHARAC_SPR_SZ) + CHARAC_SPR_MO; // address of character mask
		unsigned int coll_addr = (DMA_COLL_SPR & 0xFFFF) + ((unsigned int)COLL_SPR_SZ*((unsigned int)coll-1)) + COLL_SPR_MO;
		unsigned char h = COL_Y_MAX;
		unsigned char bw = COLL_SPR_MASK_BYTES_PER_LINE;
		unsigned char shiftA = 0;
		unsigned char shiftB = 0;
		unsigned char mask_first = 0xFF;
		unsigned char mask_last = 0xFF;

		while (offsy > 0) {

			coll_addr += COLL_SPR_MASK_BYTES_PER_LINE;

			h--;
			if (h == 0)
				return 0;
			offsy--;
		}
//ASSUME: tile and character same height!
		while (offsy < 0) {
			ch_addr += COLL_SPR_MASK_BYTES_PER_LINE;
			h--;
			if (h == 0)
				return 0;
			offsy++;			
		}

		while (offsx > 8) {
			coll_addr++;
			bw--;			
			if (bw == 0)
				return 0;
			offsx-=8;
		}

		while (offsx < -8) {
			ch_addr++;
			bw--;			
			if (bw == 0)
				return 0;
			offsx+=8;
		}

		if (offsx > 0)
		{
			mask_first = 0xFF >> offsx;
			mask_last = 0xFF;
			shiftA = offsx;
		} 
		else if (offsx < 0)
		{			
			mask_first = 0xFF >> -offsx;
			mask_last = 0xFF;
			shiftB = -offsx;
		}

		SET_DMA_BYTE(jim_DMAC_SHIFT, shiftA + (shiftB << 4));
		SET_DMA_BYTE(jim_DMAC_MASK_FIRST, mask_first);
		SET_DMA_BYTE(jim_DMAC_MASK_LAST, mask_last);


		SET_DMA_BYTE(jim_DMAC_ADDR_A, DMA_CHARAC_SPR >> 16);
		SET_DMA_WORD(jim_DMAC_ADDR_A+1, ch_addr);

		SET_DMA_BYTE(jim_DMAC_ADDR_B, DMA_COLL_SPR >> 16);
		SET_DMA_WORD(jim_DMAC_ADDR_B+1, coll_addr);

		SET_DMA_BYTE(jim_DMAC_WIDTH, bw-1);
		SET_DMA_WORD(jim_DMAC_STRIDE_A, COLL_SPR_MASK_BYTES_PER_LINE);
		SET_DMA_WORD(jim_DMAC_STRIDE_B, COLL_SPR_MASK_BYTES_PER_LINE);
		SET_DMA_BYTE(jim_DMAC_HEIGHT, h-1);

		SET_DMA_BYTE(jim_DMAC_FUNCGEN, 0xC0); //A&B
		SET_DMA_BYTE(jim_DMAC_BLITCON, BLITCON_EXEC_A | BLITCON_EXEC_B);
		SET_DMA_BYTE(jim_DMAC_BLITCON, BLITCON_ACT_ACT + BLITCON_ACT_MODE_1BBP + BLITCON_ACT_COLLIDE);

		//check result -- bodge using a function to get round ca65's lack of volatile
		if (getbltcon() & BLITCON_ACT_COLLIDE)
			return 0;

		draw_front_collide(x,y,coll,0xF0);

		return coll;
	} else 
		return 0;
}

//x in map coordinates
//y in map coordinates
unsigned colcheck_at(signed old_x, signed old_y, signed new_x, signed new_y)
{
	//check for collision with tiles
	unsigned char col = 0;
	unsigned char x = new_x / TILE_X_SZ;
	unsigned char y = new_y / TILE_Y_SZ;
	unsigned char xx = new_x % TILE_X_SZ;
	unsigned char yy = new_y % TILE_Y_SZ;

	
	col = colcheck(CHARAC_COL,x,y,xx,yy);
	if (col)
		return col;
	if (xx) {
		col = colcheck(CHARAC_COL,x+1,y,xx-TILE_X_SZ,yy);
		if (col)
			return col;
		if (yy) {
			col = colcheck(CHARAC_COL,x+1,y+1,xx-TILE_X_SZ,yy-TILE_Y_SZ);
			if (col)
				return col;
		}
	}
	if (yy) {
		col = colcheck(CHARAC_COL,x,y+1,xx,yy-TILE_Y_SZ);
		if (col)
			return col;
	}
	return 0;
}


void set_map(mapdef_t *map) {

	map_cur = map;
	map_width = map->width;
	map_height = map->height;
	map_layer_size = map_width * map_height;

	//get map from DMA to tiles buffer
	dma_copy_block(1,DMA_TILE_MAP + (unsigned long)map->binary_offs, 0x000000L + (long)A_TILE_MAP, 3*map_layer_size);

}


void set_offset(int x, int y) {

	if (x >= map_width)
	{
		if (map_cur && map_cur->east)
			set_map(map_cur->east);
		x = 0;
	} else if (x < 0) {
		if (map_cur && map_cur->west)
			set_map(map_cur->west);
		x = map_width - ROOM_SZ_X;
	}


	if (y >= map_height) {
		if (map_cur && map_cur->south)
			set_map(map_cur->south);
		y = 0;
	} else if (y < 0) {
		if (map_cur && map_cur->north)
			set_map(map_cur->north);
		y = map_height - ROOM_SZ_Y;
	}

	tile_off_x = x;
	tile_off_y = y;

	map_ptr_offset = (unsigned char *)((unsigned int)map_ptr + (unsigned int)tile_off_x + (map_width*(unsigned int)tile_off_y));
}

