#ifndef _DMA_H_
#define _DMA_H_

extern void dma_copy_block(long dma_src_addr, long dma_dest_addr, unsigned int countminus1);
extern void dma_clear(long dma_dest_addr, unsigned char value, unsigned int countminus1);

#endif