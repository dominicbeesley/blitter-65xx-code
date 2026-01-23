#ifndef __ROMSET_H__
#define __ROMSET_H__

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


extern unsigned long romset_get_index(int ix, romset *ret);
extern int romset_count();
extern const romset_cpu_def *romset_cpu_def_from_code(unsigned char c);

extern const romset_cpu_def cpudefs[];



#endif