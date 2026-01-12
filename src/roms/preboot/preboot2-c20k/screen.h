
#ifndef __SCREEN_H__
#define __SCREEN_H__

#define SCREEN_WIDTH 40
#define SCREEN_HEIGHT 25
#define SCREEN_ADDR_BAD ((char *)0xFFFF)

typedef signed char screen_coord;
typedef char screen_bool;

extern void screen_init(void);
extern void screen_print_at(screen_coord x, screen_coord y, char c);
extern void screen_cursor_at(screen_coord x, screen_coord y);
extern void screen_cursor(screen_bool b);


#endif