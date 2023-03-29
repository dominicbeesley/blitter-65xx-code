; MIT License
; 
; Copyright (c) 2023 Dossytronics
; https://github.com/dominicbeesley/blitter-65xx-code
; 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.



		.importzp	sp, sreg
		.autoimport	on


		.export 	_my_os_byteAXY
		.export		_my_os_byteAXYretX
		.export 	_my_os_byteAX
		.export 	_my_os_byteA
		.export		_my_os_OSCLI
		.export		_my_os_FIND
		.export		_my_os_FIND_name
		.export		_my_os_GBPB


		.include	"oslib.inc"

		.code

		;extern unsigned char my_os_byteAXY(unsigned char A, unsigned char X, unsigned char y);
_my_os_byteAXYretX:
_my_os_byteAXY:	sta	sreg				; Y
		ldy	#0
		lda	(sp),y
		tax					; X
		iny
		lda	(sp),y				; A
		ldy	sreg
		jsr	OSBYTE
		txa
		ldx	#0
		jmp	incsp2				; restore stack

		;extern unsigned void my_os_byteAXY(unsigned char A, unsigned char X);
_my_os_byteAX:	sta	sreg				; X
		ldy	#0
		lda	(sp),y
		ldx	sreg				; X
		jsr	OSBYTE
		txa
		ldx	#0
		jmp	incsp1				; restore stack

		;extern char my_os_byteAXY(unsigned char A, unsigned char X);
_my_os_byteA:	jsr	OSBYTE
		txa
		ldx	#0
		rts

_my_os_OSCLI:	pha
		txa
		tay
		pla
		tax
		jmp	OSCLI

_my_os_FIND_name:
		pha
		ldy	#0
		lda	(sp),y
		sta	sreg
		txa
		tay
		pla
		tax
		lda	sreg
		jsr	OSFIND
		jmp	incsp1

_my_os_FIND:
		pha
		ldy	#0
		lda	(sp),y
		sta	sreg
		pla
		tay
		lda	sreg
		jsr	OSFIND
		jmp	incsp1


_my_os_GBPB:	
		pha
		ldy	#0
		lda	(sp),y
		sta	sreg
		txa
		tay
		pla
		tax
		lda	sreg
		jsr	OSGBPB
		lda	#0
		bcc	@s1
		lda	#$FF
@s1:
		jmp	incsp1
