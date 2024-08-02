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

extern	void effect_copper_bounce();

extern char aeris_test_pgm;
extern char aeris_test_pgm_end;
extern void aeris_wait_vsync();

//// extern char aeris_movep_instr;
extern char aeris_movep_instr2;
//// extern char ae_text_rainbow;
extern char ae_sintab;

extern unsigned char aeris_test_pgm_rainbow;
extern unsigned char aeris_test_pgm_copper;
extern unsigned char pal_rainbow;
extern signed char sintab;

unsigned char i, j, k, l, rbo;
signed char s;

unsigned char *p, *q;

unsigned short oof;

void jimDEV(void) {
	*((unsigned char *)fred_JIM_PAGE_LO) = jim_page_CHIPSET & 0xFF;
	*((unsigned char *)fred_JIM_PAGE_HI) = jim_page_CHIPSET >> 8;
}

void jimAEPGM(void) {
	*((unsigned char *)fred_JIM_PAGE_LO) = (DMA_AERIS >> 8) & 0xFF;
	*((unsigned char *)fred_JIM_PAGE_HI) = DMA_AERIS >> 16;
}


unsigned char pausetgl;

void main(void) {


	for (i = 0; i < 30; i++) {
		my_os_byteAXY(19,0,0);
	}


	//naughty - set jim devno but don't save old
	*((unsigned char *)0xEE) = JIM_DEVNO_BLITTER;
	*((unsigned char *)fred_JIM_DEVNO) = JIM_DEVNO_BLITTER;
	jimDEV();


	dma_copy_block(0xFF0000L | (long)&aeris_test_pgm,DMA_AERIS,(unsigned int)&aeris_test_pgm_end-(unsigned int)&aeris_test_pgm);

	SET_DMA_ADDR(jim_CS_AERIS_PROGBASE, DMA_AERIS);
	SET_DMA_BYTE(jim_CS_AERIS_CTL, 0x80);

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

		//update rainbow
		rbo++;
		p = (&aeris_test_pgm_rainbow);
		q = (&pal_rainbow);
		q += (rbo*2);		
		j = 16;
		for (i = 1; i < 16; i++ ) {
			while (q >= (&pal_rainbow) + 64) {
				q -= 64;
			}
			p[2] = j | q[0];
			p[3] = q[1];
			p+=4;
			q+=4;
			j+=16;
		}

		effect_copper_bounce();



////		asm("sei");
////
////		//do a nula reset to force resync of palette regs
////		*((volatile char *)SHEILA_NULA_CTLAUX) = 0x40;
////		*((char *)SHEILA_NULA_PALAUX) = 0x00;
////		*((char *)SHEILA_NULA_PALAUX) = 0x00;
////
////		*((char *)SHEILA_NULA_PALAUX) = 0x8D;
////		*((char *)SHEILA_NULA_PALAUX) = 0xFF;
////
////		pal_offs++;
////		if (pal_offs >= 6)
////			pal_offs = 0;
////
////		i = 5 - (pal_offs);
////		j = 0;
////
////		while (j < 6) {
////
////			*((char *)SHEILA_NULA_PALAUX) = ((j+1) << 4) | (pal_x[i] >> 8);
////			*((char *)SHEILA_NULA_PALAUX) = pal_x[i];
////
////			*((char *)SHEILA_NULA_PALAUX) = 0x80 | ((j+1) << 4) | (pal_x[i] >> 8);
////			*((char *)SHEILA_NULA_PALAUX) = pal_x[i];
////
////
////			i++;
////			if (i >= 6)
////				i=0;
////			j++;
////		}
////
////		asm("cli");


////		jimAEPGM();
////		oof = &ae_text_rainbow  - (&aeris_movep_instr + 3) + (8 * (pal_offs2 & 0xF));
////		i = &aeris_movep_instr - &aeris_test_pgm;
////		*((unsigned char *)(0xFD00 + 1 + i)) = oof >> 8;
////		*((unsigned char *)(0xFD00 + 2 + i)) = oof;
////
////
////		jimDEV();
////		pal_offs2++;


		aeris_wait_vsync();

		oof = &ae_sintab  - (&aeris_movep_instr2 + 3) + (3 * (rbo & 0xF));
		*((unsigned char *)(&aeris_movep_instr2 + 1)) = oof >> 8;
		*((unsigned char *)(&aeris_movep_instr2 + 2)) = oof;

		dma_copy_block(0xFF0000L | (long)&aeris_test_pgm,DMA_AERIS,(unsigned int)&aeris_test_pgm_end-(unsigned int)&aeris_test_pgm);

		//return;
	}


}


