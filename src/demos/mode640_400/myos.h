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

//all return X
extern unsigned char my_os_byteAXY(unsigned char A, unsigned char X, unsigned char Y);
extern unsigned char my_os_byteAX(unsigned char A, unsigned char X);
extern unsigned char my_os_byteA(unsigned char A);

extern void __fastcall__ my_os_OSCLI(const char *cmd);


#define OSFIND_OPENIN	0x40
#define OSFIND_CLOSE	0x00

extern unsigned char __fastcall__ my_os_FIND_name(unsigned char function, const char *filename);
extern void __fastcall__ my_os_FIND(unsigned char function, unsigned char Y);

#define OSGBPB_READ	0x04
extern unsigned char __fastcall__ my_os_GBPB(unsigned char fn, void *blk);

#endif