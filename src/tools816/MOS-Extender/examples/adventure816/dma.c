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


typedef unsigned char byte;
#include "hardware816.h"
#include "dma.h"


void dma_clear(long dma_dest_addr, unsigned char value, unsigned int count)
{
	count--;
	*((volatile byte *)CS_DMA_SEL) = 0;
	*((volatile unsigned int *)CS_DMA_COUNT) = count;
	*((volatile byte *)CS_DMA_DATA) = value;
	*((volatile unsigned long *)CS_DMA_DEST_ADDR) = dma_dest_addr;
	*((volatile byte *)CS_DMA_CTL) = DMACTL_ACT + DMACTL_HALT + DMACTL_STEP_DEST_UP + DMACTL_STEP_SRC_NOP;

}

void dma_copy_block(unsigned char halt, long dma_src_addr, long dma_dest_addr, unsigned int count)
{
	//php
	//sei
	count--;
	*((volatile byte *)CS_DMA_SEL) = 0;
	*((volatile unsigned int *)CS_DMA_COUNT) = count;
	*((volatile unsigned long *)CS_DMA_SRC_ADDR) = dma_src_addr;
	*((volatile unsigned long *)CS_DMA_DEST_ADDR) = dma_dest_addr;
	*((volatile byte *)CS_DMA_CTL) = DMACTL_ACT + ((halt)?DMACTL_HALT:0) + DMACTL_STEP_DEST_UP + DMACTL_STEP_SRC_UP;
	//plp

}

unsigned char dma_act(void) {
	return (*((volatile byte *)CS_DMA_CTL)) & DMACTL_ACT;
}
