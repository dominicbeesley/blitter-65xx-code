
#define BLITCON_ACT_ACT			0x80			
#define BLITCON_ACT_CELL		0x40			

								
#define BLITCON_ACT_MODE_1BBP		0x00			
#define BLITCON_ACT_MODE_2BBP		0x10			
#define BLITCON_ACT_MODE_4BBP		0x20			
#define BLITCON_ACT_MODE_8BBP		0x30			
#define BLITCON_ACT_LINE		0x08	
#define BLITCON_ACT_COLLIDE		0x04						
#define	BLITCON_ACT_WRAP		0x02

#define BLITCON_LINE_MAJOR_UPnRIGHT	0x10			
#define BLITCON_LINE_MINOR_CCW		0x20			
								
								

#define BLITCON_EXEC_A			0x01	
#define BLITCON_EXEC_B			0x02	
#define BLITCON_EXEC_C			0x04	
#define BLITCON_EXEC_D			0x08	
#define BLITCON_EXEC_E			0x10	


#define DMACTL_ACT			0x80			

#define DMACTL_EXTEND			0x20			
#define DMACTL_HALT			0x10			
#define DMACTL_STEP_DEST_NONE		0x00			
#define DMACTL_STEP_DEST_UP		0x04			
#define DMACTL_STEP_DEST_DOWN		0x08			
#define DMACTL_STEP_DEST_NOP		0x0C			
#define DMACTL_STEP_SRC_NONE		0x00			
#define DMACTL_STEP_SRC_UP		0x01			
#define DMACTL_STEP_SRC_DOWN		0x02			
#define DMACTL_STEP_SRC_NOP		0x03			

#define DMACTL2_IF			0x80			
#define DMACTL2_IE			0x02			
#define DMACTL2_PAUSE			0x01	


// NEW little-endian Word aligned API

#define CS_BLIT_BLITCON_offs		0x0
#define CS_BLIT_FUNCGEN_offs		0x1
#define CS_BLIT_MASK_FIRST_offs		0x2	
#define CS_BLIT_MASK_LAST_offs		0x3
#define CS_BLIT_WIDTH_offs		0x4	
#define CS_BLIT_HEIGHT_offs		0x5	
#define CS_BLIT_SHIFT_A_offs		0x6	
#define CS_BLIT_SHIFT_B_offs		0x7	
#define CS_BLIT_STRIDE_A_offs		0x8	
#define CS_BLIT_STRIDE_B_offs		0xA	
#define CS_BLIT_STRIDE_C_offs		0xC	
#define CS_BLIT_STRIDE_D_offs		0xE	
#define CS_BLIT_ADDR_A_offs		0x10	
#define CS_BLIT_DATA_A_offs		0x13
#define CS_BLIT_ADDR_B_offs		0x14	
#define CS_BLIT_DATA_B_offs		0x17
#define CS_BLIT_ADDR_C_offs		0x18	
#define CS_BLIT_DATA_C_offs		0x1B
#define CS_BLIT_ADDR_D_offs		0x1C	
#define CS_BLIT_ADDR_E_offs		0x20	
#define CS_BLIT_ADDR_D_MIN_offs		0x24	
#define CS_BLIT_ADDR_D_MAX_offs		0x28	


#define DMAC_SND_DATA_offs		0x20	
#define DMAC_SND_ADDR_offs		0x21	
#define DMAC_SND_PERIOD_offs		0x24	
#define DMAC_SND_LEN_offs		0x26	
#define DMAC_SND_STATUS_offs		0x28	
#define DMAC_SND_VOL_offs		0x29	
#define DMAC_SND_REPOFF_offs		0x2A	
#define DMAC_SND_PEAK_offs		0x2C	

#define DMAC_SND_MA_VOL_offs		0x2E	
#define DMAC_SND_SEL_offs		0x2F	

#define DMAC_DMA_CTL_offs		0x30	
#define DMAC_DMA_SRC_ADDR_offs		0x31	
#define DMAC_DMA_DEST_ADDR_offs		0x34	
#define DMAC_DMA_COUNT_offs		0x37	
#define DMAC_DMA_DATA_offs		0x39	
#define DMAC_DMA_CTL2_offs		0x3A	
#define DMAC_DMA_PAUSE_VAL_offs		0x3B	
#define DMAC_DMA_SEL_offs		0x3F	

#define DMAC_AERIS_CTL_offs		0x50
#define DMAC_AERIS_PROGBASE_offs	0x51

#define jim_page_DMAC			0xFEFE

#define jim_CS_BLIT_BLITCON		(0xFD00 + CS_BLIT_BLITCON_offs)
#define jim_CS_BLIT_FUNCGEN		(0xFD00 + CS_BLIT_FUNCGEN_offs)
#define jim_CS_BLIT_MASK_FIRST		(0xFD00 + CS_BLIT_MASK_FIRST_offs)
#define jim_CS_BLIT_MASK_LAST		(0xFD00 + CS_BLIT_MASK_LAST_offs)
#define jim_CS_BLIT_WIDTH		(0xFD00 + CS_BLIT_WIDTH_offs)
#define jim_CS_BLIT_HEIGHT		(0xFD00 + CS_BLIT_HEIGHT_offs)
#define jim_CS_BLIT_SHIFT_A		(0xFD00 + CS_BLIT_SHIFT_A_offs)
#define jim_CS_BLIT_SHIFT_B		(0xFD00 + CS_BLIT_SHIFT_B_offs)
#define jim_CS_BLIT_STRIDE_A		(0xFD00 + CS_BLIT_STRIDE_A_offs)
#define jim_CS_BLIT_STRIDE_B		(0xFD00 + CS_BLIT_STRIDE_B_offs)
#define jim_CS_BLIT_STRIDE_C		(0xFD00 + CS_BLIT_STRIDE_C_offs)
#define jim_CS_BLIT_STRIDE_D		(0xFD00 + CS_BLIT_STRIDE_D_offs)
#define jim_CS_BLIT_ADDR_A		(0xFD00 + CS_BLIT_ADDR_A_offs)
#define jim_CS_BLIT_DATA_A		(0xFD00 + CS_BLIT_DATA_A_offs)
#define jim_CS_BLIT_ADDR_B		(0xFD00 + CS_BLIT_ADDR_B_offs)
#define jim_CS_BLIT_DATA_B		(0xFD00 + CS_BLIT_DATA_B_offs)
#define jim_CS_BLIT_ADDR_C		(0xFD00 + CS_BLIT_ADDR_C_offs)
#define jim_CS_BLIT_DATA_C		(0xFD00 + CS_BLIT_DATA_C_offs)
#define jim_CS_BLIT_ADDR_D		(0xFD00 + CS_BLIT_ADDR_D_offs)
#define jim_CS_BLIT_ADDR_E		(0xFD00 + CS_BLIT_ADDR_E_offs)
#define jim_CS_BLIT_ADDR_D_MIN		(0xFD00 + CS_BLIT_ADDR_D_MIN_offs)
#define jim_CS_BLIT_ADDR_D_MAX		(0xFD00 + CS_BLIT_ADDR_D_MAX_offs)


#define jim_DMAC			0xFD60	
#define jim_DMAC_SND_DATA		(jim_DMAC + DMAC_SND_DATA_offs)
#define jim_DMAC_SND_ADDR		(jim_DMAC + DMAC_SND_ADDR_offs)
#define jim_DMAC_SND_PERIOD		(jim_DMAC + DMAC_SND_PERIOD_offs)
#define jim_DMAC_SND_LEN		(jim_DMAC + DMAC_SND_LEN_offs)
#define jim_DMAC_SND_STATUS		(jim_DMAC + DMAC_SND_STATUS_offs)
#define jim_DMAC_SND_VOL		(jim_DMAC + DMAC_SND_VOL_offs)
#define jim_DMAC_SND_REPOFF		(jim_DMAC + DMAC_SND_REPOFF_offs)
#define jim_DMAC_SND_PEAK		(jim_DMAC + DMAC_SND_PEAK_offs)
#define jim_DMAC_SND_SEL		(jim_DMAC + DMAC_SND_SEL_offs)
#define jim_DMAC_SND_MA_VOL		(jim_DMAC + DMAC_SND_MA_VOL_offs)
#define jim_DMAC_DMA_CTL		(jim_DMAC + DMAC_DMA_CTL_offs)
#define jim_DMAC_DMA_SRC_ADDR		(jim_DMAC + DMAC_DMA_SRC_ADDR_offs)
#define jim_DMAC_DMA_DEST_ADDR		(jim_DMAC + DMAC_DMA_DEST_ADDR_offs)
#define jim_DMAC_DMA_COUNT		(jim_DMAC + DMAC_DMA_COUNT_offs)
#define jim_DMAC_DMA_DATA		(jim_DMAC + DMAC_DMA_DATA_offs)
#define jim_DMAC_DMA_CTL2		(jim_DMAC + DMAC_DMA_CTL2_offs)
#define jim_DMAC_DMA_PAUSE_VAL		(jim_DMAC + DMAC_DMA_PAUSE_VAL_offs)
#define jim_DMAC_DMA_SEL		(jim_DMAC + DMAC_DMA_SEL_offs)

#define jim_DMAC_ADDR_D_min		(jim_DMAC + DMAC_ADDR_D_min_offs)
#define jim_DMAC_ADDR_D_max		(jim_DMAC + DMAC_ADDR_D_max_offs)

#define jim_DMAC_AERIS_CTL		(jim_DMAC + DMAC_AERIS_CTL_offs)
#define jim_DMAC_AERIS_PROGBASE		(jim_DMAC + DMAC_AERIS_PROGBASE_offs)


#define SHEILA_NULA_CTLAUX		0xFE22
#define SHEILA_NULA_PALAUX		0xFE23


#define fred_JIM_PAGE_HI		0xFCFD
#define fred_JIM_PAGE_LO		0xFCFE
#define fred_JIM_DEVNO			0xFCFF


#define JIM_DEVNO_HOG1MPAULA		0xD0
#define JIM_DEVNO_BLITTER		0xD1


#define sheila_6845_reg			0xFE00
#define sheila_6845_rw			0xFE01


#define	SHEILA_NULA_CTLAUX		0xFE22
#define	SHEILA_NULA_PALAUX		0xFE23

