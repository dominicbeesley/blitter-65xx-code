#ifndef __LAYOUT_H__
#define __LAYOUT_H__
#include "types.h"
#include "romset.h"

#define ROMLOC_FLAGS_MAP0		0x01
#define ROMLOC_FLAGS_MAP1		0x02
#define ROMLOC_SYS				0x08
#define ROMLOC_FLAGS_PREBOOT 	0x10
#define ROMLOC_FLAGS_BBRAM	 	0x80
#define ROMLOC_FLAGS_FLASH		0x40
#define ROMLOC_FLAGS_MOS		0x20

#define SLOT_ANY				0xAA

typedef struct romloc {
	unsigned char slot;
	unsigned int page;
	unsigned char flags;
} romloc;

extern const romloc *cur_layout;

extern const romloc *layout_find(unsigned char slot, unsigned char flags, unsigned char notflags);
extern const romloc *layout_find_romset(const romset_rom_desc *rom, unsigned char mapflags, unsigned char notflags);

extern bool erase_slot(const romloc *loc);
extern bool write_slot_from_spi(const romloc *rl, unsigned long spiaddr);

#endif