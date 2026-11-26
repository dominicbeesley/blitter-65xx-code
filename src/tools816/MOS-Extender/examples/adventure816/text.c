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

#include "oslib-ext.h"
#include "adv_globals.h"
#include "hardware816.h"
#include "types.h"

//---------------------- register read/write declarations
DECL_WR16(WR16_CS_BLIT_ADDR_A, CS_BLIT_ADDR_A)
DECL_WR16(WR16_CS_BLIT_ADDR_C, CS_BLIT_ADDR_C)
DECL_WR16(WR16_CS_BLIT_STRIDE_A, CS_BLIT_STRIDE_A)
DECL_WR16(WR16_CS_BLIT_STRIDE_D, CS_BLIT_STRIDE_D)
DECL_WR8(WR8_CS_BLIT_ADDR_A_BANK, CS_BLIT_ADDR_A+2)
DECL_WR8(WR8_CS_BLIT_ADDR_C_BANK, CS_BLIT_ADDR_C+2)
DECL_WR8(WR8_CS_BLIT_BLITCON, CS_BLIT_BLITCON)
DECL_WR8(WR8_CS_BLIT_DATA_B, CS_BLIT_DATA_B)
DECL_WR8(WR8_CS_BLIT_FUNCGEN, CS_BLIT_FUNCGEN)
DECL_WR8(WR8_CS_BLIT_HEIGHT, CS_BLIT_HEIGHT)
DECL_WR8(WR8_CS_BLIT_MASK_FIRST, CS_BLIT_MASK_FIRST)
DECL_WR8(WR8_CS_BLIT_MASK_LAST, CS_BLIT_MASK_LAST)
DECL_WR8(WR8_CS_BLIT_SHIFT_A, CS_BLIT_SHIFT_A)
DECL_WR8(WR8_CS_BLIT_WIDTH, CS_BLIT_WIDTH)
//----------------------

uint16_t cursor;

void setcursor(uint16_t addr16) {
	cursor = addr16;
}

void plot_char(char c) {
	WR8_CS_BLIT_WIDTH(4-1);
	WR8_CS_BLIT_HEIGHT(8-1);
	WR8_CS_BLIT_SHIFT_A(0x00);
	WR8_CS_BLIT_MASK_FIRST(0xFF);
	WR8_CS_BLIT_MASK_LAST(0xFF);
	WR8_CS_BLIT_ADDR_C_BANK((uint8_t)((uint32_t)DMA_SCR_SHADOW >> 16));
	WR16_CS_BLIT_ADDR_C(cursor);
	WR16_CS_BLIT_STRIDE_D(SCREEN_D_STRIDE);
	WR16_CS_BLIT_STRIDE_A(1);

	// TODO: FONT data bodge - how to find the physical address of MOS rom
	WR8_CS_BLIT_ADDR_A_BANK(0x9F);			
	WR16_CS_BLIT_ADDR_A(0x0000 + ((unsigned)(c-32)*8));
	WR8_CS_BLIT_DATA_B(0x3F);
	WR8_CS_BLIT_FUNCGEN(0xC0); // just plot data B through A
	WR8_CS_BLIT_BLITCON(BLITCON_EXEC_A | BLITCON_EXEC_C | BLITCON_EXEC_D);
	WR8_CS_BLIT_BLITCON(BLITCON_ACT_ACT | BLITCON_ACT_CELL | BLITCON_ACT_MODE_4BBP);
	cursor+=4*8;
}

void plot_hexN(uint8_t i) {
	if (i <= 9)
		plot_char('0' + i);
	else
		plot_char('A' + i - 10);
}
void plot_hex8(uint8_t i) {
	plot_hexN(i >> 4);
	plot_hexN(i & 0x0F);

}
void plot_hex16(uint16_t i) {
	plot_hex8(i >> 8);
	plot_hex8(i);
}
