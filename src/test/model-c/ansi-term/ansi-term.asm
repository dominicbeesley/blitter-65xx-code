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


		.include	"oslib.inc"
		.include	"hardware.inc"
		.include	"mosrom.inc"
		.include	"aeris.inc"


		; quick test program - change HDMI to mode 2, non-interlaced and copy current screen contents to base
		; of hdmi memory



zp_ptr			:=	$70
zp_tmp			:=	$72
zp_tmp2			:=	$73


VDU_MEM_BASE		:=	$7000


		.import	my_WRCHV

		.CODE

START:
		; load font at FFFF6000 - assume this is mapped to gfx
		lda	#$FF
		ldx	#<FONT_FILE
		ldy	#>FONT_FILE
		jsr	OSFILE


		lda	#22
		jsr	my_WRCHV
		lda	#27
		jsr	my_WRCHV

		ldx	#0
		ldy	#0
		
@l2:		sty	zp_tmp2
@l1:		stx	zp_tmp
		lda	#17
		jsr	my_WRCHV
		lda	zp_tmp
		jsr	my_WRCHV
		lda	#17
		jsr	my_WRCHV
		lda	zp_tmp2
		ora	#$80
		jsr	my_WRCHV

		ldx	#<ish_str
		ldy	#>ish_str
		jsr	PrintXY

		ldx	zp_tmp
		inx
		cpx	#16
		bcc	@l1
		ldx	#0

		ldy	zp_tmp2
		iny
		cpy	#16
		bcc	@l2



		ldx	#<test_str
		ldy	#>test_str
		jsr	PrintXY

		; escape key sends char 27
		lda	#229
		ldx	#1
		ldy	#0
		jsr	OSBYTE

		; set baud to 9600/9600
		lda	#7
		ldx	#7
		jsr	OSBYTE

		lda	#8
		ldx	#7
		jsr	OSBYTE

		; listen on keyboard and serial
		lda	#2
		ldx	#2
		jsr	OSBYTE


main_loop:	lda	#$80
		ldx	#$FF
		ldy	#$FF
		jsr	OSBYTE			; adval -1
		txa
		beq	@sk_keys
		
		ldx	#0
		ldy	#0
		lda	#$81
		jsr	OSBYTE			; wait for a key

		bcs	@sk_keys2

		txa
		pha

		; send to com port

		lda	#3
		tax
		jsr	OSBYTE
		pla
		pha
		jsr	OSWRCH

		lda	#3
		ldx	#0
		jsr	OSBYTE

		pla
		jsr	my_WRCHV

@sk_keys2:
@sk_keys:
		
		; check for input from serial
		lda	#$80
		ldx	#$FE
		ldy	#$FF
		jsr	OSBYTE			; adval -2
		txa
		beq	@sk_ser

		; switch input to serial		

		lda	#2
		ldx	#1
		jsr	OSBYTE
		
		; wait for a char (should be there)
		ldx	#0
		ldy	#0
		lda	#$81
		jsr	OSBYTE
		bcs	@sk_ser2

		txa
		jsr	my_WRCHV

@sk_ser2:
		lda	#2
		ldx	#2
		jsr	OSBYTE
@sk_ser:

		jmp	main_loop

PrintXY:		stx	zp_ptr
		sty	zp_ptr+1
		ldy	#0
@lp:		lda	(zp_ptr),Y
		beq	@sk
		jsr	my_WRCHV
		iny
		bne	@lp
@sk:		rts


FONT_FILE_NAME:		.byte	"F.VGA8",$D,0
FONT_FILE:		.word	FONT_FILE_NAME
			.dword	$FFFF6000
			.dword	0
			.dword	0
			.dword	0

test_str:	.byte	"This is an ANSI TEXT test, ", 27, "[5;10mPoopPoop",13,10,"AAAAAAA",0
ish_str:		.byte	"Ish$%",0

		.END