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

#include <oslib/os.h>

#include "hardware.h"
#include "adv_globals.h"
#include "dma.h"
#include "myos.h"
#include "tile_map.h"

#include "brk.h"
#include "screenmaths.h"


#define ADD_LE_DMA_WORD(x, y) {*((unsigned volatile *)x) += y;}

typedef struct spr_save {
	unsigned int scr_addr_16;
	unsigned int bit_addr_16;
	unsigned char w;
	unsigned char h;
} spr_save;

spr_save* ptr_spr_save;
spr_save spr_save_block[SPR_SAVE_MAX-1];

//	scr_dma_addr16	- the address to plot to in screen ram (low 15 bits only)
//	w		- width in char cells-1
//	h		- height in pixel rows
void spr_save_and_plot(unsigned char w, unsigned char h, unsigned char execmask, unsigned int scr_dma_addr16)
{


	// plot address
	SET_LE_DMA_WORD(jim_CS_BLIT_ADDR_C, scr_dma_addr16);
	//SET_LE_DMA_WORD(jim_CS_BLIT_ADDR_D, scr_dma_addr16); //TODO: NEWABI

	if (ptr_spr_save >= &spr_save_block[SPR_SAVE_MAX-1])
		brk_bounce(0xFF, "SPR SAVE AREA FULL");

	ptr_spr_save->scr_addr_16 = scr_dma_addr16;
	ptr_spr_save->bit_addr_16 = GET_LE_DMA_WORD(jim_CS_BLIT_ADDR_E);
	ptr_spr_save->w = w;
	ptr_spr_save->h = h;
	ptr_spr_save++;

	SET_DMA_BYTE(jim_CS_BLIT_WIDTH, w);
	SET_DMA_BYTE(jim_CS_BLIT_HEIGHT, h);	

	SET_DMA_BYTE(jim_CS_BLIT_BLITCON, execmask);	//	exec A,B,C,D,E

	SET_DMA_BYTE(jim_CS_BLIT_FUNCGEN, 0xCA);	//	A&B | nA&C
	SET_DMA_BYTE(jim_CS_BLIT_BLITCON, BLITCON_ACT_ACT + BLITCON_ACT_MODE_4BBP + BLITCON_ACT_CELL);	//	act, cell, 4bpp
}

//	scr_dma_addr16	- the address to plot to in screen ram (low 15 bits only)
//	w		- width in char cells-1
//	h		- height in pixel rows
void spr_plot(unsigned char w, unsigned char h, unsigned char execmask, unsigned int scr_dma_addr16)
{


	// plot address
	SET_LE_DMA_WORD(jim_CS_BLIT_ADDR_C, scr_dma_addr16);
	SET_LE_DMA_WORD(jim_CS_BLIT_ADDR_D, scr_dma_addr16);

	SET_DMA_BYTE(jim_CS_BLIT_WIDTH, w);
	SET_DMA_BYTE(jim_CS_BLIT_HEIGHT, h);	

	SET_DMA_BYTE(jim_CS_BLIT_FUNCGEN, 0xCA);		//	A&B | nA&C
	SET_DMA_BYTE(jim_CS_BLIT_BLITCON, execmask);	//	exec A,B,C,D,E
	SET_DMA_BYTE(jim_CS_BLIT_BLITCON, BLITCON_ACT_ACT + BLITCON_ACT_MODE_4BBP + BLITCON_ACT_CELL);	//	act, cell, 4bpp
}



	int adj;

	unsigned int screen_addr16;
	unsigned int shiftA = 0;
	unsigned int shiftB = 0;

static signed int x;
static signed int y; 
static signed char w;
static signed char h;

void spr_plotXY(signed int _x, signed int _y, unsigned char _w, unsigned char _h)
{

	h=_h;
	w=_w;
	y=_y;
	x=_x;

	//TODO: screen size constants
	if ((y <= -(int)h) || (y > SCREEN_SZ_Y))
		return;

	SET_LE_DMA_WORD(jim_CS_BLIT_STRIDE_B, w >> 1);
	SET_LE_DMA_WORD(jim_CS_BLIT_STRIDE_A, w >> 3);

	if (y < 0) {		
		//off top of screen, keep incrementing y until +ve and sort out w/h
		ADD_LE_DMA_WORD(jim_CS_BLIT_ADDR_B, -y * (w >> 1));	
		ADD_LE_DMA_WORD(jim_CS_BLIT_ADDR_A, -y * (w >> 3));	
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
			ADD_LE_DMA_WORD(jim_CS_BLIT_ADDR_B, 4);
			ADD_LE_DMA_WORD(jim_CS_BLIT_ADDR_A, 1);
			w-=8;
			if (w <= 0) return;
			x+=8;
		}

		screen_addr16 = XY_to_dma_scr_adr(x, y);


		SET_DMA_BYTE(jim_CS_BLIT_MASK_LAST, 0xFF); 
		if (x & 0x01) {
			SET_DMA_BYTE(jim_CS_BLIT_MASK_FIRST, 0xFF >> (1-x));
			SET_DMA_BYTE(jim_CS_BLIT_SHIFT_A, 0x01);
		}
		else {
			SET_DMA_BYTE(jim_CS_BLIT_MASK_FIRST, 0xFF >> (-x));
			SET_DMA_BYTE(jim_CS_BLIT_SHIFT_A, 0x00);
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
			SET_DMA_BYTE(jim_CS_BLIT_MASK_FIRST, 0x7F);	// mask off first bit
			SET_DMA_BYTE(jim_CS_BLIT_SHIFT_A, 0x1);
		} else {
			SET_DMA_BYTE(jim_CS_BLIT_MASK_FIRST, 0xFF);	
			SET_DMA_BYTE(jim_CS_BLIT_SHIFT_A, 0x0);
		}


		SET_DMA_BYTE(jim_CS_BLIT_MASK_LAST, 0xFF << ((8-w) & 0x07) );	

		screen_addr16 = XY_to_dma_scr_adr(x, y);
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

	SET_DMA_BYTE(jim_CS_BLIT_FUNCGEN, 0xCC);			//just plot B
	SET_DMA_BYTE(jim_CS_BLIT_ADDR_D+2, DMA_SCR_SHADOW >> 16);
	SET_LE_DMA_WORD(jim_CS_BLIT_STRIDE_D, SCREEN_D_STRIDE);		//screen stride
	SET_DMA_BYTE(jim_CS_BLIT_ADDR_B+2, DMA_SPR_SAVE>>16);		//start of saved bitmaps
	SET_DMA_BYTE(jim_CS_BLIT_BLITCON, BLITCON_EXEC_B + BLITCON_EXEC_D);
	SET_DMA_BYTE(jim_CS_BLIT_SHIFT_A, 0);
	

	while (ptr_spr_save > spr_save_block) {
		ptr_spr_save--;
		SET_LE_DMA_WORD(jim_CS_BLIT_ADDR_B, ptr_spr_save->bit_addr_16);
		SET_DMA_BYTE(jim_CS_BLIT_WIDTH, ptr_spr_save->w);
		SET_DMA_BYTE(jim_CS_BLIT_HEIGHT, ptr_spr_save->h);
		SET_LE_DMA_WORD(jim_CS_BLIT_STRIDE_B, ptr_spr_save->w+1);
		SET_LE_DMA_WORD(jim_CS_BLIT_ADDR_D, ptr_spr_save->scr_addr_16);
		SET_DMA_BYTE(jim_CS_BLIT_BLITCON, BLITCON_ACT_ACT + BLITCON_ACT_CELL + BLITCON_ACT_MODE_4BBP);
	}

	ptr_spr_save = 0;
}

void spr_init() {
	SET_DMA_BYTE(jim_CS_BLIT_ADDR_C+2, DMA_SCR_SHADOW >> 16);
//	SET_DMA_BYTE(jim_CS_BLIT_ADDR_D+2, DMA_SCR_SHADOW >> 16); //TODO: REMOVE NEWABI
}

void spr_save_start() {
	// set up channel E pointer and ptr_spr_save
	SET_DMA_ADDR(jim_CS_BLIT_ADDR_E+2, DMA_SPR_SAVE);
	SET_LE_DMA_WORD(jim_CS_BLIT_STRIDE_C, SCREEN_D_STRIDE);
	//SET_LE_DMA_WORD(jim_CS_BLIT_STRIDE_D, SCREEN_D_STRIDE); //TODO: REMOVE NEWABI

		// setup screen block in dma
	ptr_spr_save = spr_save_block;
}


void charac_spr_plot_start() {
	SET_DMA_BYTE(jim_CS_BLIT_ADDR_A+2, DMA_CHARAC_SPR >> 16);
	SET_DMA_BYTE(jim_CS_BLIT_ADDR_B+2, DMA_CHARAC_SPR >> 16);

}


unsigned int tmp_addr;

void charac_spr_plot(signed int x, signed int y, unsigned char frameno) {

	// tmp_addr = frameno*CHARAC_SPR_SZ;
	// i.e. & 0xF0

	asm("		ldx	#0");
	asm("		stx	_tmp_addr+1");

	asm("		sta	ptr1");		//temp store A	
	asm("		asl     A");
	asm("		rol     _tmp_addr+1");
	asm("		asl     A");
	asm("		rol     _tmp_addr+1");
	asm("		asl     A");
	asm("		rol     _tmp_addr+1");
	asm("		asl     A");
	asm("		rol     _tmp_addr+1");

	// tmp_addr = 0x10 * frameno

	asm("		sec");
	asm("		sbc	ptr1");
	asm("		sta	_tmp_addr");
	asm("		lda	_tmp_addr+1");
	asm("		sbc	#0");		

	asm("		asl	_tmp_addr");
	asm("		rol 	A");
	asm("		asl	_tmp_addr");
	asm("		rol 	A");
	asm("		asl	_tmp_addr");
	asm("		rol 	A");
	asm("		asl	_tmp_addr");
	asm("		rol 	A");
	asm("		sta	_tmp_addr+1");

	// tmp_addr = 0x0F * frameno

	SET_LE_DMA_WORD(jim_CS_BLIT_ADDR_B, tmp_addr);

	asm("		clc");
	asm("		lda	_tmp_addr");
	asm("		adc	#%b", (unsigned int)CHARAC_SPR_MO);
	asm("		sta	%w", jim_CS_BLIT_ADDR_A+0);
	asm("		lda	_tmp_addr+1");
	asm("		adc	#0");
	asm("		sta	%w", jim_CS_BLIT_ADDR_A + 1);

	spr_plotXY(x, y, CHARAC_SZ_X, CHARAC_SZ_Y);	
// charac_spr_plot	; plot character A at X,Y
// 		pshs	D
// 		jsr	charac_a_to_u
// 		lda	#24-1
// 		jsr	spr_plot
// 		puls	D,PC
}



