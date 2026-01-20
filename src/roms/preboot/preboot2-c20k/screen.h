
#ifndef __SCREEN_H__
#define __SCREEN_H__

#include "types.h"

#define SCREEN_WIDTH 40
#define SCREEN_HEIGHT 25
#define SCREEN_ADDR_BAD ((char *)0xFFFF)

extern void screen_init(void);
extern void screen_print_at(coord x, coord y, char c);
extern void screen_cursor_at(coord x, coord y);
extern void screen_cursor(bool b);
extern char *screen_addr(coord x, coord y);
extern void screen_clear(coord X, coord Y, coord W, coord H, char c);

#endif