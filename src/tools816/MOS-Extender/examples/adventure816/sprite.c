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

#include "oslib-ext.h"

#include "hardware816.h"
#include "adv_globals.h"
#include "dma.h"
#include "tile_map.h"

#include "screenmaths.h"

//---------------------- register read/write declarations
DECL_RD16(RD16_CS_BLIT_ADDR_A, CS_BLIT_ADDR_A)
DECL_RD16(RD16_CS_BLIT_ADDR_B, CS_BLIT_ADDR_B)
DECL_RD16(RD16_CS_BLIT_ADDR_E, CS_BLIT_ADDR_E)
DECL_WR16(WR16_CS_BLIT_ADDR_A, CS_BLIT_ADDR_A)
DECL_WR16(WR16_CS_BLIT_ADDR_B, CS_BLIT_ADDR_B)
DECL_WR16(WR16_CS_BLIT_ADDR_C, CS_BLIT_ADDR_C)
DECL_WR16(WR16_CS_BLIT_ADDR_D, CS_BLIT_ADDR_D)
DECL_WR16(WR16_CS_BLIT_STRIDE_A, CS_BLIT_STRIDE_A)
DECL_WR16(WR16_CS_BLIT_STRIDE_B, CS_BLIT_STRIDE_B)
DECL_WR16(WR16_CS_BLIT_STRIDE_C, CS_BLIT_STRIDE_C)
DECL_WR16(WR16_CS_BLIT_STRIDE_D, CS_BLIT_STRIDE_D)
DECL_WR32(WR32_CS_BLIT_ADDR_E, CS_BLIT_ADDR_E)
DECL_WR8(WR8_CS_BLIT_ADDR_A_BANK, CS_BLIT_ADDR_A+2)
DECL_WR8(WR8_CS_BLIT_ADDR_B_BANK, CS_BLIT_ADDR_B+2)
DECL_WR8(WR8_CS_BLIT_ADDR_C_BANK, CS_BLIT_ADDR_C+2)
DECL_WR8(WR8_CS_BLIT_ADDR_D_BANK, CS_BLIT_ADDR_D+2)
DECL_WR8(WR8_CS_BLIT_BLITCON, CS_BLIT_BLITCON)
DECL_WR8(WR8_CS_BLIT_FUNCGEN, CS_BLIT_FUNCGEN)
DECL_WR8(WR8_CS_BLIT_HEIGHT, CS_BLIT_HEIGHT)
DECL_WR8(WR8_CS_BLIT_MASK_FIRST, CS_BLIT_MASK_FIRST)
DECL_WR8(WR8_CS_BLIT_MASK_LAST, CS_BLIT_MASK_LAST)
DECL_WR8(WR8_CS_BLIT_SHIFT_A, CS_BLIT_SHIFT_A)
DECL_WR8(WR8_CS_BLIT_WIDTH, CS_BLIT_WIDTH)
//----------------------

typedef struct spr_save {
	uint16_t scr_addr_16;
	uint16_t bit_addr_16;
	uint8_t w;
	uint8_t h;
} spr_save;

spr_save* ptr_spr_save;
spr_save spr_save_block[SPR_SAVE_MAX];

//	scr_dma_addr16	- the address to plot to in screen ram (low 15 bits only)
//	w		- width in char cells-1
//	h		- height in pixel rows
void spr_save_and_plot(uint8_t w, uint8_t h, uint8_t execmask, uint16_t scr_dma_addr16)
{


	// plot address
	WR16_CS_BLIT_ADDR_C(scr_dma_addr16);
	//SET_DMA_WORD(CS_BLIT_ADDR_D, scr_dma_addr16); //TODO: NEWABI

	if (ptr_spr_save >= &spr_save_block[SPR_SAVE_MAX])
		OS_BRK(0xFF, "SPR SAVE AREA FULL");

	ptr_spr_save->scr_addr_16 = scr_dma_addr16;
	ptr_spr_save->bit_addr_16 = RD16_CS_BLIT_ADDR_E();
	ptr_spr_save->w = w;
	ptr_spr_save->h = h;
	ptr_spr_save++;

	WR8_CS_BLIT_WIDTH(w);
	WR8_CS_BLIT_HEIGHT(h);	

	WR8_CS_BLIT_BLITCON(execmask);	//	exec A,B,C,D,E

	WR8_CS_BLIT_FUNCGEN(0xCA);	//	A&B | nA&C
	WR8_CS_BLIT_BLITCON(BLITCON_ACT_ACT + BLITCON_ACT_MODE_4BBP + BLITCON_ACT_CELL);	//	act, cell, 4bpp
}

//	scr_dma_addr16	- the address to plot to in screen ram (low 15 bits only)
//	w		- width in char cells-1
//	h		- height in pixel rows
void spr_plot(uint8_t w, uint8_t h, uint8_t execmask, uint16_t scr_dma_addr16)
{


	// plot address
	WR16_CS_BLIT_ADDR_C(scr_dma_addr16);
	WR16_CS_BLIT_ADDR_D(scr_dma_addr16);

	WR8_CS_BLIT_WIDTH(w);
	WR8_CS_BLIT_HEIGHT(h);	

	WR8_CS_BLIT_FUNCGEN(0xCA);		//	A&B | nA&C
	WR8_CS_BLIT_BLITCON(execmask);	//	exec A,B,C,D,E
	WR8_CS_BLIT_BLITCON(BLITCON_ACT_ACT + BLITCON_ACT_MODE_4BBP + BLITCON_ACT_CELL);	//	act, cell, 4bpp
}



	int adj;

	uint16_t screen_addr16;
	uint16_t shiftA = 0;
	uint16_t shiftB = 0;

static int16_t x;
static int16_t y; 
static signed char w;
static signed char h;

void spr_plotXY(int16_t _x, int16_t _y, uint8_t _w, uint8_t _h)
{

	h=_h;
	w=_w;
	y=_y;
	x=_x;

	//TODO: screen size constants
	if ((y <= -(int)h) || (y > SCREEN_SZ_Y))
		return;

	WR16_CS_BLIT_STRIDE_B(w >> 1);
	WR16_CS_BLIT_STRIDE_A(w >> 3);

	if (y < 0) {		
		//off top of screen, keep incrementing y until +ve and sort out w/h
		WR16_CS_BLIT_ADDR_B(RD16_CS_BLIT_ADDR_B() + (-y * (w >> 1)));	
		WR16_CS_BLIT_ADDR_A(RD16_CS_BLIT_ADDR_A() + (-y * (w >> 3)));	
		h += y;
		y = 0;
	}

	adj = SCREEN_SZ_Y - (y+h);
	if (adj < 0)
	{
		h += adj;
		if (h == 0)
			return;
	}

	if (x < 0)
	{

		while (x <= -8)
		{
			WR16_CS_BLIT_ADDR_B(RD16_CS_BLIT_ADDR_B() + (4));
			WR16_CS_BLIT_ADDR_A(RD16_CS_BLIT_ADDR_A() + (1));
			w-=8;
			if (w <= 0) return;
			x+=8;
		}

		screen_addr16 = XY_to_dma_scr_adr16(x, y);


		WR8_CS_BLIT_MASK_LAST(0xFF); 
		if (x & 0x01) {
			WR8_CS_BLIT_MASK_FIRST(0xFF >> (1-x));
			WR8_CS_BLIT_SHIFT_A(0x01);
		}
		else {
			WR8_CS_BLIT_MASK_FIRST(0xFF >> (-x));
			WR8_CS_BLIT_SHIFT_A(0x00);
		}
	} else {

		adj = SCREEN_SZ_X - (x+w);
		if (adj < 0)
		{
			w += adj;
			if (w <= 0)
				return;
		}

		if (x & 1)
		{
			w++;
			WR8_CS_BLIT_MASK_FIRST(0x7F);	// mask off first bit
			WR8_CS_BLIT_SHIFT_A(0x1);
		} else {
			WR8_CS_BLIT_MASK_FIRST(0xFF);	
			WR8_CS_BLIT_SHIFT_A(0x0);
		}


		WR8_CS_BLIT_MASK_LAST(0xFF << ((8-w) & 0x07));	

		screen_addr16 = XY_to_dma_scr_adr16(x, y);
	}

	w = ((w+1) >> 1)-1;	// adjust to bytes


	spr_save_and_plot(w, h-1, BLITCON_EXEC_A + BLITCON_EXEC_B + BLITCON_EXEC_C + BLITCON_EXEC_D + BLITCON_EXEC_E, screen_addr16);
}
		

void spr_restore_init() {
	ptr_spr_save = NULL;
}

void spr_restore() {

	if (!ptr_spr_save)
		return;

	WR8_CS_BLIT_FUNCGEN(0xCC);			//just plot B
	WR8_CS_BLIT_ADDR_D_BANK(((uint32_t)DMA_SCR_SHADOW) >> 16);
	WR16_CS_BLIT_STRIDE_D(SCREEN_D_STRIDE);		//screen stride
	WR8_CS_BLIT_ADDR_B_BANK(((uint32_t)DMA_SPR_SAVE) >> 16);		//start of saved bitmaps
	WR8_CS_BLIT_BLITCON(BLITCON_EXEC_B + BLITCON_EXEC_D);
	WR8_CS_BLIT_SHIFT_A(0);
	

	while (ptr_spr_save > spr_save_block) {
		ptr_spr_save--;
		WR16_CS_BLIT_ADDR_B(ptr_spr_save->bit_addr_16);
		WR8_CS_BLIT_WIDTH(ptr_spr_save->w);
		WR8_CS_BLIT_HEIGHT(ptr_spr_save->h);
		WR16_CS_BLIT_STRIDE_B(ptr_spr_save->w+1);
		WR16_CS_BLIT_ADDR_D(ptr_spr_save->scr_addr_16);
		WR8_CS_BLIT_BLITCON(BLITCON_ACT_ACT + BLITCON_ACT_CELL + BLITCON_ACT_MODE_4BBP);
	}

	ptr_spr_save = 0;
}

void spr_init() {
	WR8_CS_BLIT_ADDR_C_BANK((uint32_t)DMA_SCR_SHADOW >> 16);
//	SET_DMA_BYTE(CS_BLIT_ADDR_D+2, DMA_SCR_SHADOW >> 16); //TODO: REMOVE NEWABI
}

void spr_save_start() {
	// set up channel E pointer and ptr_spr_save
	WR32_CS_BLIT_ADDR_E((uint32_t)(DMA_SPR_SAVE));
	WR16_CS_BLIT_STRIDE_C(SCREEN_D_STRIDE);
	//SET_DMA_WORD(CS_BLIT_STRIDE_D, SCREEN_D_STRIDE); //TODO: REMOVE NEWABI

		// setup screen block in dma
	ptr_spr_save = spr_save_block;
}


void charac_spr_plot_start() {
	WR8_CS_BLIT_ADDR_A_BANK((uint32_t)DMA_CHARAC_SPR >> 16);
	WR8_CS_BLIT_ADDR_B_BANK((uint32_t)DMA_CHARAC_SPR >> 16);

}


uint16_t tmp_addr;

void charac_spr_plot(int16_t x, int16_t y, uint8_t frameno) {

	tmp_addr = frameno*CHARAC_SPR_SZ;

	WR16_CS_BLIT_ADDR_B(tmp_addr);
	WR16_CS_BLIT_ADDR_A(tmp_addr + CHARAC_SPR_MO);
	spr_plotXY(x, y, CHARAC_SZ_X, CHARAC_SZ_Y);	
}



