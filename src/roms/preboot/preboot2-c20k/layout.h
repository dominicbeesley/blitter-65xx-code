#ifndef __LAYOUT_H__
#define __LAYOUT_H__
#include "types.h"

#define ROMLOC_FLAGS_MAP0		0x01
#define ROMLOC_FLAGS_MAP1		0x02
#define ROMLOC_SYS				0x08
#define ROMLOC_FLAGS_PREBOOT 	0x10
#define ROMLOC_FLAGS_BBRAM	 	0x80
#define ROMLOC_FLAGS_FLASH		0x40
#define ROMLOC_FLAGS_MOS		0x20


typedef struct romloc {
	unsigned char slot;
	unsigned int page;
	unsigned char flags;
} romloc;

extern romloc *cur_romset;

extern bool erase_slot(romloc *loc);

#endif