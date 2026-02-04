
#include "layout.h"
#include "hw.h"
#include "hardware.h"
#include <string.h>
#include "debug.h"

romloc c20k_layout[] = {
	{0x0, 0x7E00, ROMLOC_FLAGS_MAP0|ROMLOC_FLAGS_BBRAM},
	{0x1, 0x9E00, ROMLOC_FLAGS_MAP0|ROMLOC_FLAGS_FLASH},
	{0x2, 0x7E40, ROMLOC_FLAGS_MAP0|ROMLOC_FLAGS_BBRAM},
	{0x3, 0x9E40, ROMLOC_FLAGS_MAP0|ROMLOC_FLAGS_FLASH},
	{0x4, 0x7E80, ROMLOC_FLAGS_MAP0|ROMLOC_FLAGS_BBRAM},
	{0x5, 0x9E80, ROMLOC_FLAGS_MAP0|ROMLOC_FLAGS_FLASH},
	{0x6, 0x7EC0, ROMLOC_FLAGS_MAP0|ROMLOC_FLAGS_BBRAM},
	{0x7, 0x9EC0, ROMLOC_FLAGS_MAP0|ROMLOC_FLAGS_FLASH},
	{0x8, 0x7F00, ROMLOC_FLAGS_MAP0|ROMLOC_FLAGS_BBRAM|ROMLOC_FLAGS_MOS|ROMLOC_FLAGS_PREBOOT},
	{0x9, 0x9F00, ROMLOC_FLAGS_MAP0|ROMLOC_FLAGS_FLASH|ROMLOC_FLAGS_MOS},
	{0xA, 0x7F40, ROMLOC_FLAGS_MAP0|ROMLOC_FLAGS_BBRAM},
	{0xB, 0x9F40, ROMLOC_FLAGS_MAP0|ROMLOC_FLAGS_FLASH},
	{0xC, 0x7F80, ROMLOC_FLAGS_MAP0|ROMLOC_FLAGS_BBRAM},
	{0xD, 0x9F80, ROMLOC_FLAGS_MAP0|ROMLOC_FLAGS_FLASH},
	{0xE, 0x1F00, ROMLOC_FLAGS_MAP0|ROMLOC_FLAGS_BBRAM|ROMLOC_FLAGS_PREBOOT},
	{0xF, 0x9FC0, ROMLOC_FLAGS_MAP0|ROMLOC_FLAGS_FLASH},

	{0x0, 0x7C00, ROMLOC_FLAGS_MAP1|ROMLOC_FLAGS_BBRAM},
	{0x1, 0x9C00, ROMLOC_FLAGS_MAP1|ROMLOC_FLAGS_FLASH},
	{0x2, 0x7C40, ROMLOC_FLAGS_MAP1|ROMLOC_FLAGS_BBRAM},
	{0x3, 0x9C40, ROMLOC_FLAGS_MAP1|ROMLOC_FLAGS_FLASH},
	{0x4, 0x7C80, ROMLOC_FLAGS_MAP1|ROMLOC_FLAGS_BBRAM},
	{0x5, 0x9C80, ROMLOC_FLAGS_MAP1|ROMLOC_FLAGS_FLASH},
	{0x6, 0x7CC0, ROMLOC_FLAGS_MAP1|ROMLOC_FLAGS_BBRAM},
	{0x7, 0x9CC0, ROMLOC_FLAGS_MAP1|ROMLOC_FLAGS_FLASH},
	{0x8, 0x7D00, ROMLOC_FLAGS_MAP1|ROMLOC_FLAGS_BBRAM|ROMLOC_FLAGS_MOS},
	{0x9, 0x9D00, ROMLOC_FLAGS_MAP1|ROMLOC_FLAGS_FLASH|ROMLOC_FLAGS_MOS},
	{0xA, 0x7D40, ROMLOC_FLAGS_MAP1|ROMLOC_FLAGS_BBRAM},
	{0xB, 0x9D40, ROMLOC_FLAGS_MAP1|ROMLOC_FLAGS_FLASH},
	{0xC, 0x7D80, ROMLOC_FLAGS_MAP1|ROMLOC_FLAGS_BBRAM},
	{0xD, 0x9D80, ROMLOC_FLAGS_MAP1|ROMLOC_FLAGS_FLASH},
	{0xE, 0x1F40, ROMLOC_FLAGS_MAP1|ROMLOC_FLAGS_BBRAM},
	{0xF, 0x9DC0, ROMLOC_FLAGS_MAP1|ROMLOC_FLAGS_FLASH},

	{0, 0, 0}
};


//TODO: detect at boot
romloc *cur_layout  = &c20k_layout[0];

#define FLASH_SECTOR_SIZE 	0x10
#define FLASH_BASE 			0x8000

void flash_jim55(void) {
	jim_page(FLASH_BASE + 0x55);
}

void flash_jim2AAAeq55(void) {
	jim_page(FLASH_BASE + 0x2A);
	poke(JIM + 0xAA, 0x55);
}

void flash_jim5555eqAAthen2A(void) {
	flash_jim55();
	poke(JIM + 0x55, 0xAA);
	flash_jim2AAAeq55();
}

void flash_cmd(unsigned char cmd) {
	flash_jim5555eqAAthen2A();
	flash_jim55();
	poke(JIM + 0x55, cmd);
}

void flash_wait(void) {
	unsigned a = peek(JIM);
	while (a != peek(JIM)) ;
}

void flash_sector_erase(unsigned page) {
	flash_cmd(0x80);
	flash_jim5555eqAAthen2A();
	jim_page(page);
	poke(JIM + 0, 0x30);
	flash_wait();
}

//These assume running in MOS area so we are safe to tickle the Flash EEPROM
bool erase_slot(romloc *rl) {
	unsigned short page;
	unsigned short pagectr;

		page = rl->page;
		pagectr = 0;

	if ((rl->flags & ROMLOC_FLAGS_FLASH)!=0) {
		while (pagectr < 0x40) {
			flash_sector_erase(page);
			page += FLASH_SECTOR_SIZE;
			pagectr += FLASH_SECTOR_SIZE;
		}
		return 1;
	} else {
		while (pagectr < 0x40) {
			jim_page(page);

			memset((void *)JIM, 0xFF, 0x100);

			page++;
			pagectr++;
		}
		return 1;
	}

}

romloc *layout_find(unsigned char slot, unsigned char flags) {
	romloc *ret = cur_layout;
	while (ret && ret->flags) {
		if (
			(slot == SLOT_ANY || ret->slot == slot) &&
			(ret->flags & flags))
			return ret;
		ret++;
	}

	return NULL;
}