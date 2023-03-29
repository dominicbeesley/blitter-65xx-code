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
#include "globals.h"
#include "dma.h"
#include "myos.h"



extern unsigned char *asc2font[];
extern unsigned int font_tile_bases[];

extern char aeris_test_pgm;
extern char aeris_test_pgm_end;
extern void aeris_wait_vsync();

extern char aeris_movep_instr;
extern char ae_text_rainbow;

//const char const *message="HELLO   ISHBEL   MUMMY  AND  DADDY   !@#? \x80 STARDOT 0123456789 ABC DEF GHI JKL MNO PQR STU VWX YZ!        ";

const char const *message="ISHBEL     ANDY    DOMINIC    STACEY    AND     CAT     ONCE     UPON    A    TIME    THERE     WAS    A    LITTLE     GIRL     WHO     LIKED     PEAS            ";

const char *msgptr;

unsigned char char_off_x; // number of double pixel bytes into current char tile 0..7
unsigned char char_tile_x; // tile within current char 0..5

unsigned char tile_no;
char *tile_addr;

char cur_char;
char cur_char_mapped;
char *cur_char_map;
char *tmp_char_map;

unsigned char i, j, k, l;

unsigned int scr_ptr;
unsigned int scr_start_6845=0x600;
unsigned int scr_ptr_base=0x3000;		//top of right most 2 bytes of screen (to be cleared / base for blits)

unsigned char y_top = 40;


unsigned char pal_offs=0;
unsigned char pal_offs2=0;

unsigned int pal_x[6] = {
	0x000,
	0x220,
	0x440,
	0x650,
	0x440,
	0x220
};

char first = 1;

typedef struct t_owl_pos {
	int x;
	int y;
	unsigned char dx;
	unsigned int addr;
	unsigned int w;
} t_owl_pos;

#define N_OWLS 4

struct t_owl_pos owls[N_OWLS] = {
	{ 155, 70, 1, 0 },
	{ 154, 100, 2, 0 },
	{ 153, 110, 3, 0 },
	{ 152, 200, 4, 0 }
/*	,
	{ 155, 65, 3, 0 },
	{ 150, 103, 5, 0 },
	{ 153, 160, 7, 0 },*/
};

unsigned int SCR_LIM(unsigned int addr) {
	if (addr & (unsigned int)0x8000)
		return addr-0x5000;
	else
		return addr; 
}

void jimDEV(void) {
	*((unsigned char *)fred_JIM_PAGE_LO) = jim_page_DMAC & 0xFF;
	*((unsigned char *)fred_JIM_PAGE_HI) = jim_page_DMAC >> 8;
}

void jimAEPGM(void) {
	*((unsigned char *)fred_JIM_PAGE_LO) = (DMA_AERIS >> 8) & 0xFF;
	*((unsigned char *)fred_JIM_PAGE_HI) = DMA_AERIS >> 16;
}


unsigned char pausetgl;

void main(void) {

	OSWRCH(22);
	OSWRCH(2);



	//naughty - set jim devno but don't save old
	*((unsigned char *)0xEE) = JIM_DEVNO_BLITTER;
	*((unsigned char *)fred_JIM_DEVNO) = JIM_DEVNO_BLITTER;
	jimDEV();

	msgptr = message;
	char_off_x = 0;
	char_tile_x = 0;


	dma_copy_block(0xFF0000L | (long)&aeris_test_pgm,DMA_AERIS,(unsigned int)&aeris_test_pgm_end-(unsigned int)&aeris_test_pgm);

	SET_DMA_ADDR(jim_DMAC_AERIS_PROGBASE, DMA_AERIS);
	SET_DMA_BYTE(jim_DMAC_AERIS_CTL, 0x80);

	while(1) {

		if (my_os_byteAXY(0x81, 0xFF, 0xFF)) {
			pausetgl = my_os_byteAXY(0x81, 0xFE, 0xFF);
			while (my_os_byteAXY(0x81, 0xFF, 0xFF)) 
			{
				i = my_os_byteAXY(0x81, 0xFE, 0xFF);
				if (i != pausetgl) {
					pausetgl = i;
					break;
				}
				aeris_wait_vsync();
			}
		}

		aeris_wait_vsync();


		scr_start_6845+=2;
		if (scr_start_6845 >= 0x1000)
		{
			scr_start_6845 = 0x600 + scr_start_6845 & 0xFFF;
		}

		asm("sei");
		*(char *)sheila_6845_reg=12;
		*(char *)sheila_6845_rw=scr_start_6845 >> 8;

		*(char *)sheila_6845_reg=13;
		*(char *)sheila_6845_rw=scr_start_6845;
		asm("cli");


		asm("sei");

		//do a nula reset to force resync of palette regs
		*((volatile char *)SHEILA_NULA_CTLAUX) = 0x40;
		*((char *)SHEILA_NULA_PALAUX) = 0x00;
		*((char *)SHEILA_NULA_PALAUX) = 0x00;

		*((char *)SHEILA_NULA_PALAUX) = 0x8D;
		*((char *)SHEILA_NULA_PALAUX) = 0xFF;

		pal_offs++;
		if (pal_offs >= 6)
			pal_offs = 0;

		i = 5 - (pal_offs);
		j = 0;

		while (j < 6) {

			*((char *)SHEILA_NULA_PALAUX) = ((j+1) << 4) | (pal_x[i] >> 8);
			*((char *)SHEILA_NULA_PALAUX) = pal_x[i];

			*((char *)SHEILA_NULA_PALAUX) = 0x80 | ((j+1) << 4) | (pal_x[i] >> 8);
			*((char *)SHEILA_NULA_PALAUX) = pal_x[i];


			i++;
			if (i >= 6)
				i=0;
			j++;
		}

		asm("cli");


		jimAEPGM();
		j = &ae_text_rainbow  - (&aeris_movep_instr + 3) + (8 * (pal_offs2 & 0xF));
		i = &aeris_movep_instr - &aeris_test_pgm;
		*((char *)(0xFD00 + 1 + i)) = j >> 8;
		*((char *)(0xFD00 + 2 + i)) = j;
		jimDEV();
		pal_offs2++;

		if (first) 
			first = 0;
		else {


			
			for (i = 0; i < N_OWLS; i++) {

				scr_ptr = owls[i].addr;
				k = owls[i].x & 0x01;
				l = owls[i].w;

				//owl logo "un"plot (not and with screen)
				// setup screen block in dma
				SET_DMA_BYTE(jim_DMAC_ADDR_D, 0xFF);
				SET_DMA_BYTE(jim_DMAC_ADDR_C, 0xFF);
				// plot address
				SET_DMA_WORD(jim_DMAC_ADDR_D+1, scr_ptr);
				SET_DMA_WORD(jim_DMAC_ADDR_C+1, scr_ptr);

				SET_DMA_BYTE(jim_DMAC_ADDR_B, DMA_OWL_TIL >> 16);
				SET_DMA_WORD(jim_DMAC_ADDR_B+1, (unsigned int)DMA_OWL_TIL);


				SET_DMA_BYTE(jim_DMAC_DATA_A, 0xFF);

				SET_DMA_WORD(jim_DMAC_STRIDE_B, 9);
				SET_DMA_WORD(jim_DMAC_STRIDE_D, 640);
				SET_DMA_WORD(jim_DMAC_STRIDE_C, 640);

				if (k) {
					SET_DMA_BYTE(jim_DMAC_SHIFT, 0x11);
					SET_DMA_BYTE(jim_DMAC_MASK_FIRST, 0x7F);
					SET_DMA_BYTE(jim_DMAC_MASK_LAST, 0xFF);
				} else {
					SET_DMA_BYTE(jim_DMAC_SHIFT, 0x00);
					SET_DMA_BYTE(jim_DMAC_MASK_FIRST, 0xFF);
					SET_DMA_BYTE(jim_DMAC_MASK_LAST, 0xFF);				
				}

				SET_DMA_BYTE(jim_DMAC_WIDTH, l);
				SET_DMA_BYTE(jim_DMAC_HEIGHT, 42-1);	
				
				SET_DMA_BYTE(jim_DMAC_ADDR_D_min, 0xFF);
				SET_DMA_BYTE(jim_DMAC_ADDR_D_max, 0xFF);
				SET_DMA_WORD(jim_DMAC_ADDR_D_min+1, 0x3000);
				SET_DMA_WORD(jim_DMAC_ADDR_D_max+1, 0x8000);

				SET_DMA_BYTE(jim_DMAC_FUNCGEN, 0x2A);	//	C&(!(B&A))
				SET_DMA_BYTE(jim_DMAC_BLITCON, BLITCON_EXEC_B+BLITCON_EXEC_C+BLITCON_EXEC_D);	//	exec A,B,C,D,E
				SET_DMA_BYTE(jim_DMAC_BLITCON, BLITCON_ACT_ACT + BLITCON_ACT_MODE_4BBP + BLITCON_ACT_CELL + BLITCON_ACT_WRAP);	//	act, cell, 4bpp
			}
			
				
		}

		scr_ptr_base=SCR_LIM(scr_ptr_base + 16);


		for (i = 0; i < N_OWLS; i++) {

			l = 9-1;
			j = owls[i].x;
			j+= owls[i].dx;
			if (j >= 160) {
				j-= 160;
			} else if (j > (160-18)) {
				l-=(j-(160-18)) >> 1;
			}	
			owls[i].x = j;
			k = j & 0x01;
			j = j >> 1;

			owls[i].w = l;

			scr_ptr = SCR_LIM(scr_ptr_base + (j << 3) + (640 * (owls[i].y >> 3)) + (owls[i].y & 0x7));

			owls[i].addr = scr_ptr;

			//owl logo plot (or with screen)
			// setup screen block in dma
			SET_DMA_BYTE(jim_DMAC_ADDR_D, 0xFF);
			SET_DMA_BYTE(jim_DMAC_ADDR_C, 0xFF);
			// plot address
			SET_DMA_WORD(jim_DMAC_ADDR_D+1, scr_ptr);
			SET_DMA_WORD(jim_DMAC_ADDR_C+1, scr_ptr);

			SET_DMA_BYTE(jim_DMAC_ADDR_B, DMA_OWL_TIL >> 16);
			SET_DMA_WORD(jim_DMAC_ADDR_B+1, (unsigned int)DMA_OWL_TIL);


			SET_DMA_BYTE(jim_DMAC_DATA_A, 0xFF);

			SET_DMA_WORD(jim_DMAC_STRIDE_B, 9);
			SET_DMA_WORD(jim_DMAC_STRIDE_D, 640);
			SET_DMA_WORD(jim_DMAC_STRIDE_C, 640);

			if (k) {
				SET_DMA_BYTE(jim_DMAC_SHIFT, 0x11);
				SET_DMA_BYTE(jim_DMAC_MASK_FIRST, 0x7F);
				SET_DMA_BYTE(jim_DMAC_MASK_LAST, 0xFF);
			} else {
				SET_DMA_BYTE(jim_DMAC_SHIFT, 0x00);
				SET_DMA_BYTE(jim_DMAC_MASK_FIRST, 0xFF);
				SET_DMA_BYTE(jim_DMAC_MASK_LAST, 0xFF);				
			}

			SET_DMA_BYTE(jim_DMAC_WIDTH, l);
			SET_DMA_BYTE(jim_DMAC_HEIGHT, 42-1);	
			
			SET_DMA_BYTE(jim_DMAC_ADDR_D_min, 0xFF);
			SET_DMA_BYTE(jim_DMAC_ADDR_D_max, 0xFF);
			SET_DMA_WORD(jim_DMAC_ADDR_D_min+1, 0x3000);
			SET_DMA_WORD(jim_DMAC_ADDR_D_max+1, 0x8000);

			SET_DMA_BYTE(jim_DMAC_FUNCGEN, 0xEA);	//	(B&A)|C
			SET_DMA_BYTE(jim_DMAC_BLITCON, BLITCON_EXEC_B+BLITCON_EXEC_C+BLITCON_EXEC_D);	//	exec A,B,C,D,E
			SET_DMA_BYTE(jim_DMAC_BLITCON, BLITCON_ACT_ACT + BLITCON_ACT_MODE_4BBP + BLITCON_ACT_CELL + BLITCON_ACT_WRAP);	//	act, cell, 4bpp


		}
		



		SET_DMA_BYTE(jim_DMAC_SHIFT, 0x00);
		SET_DMA_BYTE(jim_DMAC_MASK_FIRST, 0xFF);
		SET_DMA_BYTE(jim_DMAC_MASK_LAST, 0xFF);				


		//clear scrolled out column
		// setup screen block in dma
		SET_DMA_BYTE(jim_DMAC_ADDR_D, 0xFF);
		// plot address
		SET_DMA_WORD(jim_DMAC_ADDR_D+1, SCR_LIM(scr_ptr_base+0x270));

		SET_DMA_BYTE(jim_DMAC_DATA_B, 0);

		SET_DMA_WORD(jim_DMAC_STRIDE_D, 640);

		SET_DMA_BYTE(jim_DMAC_WIDTH, 2-1);
		SET_DMA_BYTE(jim_DMAC_HEIGHT, 256-1);	
		
		SET_DMA_BYTE(jim_DMAC_ADDR_D_min, 0xFF);
		SET_DMA_BYTE(jim_DMAC_ADDR_D_max, 0xFF);
		SET_DMA_WORD(jim_DMAC_ADDR_D_min+1, 0x3000);
		SET_DMA_WORD(jim_DMAC_ADDR_D_max+1, 0x8000);

		SET_DMA_BYTE(jim_DMAC_FUNCGEN, 0xCC);	//	B
		SET_DMA_BYTE(jim_DMAC_BLITCON, BLITCON_EXEC_D);	//	exec D
		SET_DMA_BYTE(jim_DMAC_BLITCON, BLITCON_ACT_ACT + BLITCON_ACT_MODE_4BBP + BLITCON_ACT_CELL + BLITCON_ACT_WRAP);	//	act, cell, 4bpp



		if (char_off_x == 0 && char_tile_x == 0) {
			//get char of message;
			cur_char = *msgptr;
			if (cur_char != 0)
			{
				// look up tile 
				cur_char_mapped=cur_char - 32;
				cur_char_mapped&=63;
				cur_char_map=asc2font[cur_char_mapped];
			} else {
				cur_char_map=0;
			}			
		}
		

		//do 6 tiles for the char
		scr_ptr = SCR_LIM(scr_ptr_base + 640-16 + (y_top & 0x7) + (y_top & 0xF8) * 80); //somewhere near centre right of screen
		tmp_char_map = cur_char_map;
		for (i = 0; i < 6; i++) {
			if (tmp_char_map == 0)
				tile_no = 0;
			else
				tile_no = *(tmp_char_map++);
			tile_addr = (char *)font_tile_bases[tile_no]+char_off_x;

			// blit the tile sliver at the right of the screen

			// setup screen block in dma
			SET_DMA_BYTE(jim_DMAC_ADDR_D, 0xFF);
			// plot address
			SET_DMA_WORD(jim_DMAC_ADDR_D+1, scr_ptr);

			SET_DMA_BYTE(jim_DMAC_ADDR_B, DMA_FONT_TIL >> 16);
			SET_DMA_WORD(jim_DMAC_ADDR_B+1, (unsigned int)tile_addr);


			SET_DMA_WORD(jim_DMAC_STRIDE_B, 8);
			SET_DMA_WORD(jim_DMAC_STRIDE_D, 640);

			SET_DMA_BYTE(jim_DMAC_WIDTH, 2-1);
			SET_DMA_BYTE(jim_DMAC_HEIGHT, 32-1);	
			
			SET_DMA_BYTE(jim_DMAC_ADDR_D_min, 0xFF);
			SET_DMA_BYTE(jim_DMAC_ADDR_D_max, 0xFF);
			SET_DMA_WORD(jim_DMAC_ADDR_D_min+1, 0x3000);
			SET_DMA_WORD(jim_DMAC_ADDR_D_max+1, 0x8000);

			SET_DMA_BYTE(jim_DMAC_FUNCGEN, 0xCC);	//	B
			SET_DMA_BYTE(jim_DMAC_BLITCON, BLITCON_EXEC_B+BLITCON_EXEC_D);	//	exec A,B,C,D,E
			SET_DMA_BYTE(jim_DMAC_BLITCON, BLITCON_ACT_ACT + BLITCON_ACT_MODE_4BBP + BLITCON_ACT_CELL + BLITCON_ACT_WRAP);	//	act, cell, 4bpp

			scr_ptr=SCR_LIM(scr_ptr + 640*32/8);	
		}

		

		char_off_x +=2;
		if (char_off_x >= 8)
		{
			cur_char_map = tmp_char_map;
			char_tile_x++;
			char_off_x = 0;
			if (char_tile_x >= 6)
			{
				char_tile_x = 0;
				if (cur_char)
					msgptr++;
				else
					msgptr = message;
			}
		}

		//return;
	}


}


