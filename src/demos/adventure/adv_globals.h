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

#define RLE_LOADBUF	((unsigned char *)0x7E00)
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
#define DMA_COLL_SPR	0x090000L

#define FRONT_SPR_MO	(8*24)				// mask offset from start of spr
#define FRONT_SPR_SZ	((2*24)+(8*24))			// size of spr
#define FRONT_SPR_MASK_BYTES_PER_LINE 2

#define COLL_SPR_MO	(8*24)				// mask offset from start of spr
#define COLL_SPR_SZ	((2*24)+(8*24))			// size of spr
#define COLL_SPR_MASK_BYTES_PER_LINE 2

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

#define TILE_MAP_MAX_W 30
#define TILE_MAP_MAX_H 30

#define TILE_MAP_LAYER_SZ 	(TILE_MAP_MAX_W*TILE_MAP_MAX_H)				//tile map front offset
#define TILE_MAP_SZ		(TILE_MAP_LAYER_SZ*3)
#define A_TILE_MAP		tilemap
#define DMA_TILE_MAP	0x080000L

#define LAYER_BACK 0
#define LAYER_FRONT 1
#define LAYER_COLL 2

#define COLOBJ_FLAG_NOCOL 0x80
#define COLOBJ_FLAG_BORDER_NORTH 0x01

#define SET_DMA_BYTE(x,y) \
	{*((byte volatile *)x) = (y);} 


#define GET_DMA_BYTE(x) \
	(*((byte volatile *)x))

//WARNING: sets a 32 bit address - may have consequences
#define SET_DMA_ADDR(x,y) \
	{*((unsigned long volatile *)x) = y;}

#define SET_DMA_WORD(x,y) \
	{*((unsigned volatile *)x) = y;}

#define GET_DMA_WORD(x) \
	(*((unsigned volatile *)x))



#endif

