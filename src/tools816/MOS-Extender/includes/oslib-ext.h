#ifndef __OSLIB_EXT_H__
#define __OSLIB_EXT_H__

#include <stdint.h>

#define OEPTR32 void*

struct osword_timer_block
   {  uint8_t b [5];
   }; 

struct os_error {
	uint32_t errcode;
	char errmsg[251];
};

union os_gbpb_blk {
	 struct rw {
		uint16_t handle;
		OEPTR32 data;
		uint32_t count;
		uint32_t offset;
	} rw;
};

struct os_file_blk {
	const char *filename;
	OEPTR32 load;
	OEPTR32 exec;
	uint32_t length;
	uint32_t attributes;
};

typedef struct os_error os_error;
typedef struct osword_timer_block osword_timer_block;
typedef union os_gbpb_blk os_gbpb_blk;
typedef struct os_file_blk os_file_blk;

extern const os_error *xos_wrch(char c);
extern const os_error *xos_newl();
extern const os_error *xos_writes(const char *c);
extern const os_error *xos_word(uint8_t op, void *block);
extern const os_error *xos_find_open(const char *c, uint8_t mode, uint16_t *handle);
extern const os_error *xos_find_close(uint16_t handle);
extern const os_error *xos_bget(uint16_t handle, uint16_t *ret);
extern const os_error *xos_bput(uint16_t handle, uint8_t b);
extern const os_error *xos_gbpb(uint8_t funcode, os_gbpb_blk *blk);
extern const os_error *xos_file(uint8_t funtion, os_file_blk *blk);


#define OS_XSTR(x) __str(x)
#define OS_BRK(num, msg) \
    __asm("\tbrk\n\tdefl\t" OS_XSTR(num) "\n\tstring\t\"" msg "\"\n")


#endif