#ifndef __GLOBALS_H_
#define __GLOBALS_H_


extern char tilemap[];

#define A_LOADBUFFER 	((void *)0x3000)

#define DMA_LOADBUFFER  (0xFF0000+(long)A_LOADBUFFER)
#define	DMA_FONT_TIL	0x050000L
#define FONT_TIL_LEN	0x3200

#define DMA_OWL_TIL	(DMA_FONT_TIL+FONT_TIL_LEN)
#define OWL_TIL_LEN	378

#define DMA_AERIS	0x060000L


#define SET_DMA_ADDR(x,y) \
	{*((byte volatile *)x) = ((y) >> 16); \
	*((byte volatile *)x+1) = ((y) >> 8); \
	*((byte volatile *)x+2) = (y);}

#define SET_DMA_WORD(x,y) \
	{*((byte volatile *)x) = ((y) >> 8); \
	*((byte volatile *)x+1) = (y);}
#define SET_DMA_BYTE(x,y) \
	{*((byte volatile *)x) = (y);} 

#define GET_DMA_WORD(x) \
	(((unsigned int)(*((byte volatile *)(x+1)))) + (((unsigned int)(*((byte volatile *)(x))))<<8))

#define GET_DMA_BYTE(x) \
	(*((byte volatile *)x))

#endif

