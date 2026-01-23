#include <stddef.h>
#include "romset.h"
#include "spi.h"

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
