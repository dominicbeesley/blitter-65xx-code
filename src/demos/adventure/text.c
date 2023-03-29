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

#include "oslib/os.h"
#include "adv_globals.h"
#include "hardware.h"

unsigned int cursor;

void setcursor(unsigned int addr16) {
	cursor = addr16;
}

void plot_char(char c) {
	SET_DMA_BYTE(jim_DMAC_WIDTH, 4-1);
	SET_DMA_BYTE(jim_DMAC_HEIGHT, 8-1);
	SET_DMA_BYTE(jim_DMAC_SHIFT, 0x00);
	SET_DMA_BYTE(jim_DMAC_MASK_FIRST, 0xFF);
	SET_DMA_BYTE(jim_DMAC_MASK_LAST, 0xFF);
	SET_DMA_BYTE(jim_DMAC_ADDR_D, DMA_SCR_SHADOW >> 16);
	SET_DMA_WORD(jim_DMAC_ADDR_D+1, cursor);
	SET_DMA_BYTE(jim_DMAC_ADDR_C, DMA_SCR_SHADOW >> 16);
	SET_DMA_WORD(jim_DMAC_ADDR_C+1, cursor);
	SET_DMA_WORD(jim_DMAC_STRIDE_D, SCREEN_D_STRIDE);
	SET_DMA_WORD(jim_DMAC_STRIDE_A, 1);

	SET_DMA_BYTE(jim_DMAC_ADDR_A, 0xFF);
	SET_DMA_WORD(jim_DMAC_ADDR_A+1, 0xC000 - (32*8) + ((unsigned)c)*8);
	SET_DMA_BYTE(jim_DMAC_DATA_B, 0x0F);
	SET_DMA_BYTE(jim_DMAC_FUNCGEN, 0xC0); // just plot data B through A
	SET_DMA_BYTE(jim_DMAC_BLITCON, BLITCON_EXEC_A | BLITCON_EXEC_C | BLITCON_EXEC_D);
	SET_DMA_BYTE(jim_DMAC_BLITCON, BLITCON_ACT_ACT | BLITCON_ACT_CELL | BLITCON_ACT_MODE_4BBP );
	cursor+=4*8;
}

void plot_hexN(unsigned char i) {
	if (i <= 9)
		plot_char('0' + i);
	else
		plot_char('A' + i - 10);
}
void plot_hex8(unsigned char i) {
	plot_hexN(i >> 4);
	plot_hexN(i & 0x0F);

}
void plot_hex16(unsigned char i) {
	plot_hex8(i >> 8);
	plot_hex8(i);
}
