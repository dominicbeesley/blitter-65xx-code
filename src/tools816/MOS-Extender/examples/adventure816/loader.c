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

#include "oslib-ext.h"

#include "hardware816.h"
#include "adv_globals.h"
#include "dma.h"

#include "rle_asm.h"

#include "sprite.h"

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


void loadpal(void) {
	unsigned char i;
	char *pe = DMA_LOADBUFFER;

	os_file_blk blk;
	blk.filename = "P.MAIN";
	blk.load = (void *)DMA_LOADBUFFER;
	blk.exec = 0;

	puts("pal");
	xos_file(0xFF, &blk);

	*((volatile uint8_t *)SHEILA_NULA_CTLAUX) = 0x40;

	for (i=32; i>0; i--)
	{
		*((volatile uint8_t *)SHEILA_NULA_PALAUX) = *pe++;
	}

}

uint16_t fh;
int rle_read_ptr;
unsigned rle_eof;
long rle_len;
void *rle_ptr;
//unsigned char rle_tmp;
os_gbpb_blk gbpb_blk;

void nofile(void) {
	puts("Cannot open file");

}

int rle_read() {
	if (rle_read_ptr >= RLE_LOADBUFSZ || rle_read_ptr >= rle_eof)
	{
		rle_read_ptr = 0;	
		if (rle_eof)
			return -1;
		else {
			gbpb_blk.rw.handle = fh;
			gbpb_blk.rw.data = RLE_LOADBUF;
			gbpb_blk.rw.count = RLE_LOADBUFSZ;
			xos_gbpb(4, &gbpb_blk);
			rle_eof = gbpb_blk.rw.count;
		}	
	}
	return ((uint8_t *)RLE_LOADBUF)[rle_read_ptr++];
}

void rle_load(const char *filename, void *chip_addr) {

	rle_ptr = chip_addr;

	printf("%s %lx - ", filename, (long)rle_ptr);

	xos_find_open(filename, 0x40, &fh);
	if (!fh)
		nofile();

	rle_read_ptr = 0;
	rle_eof = 0;

	gbpb_blk.rw.handle = fh;
	gbpb_blk.rw.data = &rle_len;
	gbpb_blk.rw.count = 4;

	xos_gbpb(4, &gbpb_blk);

	rle_load_loop();
	
	printf("END %lx\n", (long)rle_ptr);

	xos_find_close(fh);
}

void loadcharactersprites(void) {
	rle_load("T.CHARAC", DMA_CHARAC_SPR);
}

void loadbacktiles(void) {
	rle_load("T.OBACK", DMA_BACK_SPR);	
}

void loadforetiles(void) {
	rle_load("T.OFRONT", DMA_FRONT_SPR);	
}

void loadcolltiles(void) {
	rle_load("T.OCOLL", DMA_COLL_SPR);	
}

void loadtiles(void) {
	rle_load("M.OVER", DMA_TILE_MAP);
}

int main(void) {

	setvbuf(stdout, NULL, _IONBF, 0);

//	//naughty - set jim devno but don't save old
//	*((unsigned char *)0xEE) = JIM_DEVNO_BLITTER;
//	*((unsigned char *)fred_JIM_DEVNO) = JIM_DEVNO_BLITTER;

	xos_wrch(22);
	xos_wrch(2);

	loadcharactersprites();
	loadbacktiles();
	loadforetiles();
	loadcolltiles();
//
//	*((unsigned char *)fred_JIM_PAGE_LO) = jim_page_CHIPSET & 0xFF;
//	*((unsigned char *)fred_JIM_PAGE_HI) = jim_page_CHIPSET >> 8;
//
//	loadtiles();

	loadpal();


	return 0;
}
