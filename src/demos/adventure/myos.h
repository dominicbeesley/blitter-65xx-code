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

#ifndef _MYOS_H_
#define _MYOS_H_

extern void my_os_byteAXY(unsigned char A, unsigned char X, unsigned char Y);
extern void my_os_byteAX(unsigned char A, unsigned char X);
extern void my_os_byteA(unsigned char A);

extern unsigned char my_os_byteAXYretX(unsigned char A, unsigned char X, unsigned char Y);

extern unsigned char my_os_find_open(unsigned char A, const char *ptr);
extern void my_os_find_close(unsigned Y);

extern long my_os_gbpb_read (unsigned char file, void *data, long size);

extern void my_os_brk(unsigned char n, const char *s);




#endif