
#ifndef __SCREEN_H__
#define __SCREEN_H__

#include "types.h"
#include "coords.h"

#define SCREEN_WIDTH 40
#define SCREEN_HEIGHT 25
#define SCREEN_ADDR_BAD ((char *)0xFFFF)

extern void screen_init(void);
extern void screen_print_at(const point *p, char c);
extern void screen_cursor_at(const point *p);
extern void screen_cursor(bool b);
extern char *screen_addr(const point *p);
extern void screen_clear(const rectangle *r, char c);

#endif