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

#include "gen_vars.h"

#include "hardware.h"
#include "globals.h"
#include "dma.h"


void loadpal(void) {
	unsigned char i;
	char *pe = A_LOADBUFFER;

	puts("pal");
	osfile_load("P.MAIN", A_LOADBUFFER, NULL, NULL, NULL, NULL);

	*((byte *)SHEILA_NULA_CTLAUX) = 0x40;

	for (i=32; i>0; i--)
	{
		*((byte *)SHEILA_NULA_PALAUX) = *pe++;
	}

}

void loadfonttiles(void) {
	puts("font");
	osfile_load("T.FONT", A_LOADBUFFER, NULL, NULL, NULL, NULL);
	dma_copy_block(DMA_LOADBUFFER,DMA_FONT_TIL,FONT_TIL_LEN);
}

void loadowl(void) {
	puts("font");
	osfile_load("T.OWL", A_LOADBUFFER, NULL, NULL, NULL, NULL);
	dma_copy_block(DMA_LOADBUFFER,DMA_OWL_TIL,OWL_TIL_LEN);
}


void main(void) {

	//naughty - set jim devno but don't save old
	*((unsigned char *)0xEE) = JIM_DEVNO_BLITTER;
	*((unsigned char *)fred_JIM_DEVNO) = JIM_DEVNO_BLITTER;
	*((unsigned char *)fred_JIM_PAGE_LO) = jim_page_CHIPSET & 0xFF;
	*((unsigned char *)fred_JIM_PAGE_HI) = jim_page_CHIPSET >> 8;


//	OSWRCH(22);
//	OSWRCH(7);

	OSWRCH(22);
	OSWRCH(2);

	loadpal();
	loadfonttiles();
	loadowl();
}
