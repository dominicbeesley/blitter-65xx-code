; 
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

		.importzp	sp, sreg, ptr1
		.autoimport	on


		.export 	_my_os_byteAXY
		.export		_my_os_byteAXYretX
		.export 	_my_os_byteAX
		.export 	_my_os_byteA


		.export		_my_os_find_open
		.export		_my_os_find_close
		.export		_my_os_brk
		.export		_my_os_gbpb_read

		.include	"oslib.inc"

		.code

		;extern void my_os_byteAXY(unsigned char A, unsigned char X, unsigned char y);
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
		jmp	incsp2				; restore stack

		;extern void my_os_byteAXY(unsigned char A, unsigned char X);
_my_os_byteAX:	sta	sreg				; X
		ldy	#0
		lda	(sp),y
		ldx	sreg				; X
		jsr	OSBYTE
		jmp	incsp1				; restore stack

		;extern void my_os_byteAXY(unsigned char A, unsigned char X);
_my_os_byteA:	jmp	OSBYTE

		;extern unsigned char my_os_find_open(unsigned char A, const char *ptr);
_my_os_find_open:
		sta	ptr1				; filename ptr
		stx	ptr1+1
		ldy	#0

@lp:		lda	(ptr1),Y
		beq	@s1
		sta	$100,Y
		iny
		bne	@lp
@s1:		lda	#$0D
		sta	$100,Y

		ldy	#0
		lda	(sp),y				; A

		ldy	#$01
		ldx	#$00
		jsr	OSFIND
		ldx	#$00
		jmp	incsp1

		;extern void my_os_find_close(unsigned Y);
_my_os_find_close:
		tay
		txa
		jmp	OSFIND

		;extern void my_os_brk(unsigned char n, const char *s);
_my_os_brk:	pha
		txa
		pha
		sei		
		ldy	#0
		sty	$700
		lda	(sp),Y
		sta	$701
		pla
		sta	ptr1+1
		pla
		sta	ptr1
@lp:		lda	(ptr1),Y
		sta	$702,Y
		iny
		cmp	#0
		bne	@lp
		jmp	$700

		.DATA
osgbpb_block:	.res	14
		.CODE


		;extern long my_os_obpb_read (unsigned char file, unsigned char const *data, long size);
_my_os_gbpb_read:
		; size
		sta	osgbpb_block+5
		stx	osgbpb_block+6
		lda	sreg
		sta	osgbpb_block+7
		lda	sreg+1
		sta	osgbpb_block+8

		; pointer (always in host memory)
		jsr	popax
		sta	osgbpb_block+1
		stx	osgbpb_block+2

		ldx	#$FF
		stx	osgbpb_block+3
		stx	osgbpb_block+4

		jsr	popa
		sta	osgbpb_block+0
		ldx	#<osgbpb_block
		ldy	#>osgbpb_block

		lda	#$04				; read bytes ignore PTR

		jsr	OSGBPB
		
		lda	osgbpb_block+8
		sta	sreg+1
		lda	osgbpb_block+7
		sta	sreg
		lda	osgbpb_block+5
		ldx	osgbpb_block+6
		rts