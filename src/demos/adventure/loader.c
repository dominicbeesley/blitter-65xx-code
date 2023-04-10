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
#include "adv_globals.h"
#include "dma.h"
#include "myos.h"

#include "rle_asm.h"

//!!!!!!!!!!!!!!!!!!!!!!!!!!!! TODO !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// BRK HANDLER BORKEN - CLIB needs to page in, have bounce down to low mem and page in CLIB?


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

unsigned char fh;
unsigned char rle_read_ptr;
int rle_eof;
long rle_len;
unsigned char rle_ptr;
//unsigned char rle_tmp;

void nofile(void) {
	my_os_brk(0xFF, "Cannot open file");
}

int rle_read() {
	if (rle_read_ptr == 0 || rle_read_ptr >= rle_eof)
	{
		rle_read_ptr = 0;	
		if (rle_eof & 0xFF)
			return -1;
		else {
			rle_eof = (int)my_os_gbpb_read(fh, RLE_LOADBUF, RLE_LOADBUFSZ);
			if (rle_eof == 256) 
			{
				return -1;
			}
			else {
				rle_eof = 256 - rle_eof;
			}
		}	
	}
	return RLE_LOADBUF[rle_read_ptr++];
}

void rle_load(const char *filename, bits32 chip_addr) {

	*((unsigned char *)fred_JIM_PAGE_LO) = chip_addr >> 8;
	*((unsigned char *)fred_JIM_PAGE_HI) = chip_addr >> 16;
	rle_ptr = chip_addr & 0xFF;

	fh = my_os_find_open(0x40, filename);
	if (!fh)
		nofile();

	rle_read_ptr = 0;
	rle_eof = 0;

	my_os_gbpb_read(fh, &rle_len, 4);

	rle_load_loop();
	
	puts("END");

eof:

	my_os_find_close(fh);
}

void loadcharactersprites(void) {
	puts("char");
	rle_load("T.CHARAC", DMA_CHARAC_SPR);
}

void loadbacktiles(void) {
	puts("back");
	rle_load("T.OBACK", DMA_BACK_SPR);	
}

void loadforetiles(void) {
	puts("fore");
	rle_load("T.OFRONT", DMA_FRONT_SPR);	
}


void loadtiles(void) {
	puts("tilemap");
	rle_load("M.OVER", DMA_TILE_MAP);
}

void main(void) {

	//naughty - set jim devno but don't save old
	*((unsigned char *)0xEE) = JIM_DEVNO_BLITTER;
	*((unsigned char *)fred_JIM_DEVNO) = JIM_DEVNO_BLITTER;


//	OSWRCH(22);
//	OSWRCH(7);

	OSWRCH(22);
	OSWRCH(2);

	loadcharactersprites();
	loadbacktiles();
	loadforetiles();

	*((unsigned char *)fred_JIM_PAGE_LO) = jim_page_DMAC & 0xFF;
	*((unsigned char *)fred_JIM_PAGE_HI) = jim_page_DMAC >> 8;

	loadtiles();

	loadpal();

}
