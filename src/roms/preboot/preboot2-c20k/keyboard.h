#ifndef __KEYBOARD_H__
#define __KEYBOARD_H__

#define KEYCODE_UP 		0x8B
#define KEYCODE_DOWN	0x8A
#define KEYCODE_LEFT	0x88
#define KEYCODE_RIGHT	0x89


extern unsigned char keyb_check_pressed(unsigned char); //check if key code is depressed
extern unsigned char keyb_scan(unsigned char); //check for first key after

extern unsigned char keyb_code2ascii(unsigned char code, unsigned char flags);

extern void keyb_init(void);

#endif