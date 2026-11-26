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


#include "hardware816.h"
#include "dma.h"
#include "types.h"

//---------------------- register read/write declarations
DECL_WR8(WR8_CS_DMA_SEL, CS_DMA_SEL)
DECL_WR16(WR16_CS_DMA_COUNT, CS_DMA_COUNT)
DECL_WR8(WR8_CS_DMA_DATA, CS_DMA_DATA)
DECL_WR32(WR32_CS_DMA_DEST_ADDR, CS_DMA_DEST_ADDR)
DECL_WR32(WR32_CS_DMA_SRC_ADDR, CS_DMA_SRC_ADDR)
DECL_WR8(WR8_CS_DMA_CTL, CS_DMA_CTL)

DECL_RD8(RD8_CS_DMA_CTL, CS_DMA_CTL)
//----------------------


void dma_clear(LPTR dma_dest_addr, uint8_t value, uint16_t count)
{
	count--;
	WR8_CS_DMA_SEL(0);
	WR16_CS_DMA_COUNT(count);
	WR8_CS_DMA_DATA(value);
	WR32_CS_DMA_DEST_ADDR((long)dma_dest_addr);
	WR8_CS_DMA_CTL(DMACTL_ACT + DMACTL_HALT + DMACTL_STEP_DEST_UP + DMACTL_STEP_SRC_NOP);

}

void dma_copy_block(BOOL halt, LPTR dma_src_addr, LPTR dma_dest_addr, uint16_t count)
{
	//php
	//sei
	count--;
	WR8_CS_DMA_SEL(0);
	WR16_CS_DMA_COUNT(count);
	WR32_CS_DMA_SRC_ADDR((long)dma_src_addr);
	WR32_CS_DMA_DEST_ADDR((long)dma_dest_addr);
	WR8_CS_DMA_CTL(DMACTL_ACT + ((halt)?DMACTL_HALT:0) + DMACTL_STEP_DEST_UP + DMACTL_STEP_SRC_UP);
	//plp

}

BOOL dma_act(void) {
	return RD8_CS_DMA_CTL() & DMACTL_ACT;
}
