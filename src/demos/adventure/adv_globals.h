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


#ifndef __ADV_GLOBALS_H_
#define __ADV_GLOBALS_H_


extern char tilemap[];

#define RLE_LOADBUF	((unsigned char *)0x3000)
#define RLE_LOADBUFSZ   256

#define A_LOADBUFFER 	((void *)0x4000)

#define DMA_LOADBUFFER  (0xFF0000+(long)A_LOADBUFFER)
#define	DMA_CHARAC_SPR	0x050000L
#define CHARAC_SZ_X	16
#define CHARAC_SZ_Y	24
#define CHARAC_SPR_MO	(8*24)				// mask offset from start of spr
#define CHARAC_SPR_SZ	((2*24)+(8*24))			// size of spr
#define CHARAC_COL	16				// index of shadow/collision mask

#define	DMA_BACK_SPR	0x010000L
#define DMA_FRONT_SPR	0x020000L
#define FRONT_SPR_MO	(8*24)				// mask offset from start of spr
#define FRONT_SPR_SZ	((2*24)+(8*24))			// size of spr
#define FRONT_SPR_MASK_BYTES_PER_LINE 2

#define DMA_SPR_SAVE	0x030000L			// save area for sprites bitmaps
#define SPR_SAVE_MAX	80				// max sprites that can be saved per frame

#define DMA_SCR_SHADOW	0x040000L			// draw to this screen then blit to SYS
//#define DMA_SCR_SHADOW	0xFF3000L			// draw to this screen then blit to SYS

#define ROOM_SZ_Y	10
#define ROOM_SZ_X	10


#define TILE_X_SZ	16
#define TILE_Y_SZ	24
#define TILE_B_STRIDE	8
#define SCREEN_SZ_X	160
#define SCREEN_SZ_Y	(TILE_Y_SZ*ROOM_SZ_Y)
#define SCREEN_D_STRIDE 640
#define TILE_MAP_STRIDE 30
#define TILE_MAP_HEIGHT 30
#define TILE_BYTES	8*24				//bytes per tile sprite (no mask)
#define TILE_SCR_ADDR_STRIDE_X	((TILE_X_SZ >> 1)*8)	//bytes on screen (adjusted for cells)
#define TILE_SCR_ADDR_STRIDE_Y	(640+640)		//bytes on screen (adjusted for cells) - from end of one line to start of next

#define COL_X_MAX	16				//smaller of TILE_X_SZ and CHARAC_SZ_X
#define COL_Y_MAX	24				//smaller of TILE_Y_SZ and CHARAC_SZ_Y

// 	; sprite save area block offsets
// o_spr_save_sava	equ	0
// o_spr_save_scra	equ	3
// o_spr_save_w	equ	5
// o_spr_save_h	equ	6
// o_spr_save_l	equ	7

#define TILE_MAP_LAYER_SZ 	(TILE_MAP_STRIDE*TILE_MAP_HEIGHT)				//tile map front offset
#define TILE_MAP_SZ		(TILE_MAP_LAYER_SZ*2)
#define A_TILE_MAP		tilemap
#define DMA_TILE_MAP		0x080000L


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
	(((unsigned int)(*((byte volatile *)(x+1)))) | (((unsigned int)(*((byte volatile *)(x))))<<8))

#define GET_DMA_BYTE(x) \
	(*((byte volatile *)x))

#endif

extern int tile_off_x;
extern int tile_off_y;

#define A_TILE_MAP_WITH_OFFS \
	(((unsigned int)A_TILE_MAP + (unsigned int)tile_off_x + (TILE_MAP_STRIDE*(unsigned int)tile_off_y)))