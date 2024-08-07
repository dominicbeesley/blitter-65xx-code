/*
MIT License

Copyright (c) 2023 Dossytronics
https://github.com/dominicbeesley/blitter-65xx-code

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#ifndef _TILE_MAP_H
#define _TILE_MAP_H

#include "mapdef.h"

extern unsigned char get_tile_at(unsigned char layer, unsigned char x, unsigned char y);
extern void draw_front(unsigned char flags);
extern void draw_front_nosave(unsigned char flags);
extern void draw_front_collide(unsigned char x, unsigned char y, unsigned char tileno, unsigned char colourB);
extern unsigned colcheck_at(signed old_x, signed old_y, signed new_x, signed new_y);

extern void draw_map(void *addr);
extern void set_offset(int x, int y);
extern void set_map(mapdef_t *map);


extern int tile_off_x;
extern int tile_off_y;

extern unsigned char *map_ptr;
extern unsigned char *map_ptr_offset;
extern unsigned char map_width;
extern unsigned char map_height;

extern unsigned char room_exit;

#endif