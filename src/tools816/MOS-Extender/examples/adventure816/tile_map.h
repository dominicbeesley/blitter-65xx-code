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

#include <stdint.h>

#include "mapdef.h"

extern uint8_t get_tile_at(uint8_t layer, int8_t x, int8_t y);
extern void draw_front(uint8_t flags);
extern void draw_front_nosave(uint8_t flags);
extern void draw_front_collide(uint8_t x, uint8_t y, uint8_t tileno, uint8_t colourB);
extern uint16_t colcheck_at(int16_t old_x, int16_t old_y, int16_t new_x, int16_t new_y);

extern void draw_map(uint8_t *map);
extern void set_offset(int16_t x, int16_t y);
extern void set_map(mapdef_t *map);


extern int16_t tile_off_x;
extern int16_t tile_off_y;

extern uint8_t *map_ptr;
extern uint8_t *map_ptr_offset;
extern uint8_t map_width;
extern uint8_t map_height;

extern uint8_t room_exit;

#endif