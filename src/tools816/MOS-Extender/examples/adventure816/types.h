#ifndef __TYPES_H__
#define __TYPES_H__

#include <stdint.h>

#define LPTR void*

#define BOOL uint8_t
#define TRUE 1
#define FALSE 0

#define SET_DMA_BYTE(x,y) \
	{*((uint8_t volatile *)x) = (y);} 

#define GET_DMA_BYTE(x) \
	(*((uint8_t volatile *)x))

//WARNING: sets a 32 bit address - may have consequences
#define SET_DMA_ADDR(x,y) \
	{*((uint32_t volatile *)x) = (uint32_t)y;}

#define SET_DMA_WORD(x,y) \
	{*((uint16_t volatile *)x) = y;}

#define GET_DMA_WORD(x) \
	(*((uint16_t volatile *)x))

#define ADD_DMA_WORD(x, y) \
	{*((uint16_t volatile *)x) += y;}

#endif