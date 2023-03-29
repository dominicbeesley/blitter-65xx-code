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

