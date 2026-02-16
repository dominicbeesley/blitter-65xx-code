#ifndef __ROMSET_H__
#define __ROMSET_H__

#include "preboot.h"
#include "types.h"

typedef struct romset_struct_romset romset;

struct romset_struct_romset {
	unsigned char len;
	unsigned char cpu;
	char title[32];	
	unsigned long ident;
};

#define ROMSET_BASE (PREBOOT_BASE + 0x020000)
#define ROMSET_SIZE 64
#define ROMDESCR_SIZE 64
#define ROM_SIZE 16384

#define ROM_EXTTYPE_ROM 1
#define ROM_EXTTYPE_MOS 2

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
extern unsigned long romset_get_rom(int romset_ix, int ix, romset_rom_desc *rd);
extern int romset_count();
extern const romset_cpu_def *romset_cpu_def_from_code(unsigned char c);
extern char romset_slot_char(unsigned char code);
extern char* romset_rom_type_string(char *buf, unsigned char ext_type, unsigned char rom_type);

extern const romset_cpu_def cpudefs[];



#endif