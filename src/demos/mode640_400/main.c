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

#include <stdio.h>
#include <oslib/os.h>
#include <oslib/osfile.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>

#include "hardware.h"
#include "myos.h"
#include "build/pics.h"

const char mo6845[]  = {
	0x7f,				// 0 Horizontal Total	 =128
	0x50,				// 1 Horizontal Displayed =80
	0x62,				// 2 Horizontal Sync	 =&62
	0x28,				// 3 HSync Width+VSync	 =&28  VSync=2, HSync Width=8
	0x26,				// 4 Vertical Total	 =38
	0x00,				// 5 Vertial Adjust	 =0
	0x20,				// 6 Vertical Displayed	 =32
	0x22,				// 7 VSync Position	 =&22
	0x01,				// 8 Interlace+Cursor	 =&01  Cursor=0, Display=0, Interlace=Sync
	0x07,				// 9 Scan Lines/Character =8
	0x67,				// 10 Cursor Start Line	  =&67	Blink=On, Speed=1/32, Line=7
	0x08				// 11 Cursor End Line	  =8
};


void error(const char *str) {
	my_os_OSCLI("BLTURBO L00\r");	
	puts(str);
	exit(-1);
}

void SET_PAG(unsigned int p) {
	*((unsigned char *)fred_JIM_PAGE_LO) = p & 0xFF;
	*((unsigned char *)fred_JIM_PAGE_HI) = p >> 8;

}

void write_6845_12_13(unsigned int x) {
	*((unsigned char *)sheila_6845_reg) = 12;
	*((unsigned char *)sheila_6845_rw) = x >> 8;
	*((unsigned char *)sheila_6845_reg) = 13;
	*((unsigned char *)sheila_6845_rw) = x & 0xFF;
}

typedef struct t_gbpb {
	unsigned char handle;
	long int addr;
	long int num;
	long int fileptr;
} t_gbpb;

t_gbpb gbpb;

char *filename="P.01\r";

void main(void) {

	unsigned char ch;
	int pag;
	int i, pic, k;

	// *tv 255 0
	my_os_byteAXY(0x90, 255, 0);

	OSWRCH(22);
	OSWRCH(0);

	my_os_OSCLI("BLTURBO LFF\r");

	//select blitter hardware
	*((unsigned char *)0xEE) = JIM_DEVNO_BLITTER;
	*((unsigned char *)fred_JIM_DEVNO) = JIM_DEVNO_BLITTER;

	pic = 1;
	while (1) {

		filename[2] = '0' + ((pic >> 4) & 0xF);
		filename[3] = '0' + (pic & 0xF);

		ch = my_os_FIND_name(OSFIND_OPENIN, filename);

		if (ch == 0)
			error("Cannot open file");


		pag = 0xFF00;
		i = 0;
		while (i < 0x80) {
			SET_PAG(pag++);

			gbpb.handle = ch;
			gbpb.addr = 0xFFFFFD00;
			gbpb.num = 256;

			my_os_GBPB(OSGBPB_READ, (void *)&gbpb);

			i++;
		}

		my_os_FIND(OSFIND_CLOSE, ch);

		i = 0;
		while (1) {
			my_os_byteA(19); //wait vsync
			if (i) {
				write_6845_12_13(0x0000);
			} else {
				write_6845_12_13(0x4000 >> 3);
			}

			i = 1 - i;

			k = my_os_byteAXY(0x81, 0, 0);

			if (k == 32) {
				my_os_byteA(19); //wait vsync
			} else if (k == 'N' || k == 'n') {
				break;
			}
		}

		pic = pic + 1;
		if (pic > N_PICS)
			pic = 1;
	}

}


