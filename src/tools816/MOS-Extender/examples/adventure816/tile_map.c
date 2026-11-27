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

#include <stddef.h>

#include "hardware816.h"
#include "adv_globals.h"
#include "screenmaths.h"
#include "sprite.h"
#include "mapdef.h"
#include "dma.h"

//---------------------- register read/write declarations
DECL_RD8(RD8_CS_BLIT_BLITCON, CS_BLIT_BLITCON)
DECL_WR16(WR16_CS_BLIT_ADDR_A, CS_BLIT_ADDR_A)
DECL_WR16(WR16_CS_BLIT_ADDR_B, CS_BLIT_ADDR_B)
DECL_WR16(WR16_CS_BLIT_STRIDE_A, CS_BLIT_STRIDE_A)
DECL_WR16(WR16_CS_BLIT_STRIDE_B, CS_BLIT_STRIDE_B)
DECL_WR8(WR8_CS_BLIT_ADDR_A_BANK, CS_BLIT_ADDR_A+2)
DECL_WR8(WR8_CS_BLIT_ADDR_B_BANK, CS_BLIT_ADDR_B+2)
DECL_WR8(WR8_CS_BLIT_BLITCON, CS_BLIT_BLITCON)
DECL_WR8(WR8_CS_BLIT_DATA_B, CS_BLIT_DATA_B)
DECL_WR8(WR8_CS_BLIT_FUNCGEN, CS_BLIT_FUNCGEN)
DECL_WR8(WR8_CS_BLIT_HEIGHT, CS_BLIT_HEIGHT)
DECL_WR8(WR8_CS_BLIT_MASK_FIRST, CS_BLIT_MASK_FIRST)
DECL_WR8(WR8_CS_BLIT_MASK_LAST, CS_BLIT_MASK_LAST)
DECL_WR8(WR8_CS_BLIT_SHIFT_A, CS_BLIT_SHIFT_A)
DECL_WR8(WR8_CS_BLIT_SHIFT_B, CS_BLIT_SHIFT_B)
DECL_WR8(WR8_CS_BLIT_WIDTH, CS_BLIT_WIDTH)
//----------------------

mapdef_t *map_cur = NULL;
uint8_t *map_ptr = (uint8_t *)tilemap;
uint8_t *map_ptr_offset;
uint8_t map_width;
uint8_t map_height;
uint16_t map_layer_size;
int16_t tile_off_x;
int16_t tile_off_y;
uint8_t tilemap[TILE_MAP_SZ];

BOOL room_exit = FALSE;

int16_t char_y, char_x;


void set_map(mapdef_t *map);
void set_offset(int16_t x, int16_t y);

uint8_t get_tile_at(uint8_t layer, int8_t x, int8_t y) {
	int16_t xx = tile_off_x + x;
	int16_t yy = tile_off_y + y;
	
	if (xx < 0 || xx >= map_width)
		return 0;
	if (yy < 0 || yy >= map_height)
		return 0;
	return *(uint8_t *)(map_ptr_offset + (y * map_width) + x + (layer * map_height * map_width));
}


uint8_t getbltcon() {
	return RD8_CS_BLIT_BLITCON();
}


// calculate address of front tile sprite #A in addresses A/B
void front_spr_addr(uint8_t tileno)
{
	uint16_t a;

	WR8_CS_BLIT_ADDR_B_BANK(((uint32_t)DMA_FRONT_SPR) >> 16);
	WR8_CS_BLIT_ADDR_A_BANK(((uint32_t)DMA_FRONT_SPR) >> 16);

	a = ((uint16_t)FRONT_SPR_SZ)*((uint16_t)tileno);
	WR16_CS_BLIT_ADDR_B(a);
	a+= FRONT_SPR_MO; 
	WR16_CS_BLIT_ADDR_A(a);
	//Assume all tiles in single bank

}

// calculate address of front tile sprite #A in addresses A/B
void coll_spr_addr(uint8_t tileno)
{
	uint16_t a = ((uint16_t)COLL_SPR_SZ)*((uint16_t)tileno);
	WR16_CS_BLIT_ADDR_B(a);
	a+= FRONT_SPR_MO;
	WR16_CS_BLIT_ADDR_A(a);
	//Assume all tiles in single bank
	WR8_CS_BLIT_ADDR_B_BANK(((uint32_t)DMA_COLL_SPR) >> 16);
	WR8_CS_BLIT_ADDR_A_BANK(((uint32_t)DMA_COLL_SPR) >> 16);

}

//flags & 0x01 to draw "nocollide"
//flags & 0x02 to draw others

static uint8_t nocollide;
static uint8_t *tile_ptr;	//pointer to current "front" tile
static uint8_t *coll_ptr;	//pointer to current "front" tile
static uint8_t j, i;
static uint16_t scr_addr16;
static uint8_t tileno;
static uint8_t coll;

void draw_front_nosave(uint8_t flags) {

	scr_addr16 = XY_to_dma_scr_adr16(0,0);

	WR8_CS_BLIT_SHIFT_A(0);
	WR8_CS_BLIT_MASK_FIRST(0xFF);
	WR8_CS_BLIT_MASK_LAST(0xFF);

	WR16_CS_BLIT_STRIDE_A(TILE_X_SZ >> 3);
	WR16_CS_BLIT_STRIDE_B(TILE_X_SZ >> 1);

	tile_ptr = (uint8_t *)(map_ptr_offset + map_layer_size);
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

void draw_front(uint8_t flags) {
	// specialised sprite plot - no bounds checking, all x are even

	scr_addr16 = XY_to_dma_scr_adr16(0,0);

	WR8_CS_BLIT_SHIFT_A(0);
	WR8_CS_BLIT_MASK_FIRST(0xFF);
	WR8_CS_BLIT_MASK_LAST(0xFF);

	WR16_CS_BLIT_STRIDE_A(TILE_X_SZ >> 3);
	WR16_CS_BLIT_STRIDE_B(TILE_X_SZ >> 1);

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


void draw_front_collide(uint8_t x, uint8_t y, uint8_t tileno, uint8_t colourB) {

	scr_addr16 = XY_to_dma_scr_adr16(x *TILE_X_SZ, y * TILE_Y_SZ);
	WR8_CS_BLIT_SHIFT_A(0);
	WR8_CS_BLIT_MASK_FIRST(0xFF);
	WR8_CS_BLIT_MASK_LAST(0xFF);

	WR16_CS_BLIT_STRIDE_A(TILE_X_SZ >> 3);
	WR8_CS_BLIT_DATA_B(colourB);

	coll_spr_addr(tileno-1);
	spr_save_and_plot((TILE_X_SZ>>1)-1, TILE_Y_SZ-1, BLITCON_EXEC_A + BLITCON_EXEC_C + BLITCON_EXEC_D + BLITCON_EXEC_E, scr_addr16);
}


struct mapdef_object *cur_obj;

uint8_t colcheck(
	uint8_t charspr_ix, 
	int8_t x, 
	int8_t y, 
	int8_t offsx, 
	int8_t offsy) {

	coll = get_tile_at(LAYER_COLL,x,y) & 0x7F;
	if (coll) {


//		uint16_t ch_addr = ((uint16_t)DMA_CHARAC_SPR) + ((uint16_t)charspr_ix*(uint16_t)CHARAC_SPR_SZ) + CHARAC_SPR_MO; // address of character mask
		uint16_t ch_addr = ((uint16_t)((uint32_t)DMA_CHARAC_SPR & 0xFFFF)) + ((uint16_t)16*(uint16_t)CHARAC_SPR_SZ) + CHARAC_SPR_MO; // address of character mask
		uint16_t coll_addr = ((uint16_t)((uint32_t)DMA_COLL_SPR & 0xFFFF)) + ((uint16_t)COLL_SPR_SZ*((uint16_t)coll-1)) + COLL_SPR_MO;
		uint8_t h = COL_Y_MAX;
		uint8_t bw = COLL_SPR_MASK_BYTES_PER_LINE;
		uint8_t shiftA = 0;
		uint8_t shiftB = 0;
		uint8_t mask_first = 0xFF;
		uint8_t mask_last = 0xFF;

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

		WR8_CS_BLIT_SHIFT_A(shiftA);
		WR8_CS_BLIT_SHIFT_B(shiftB);  
		WR8_CS_BLIT_MASK_FIRST(mask_first);
		WR8_CS_BLIT_MASK_LAST(mask_last);


		WR8_CS_BLIT_ADDR_A_BANK((uint32_t)DMA_CHARAC_SPR >> 16);
		WR16_CS_BLIT_ADDR_A(ch_addr);

		WR8_CS_BLIT_ADDR_B_BANK((uint32_t)DMA_COLL_SPR >> 16);
		WR16_CS_BLIT_ADDR_B(coll_addr);

		WR8_CS_BLIT_WIDTH(bw-1);
		WR16_CS_BLIT_STRIDE_A(COLL_SPR_MASK_BYTES_PER_LINE);
		WR16_CS_BLIT_STRIDE_B(COLL_SPR_MASK_BYTES_PER_LINE);
		WR8_CS_BLIT_HEIGHT(h-1);

		WR8_CS_BLIT_FUNCGEN(0xC0); //A&B
		WR8_CS_BLIT_BLITCON(BLITCON_EXEC_A | BLITCON_EXEC_B);
		WR8_CS_BLIT_BLITCON(BLITCON_ACT_ACT + BLITCON_ACT_MODE_1BBP + BLITCON_ACT_COLLIDE);

		//check result -- bodge using a function to get round ca65's lack of volatile
		if (getbltcon() & BLITCON_ACT_COLLIDE)
			return 0;

		//we had a collision - check to see if there's an object on this square - if there
		//is do its thing

		cur_obj = &(map_cur->objects[0]);
		while (cur_obj->type) {
			if (cur_obj->x == x + tile_off_x && cur_obj->y == y + tile_off_y) {
				if (cur_obj->type == MAPDEF_OBJ_TYPE_TELEPORT) {
					set_map(cur_obj->data.teleport.map);

					char_x = TILE_X_SZ * cur_obj->data.teleport.dest_x;
					char_y = TILE_Y_SZ * cur_obj->data.teleport.dest_y;

					set_offset(cur_obj->data.teleport.dest_x / ROOM_SZ_X, cur_obj->data.teleport.dest_y / ROOM_SZ_Y);
					room_exit = 1;
					return 0;
				}
			}
			cur_obj++;
		}


		draw_front_collide(x,y,coll,0xF0);

		return coll;
	} else 
		return 0;
}

//x in map coordinates
//y in map coordinates
uint16_t colcheck_at(int16_t old_x, int16_t old_y, int16_t new_x, int16_t new_y)
{
	//check for collision with tiles
	uint8_t col = 0;
	uint8_t x = new_x / TILE_X_SZ;
	uint8_t y = new_y / TILE_Y_SZ;
	uint8_t xx = new_x % TILE_X_SZ;
	uint8_t yy = new_y % TILE_Y_SZ;

	
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
	dma_copy_block(1,(void *)((uint32_t)DMA_TILE_MAP + (uint32_t)map->binary_offs), tilemap, 3*map_layer_size);

}


void set_offset(int16_t x, int16_t y) {

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

	map_ptr_offset = (uint8_t *)((uint32_t)map_ptr + (uint16_t)tile_off_x + (map_width*(uint16_t)tile_off_y));
	printf("O:%lX", (long)map_ptr_offset);
}

