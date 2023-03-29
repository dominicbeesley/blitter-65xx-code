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
#include "dma.h"


void dma_clear(long dma_dest_addr, unsigned char value, unsigned int count)
{
	count--;
	*((byte *)jim_DMAC_DMA_SEL) = 0;
	*((byte *)jim_DMAC_DMA_COUNT+0) = count >> 8;
	*((byte *)jim_DMAC_DMA_COUNT+1) = count;
	*((byte *)jim_DMAC_DMA_DATA) = value;
	*((byte *)jim_DMAC_DMA_DEST_ADDR+0) = dma_dest_addr >> 16;
	*((byte *)jim_DMAC_DMA_DEST_ADDR+1) = dma_dest_addr >> 8;
	*((byte *)jim_DMAC_DMA_DEST_ADDR+2) = dma_dest_addr;
	*((byte *)jim_DMAC_DMA_CTL) = DMACTL_ACT + DMACTL_HALT + DMACTL_STEP_DEST_UP + DMACTL_STEP_SRC_NOP;

}

void dma_copy_block(unsigned char halt, long dma_src_addr, long dma_dest_addr, unsigned int count)
{
	//php
	//sei
	count--;
	*((byte *)jim_DMAC_DMA_SEL) = 0;
	*((byte *)jim_DMAC_DMA_COUNT+0) = count >> 8;
	*((byte *)jim_DMAC_DMA_COUNT+1) = count;
	*((byte *)jim_DMAC_DMA_SRC_ADDR+0) = dma_src_addr >> 16;
	*((byte *)jim_DMAC_DMA_SRC_ADDR+1) = dma_src_addr >> 8;
	*((byte *)jim_DMAC_DMA_SRC_ADDR+2) = dma_src_addr;
	*((byte *)jim_DMAC_DMA_DEST_ADDR+0) = dma_dest_addr >> 16;
	*((byte *)jim_DMAC_DMA_DEST_ADDR+1) = dma_dest_addr >> 8;
	*((byte *)jim_DMAC_DMA_DEST_ADDR+2) = dma_dest_addr;
	*((byte *)jim_DMAC_DMA_CTL) = DMACTL_ACT + ((halt)?DMACTL_HALT:0) + DMACTL_STEP_DEST_UP + DMACTL_STEP_SRC_UP;
	//plp

}

unsigned char dma_act(void) {
	return (*((byte *)jim_DMAC_DMA_CTL)) & DMACTL_ACT;
}
