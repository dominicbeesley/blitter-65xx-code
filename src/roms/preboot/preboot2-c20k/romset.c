#include <stddef.h>
#include "romset.h"
#include "spi.h"
#include "types.h"
#include "debug.h"
#include "hex.h"

unsigned long romset_get_index(int ix, romset *ret) {
	unsigned long addr;
	addr = ROMSET_BASE;
	ix++;
	while (ix) {
		spi_read_buf(ret, addr, sizeof(romset));
		if (!ret->len)
			return 0;
		ix--;
		if (ix)
			addr += 
				(unsigned long)ROMSET_SIZE 
				+ (unsigned long)((ROMDESCR_SIZE + ROM_SIZE) 
					* (unsigned long)ret->len);
	}
	return addr;
}

int romset_count() {
	int ret = 0;
	unsigned long addr = ROMSET_BASE;
	romset r;
	while (1) {
		spi_read_buf(&r, addr, sizeof(romset));
		if (!r.len)
			return ret;
		ret++;
		addr += 
			(unsigned long)ROMSET_SIZE 
			+ (unsigned long)((ROMDESCR_SIZE + ROM_SIZE) 
				* (unsigned long)r.len);
	}
}

bool romset_get_rom(int romset_ix, int ix, romset_rom_desc *rd) {
	romset r;
	unsigned long addr;


	addr = romset_get_index(romset_ix, &r);
	if (!addr)
		return 0;
	if (ix >= r.len)
		return 0;
	
	addr += (unsigned long)ROMSET_SIZE + 
			(unsigned long)ix * (unsigned long)ROMDESCR_SIZE;

	spi_read_buf(
		rd, 
		addr,
		sizeof(romset_rom_desc));
	return 1;
}


const romset_cpu_def cpudefs[] = {
	{0, "NMOS 6502"},
	{1, "65C02"},
	{2, "65816"},
	{4, "6809"},
	{5, "6309"},
	{8, "Z80"},
	{12, "68000"},
	{16, "6800"},
	{20, "RiscV"},
	{0, NULL}
};

const romset_cpu_def *romset_cpu_def_from_code(unsigned char c) {
	const romset_cpu_def *ret = &cpudefs[0];
	while (ret->label) {
		if (ret->code == c)
			return ret;
		ret++;
	}
	return NULL;
}

char romset_slot_char(unsigned char code) {
	if (code == 0xFF)
		return 'M';
	else if (code < 16)
		return hex_nyb(code);
	else
		return '?';
}