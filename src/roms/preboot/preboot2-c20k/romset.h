#ifndef __ROMSET_H__
#define __ROMSET_H__

#include "types.h"

typedef struct romset_struct_romset romset;

struct romset_struct_romset {
	unsigned char len;
	unsigned char cpu;
	char title[32];	
};

#define ROMSET_BASE 0x720000
#define ROMSET_SIZE 64
#define ROMDESCR_SIZE 64
#define ROM_SIZE 16384


typedef struct romset_cpu_def {
	unsigned char code;
	char *label;
} romset_cpu_def;

typedef struct romset_rom_desc {
	unsigned char slot;
	unsigned char ext_type;
	unsigned char rom_type;
	unsigned char cpu;
	char title[32];
	unsigned int crc;
} romset_rom_desc;

extern unsigned long romset_get_index(int ix, romset *ret);
extern bool romset_get_rom(int romset_ix, int ix, romset_rom_desc *rd);
extern int romset_count();
extern const romset_cpu_def *romset_cpu_def_from_code(unsigned char c);
extern char romset_slot_char(unsigned char code);

extern const romset_cpu_def cpudefs[];



#endif