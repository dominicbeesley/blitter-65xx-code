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

unsigned char adval8(unsigned int channel){
	asm("	ldy	#%o", channel);
	asm("	lda	(sp),y");
	asm("	tax");
	asm("	iny");
	asm("	lda	(sp),y");
	asm("	tay");
	asm("   lda	#$80");
	asm("	jsr	$FFF4");
	asm("	tya");
	asm("	eor	#$FF");
	asm("	clc");
	asm("	adc	#$80");
	asm("	cmp	#$80");
	asm("	ror	a");
	asm("	cmp	#$80");
	asm("	ror	a");
	asm("	cmp	#$80");
	asm("	ror	a");
	asm("	cmp	#$80");
	asm("	ror	a");
	asm("	cmp	#$80");
	asm("	ror	a");
	asm("	ldx	#0");
}
