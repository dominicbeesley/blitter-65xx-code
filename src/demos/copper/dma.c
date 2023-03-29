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

void dma_copy_block(long dma_src_addr, long dma_dest_addr, unsigned int count)
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
	*((byte *)jim_DMAC_DMA_CTL) = DMACTL_ACT + DMACTL_HALT + DMACTL_STEP_DEST_UP + DMACTL_STEP_SRC_UP;
	//plp

}
