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

#ifndef __SPRITE_H_
#define __SPRITE_H_

extern void spr_plotXY(signed int x, signed int y, unsigned char w, unsigned char h);

extern void spr_restore_init();
extern void spr_restore();
extern void spr_save_start();

extern void spr_plot(unsigned char w, unsigned char h, unsigned char execmask, unsigned int scr_dma_addr16);
extern void spr_save_and_plot(unsigned char w, unsigned char h, unsigned char execmask, unsigned int scr_dma_addr16);
extern void charac_spr_plot(signed int x, signed int y, unsigned char frameno);
extern void charac_spr_plot_start(void);
extern void spr_init(void);


#endif