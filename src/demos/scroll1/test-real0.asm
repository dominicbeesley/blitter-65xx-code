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

		.include	"common.inc"
		.include	"hardware.inc"
		.include	"blit_lib.inc"
		.include	"oslib.inc"

vec_nmi		:=	$D00

		.ZEROPAGE
ZP_PTR:		.RES 2

		.CODE
		
		JMP	START

mostbl_chardefs:
	.byte	$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$18,$18,$18,$18,$18,$00,$18,$00
	.byte	$6C,$6C,$6C,$00,$00,$00,$00,$00
	.byte	$36,$36,$7F,$36,$7F,$36,$36,$00
	.byte	$0C,$3F,$68,$3E,$0B,$7E,$18,$00
	.byte	$60,$66,$0C,$18,$30,$66,$06,$00
	.byte	$38,$6C,$6C,$38,$6D,$66,$3B,$00
	.byte	$0C,$18,$30,$00,$00,$00,$00,$00
	.byte	$0C,$18,$30,$30,$30,$18,$0C,$00
	.byte	$30,$18,$0C,$0C,$0C,$18,$30,$00
	.byte	$00,$18,$7E,$3C,$7E,$18,$00,$00
	.byte	$00,$18,$18,$7E,$18,$18,$00,$00
	.byte	$00,$00,$00,$00,$00,$18,$18,$30
	.byte	$00,$00,$00,$7E,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$18,$18,$00
	.byte	$00,$06,$0C,$18,$30,$60,$00,$00
	.byte	$3C,$66,$6E,$7E,$76,$66,$3C,$00
	.byte	$18,$38,$18,$18,$18,$18,$7E,$00
	.byte	$3C,$66,$06,$0C,$18,$30,$7E,$00
	.byte	$3C,$66,$06,$1C,$06,$66,$3C,$00
	.byte	$0C,$1C,$3C,$6C,$7E,$0C,$0C,$00
	.byte	$7E,$60,$7C,$06,$06,$66,$3C,$00
	.byte	$1C,$30,$60,$7C,$66,$66,$3C,$00
	.byte	$7E,$06,$0C,$18,$30,$30,$30,$00
	.byte	$3C,$66,$66,$3C,$66,$66,$3C,$00
	.byte	$3C,$66,$66,$3E,$06,$0C,$38,$00
	.byte	$00,$00,$18,$18,$00,$18,$18,$00
	.byte	$00,$00,$18,$18,$00,$18,$18,$30
	.byte	$0C,$18,$30,$60,$30,$18,$0C,$00
	.byte	$00,$00,$7E,$00,$7E,$00,$00,$00
	.byte	$30,$18,$0C,$06,$0C,$18,$30,$00
	.byte	$3C,$66,$0C,$18,$18,$00,$18,$00
	.byte	$3C,$66,$6E,$6A,$6E,$60,$3C,$00
	.byte	$3C,$66,$66,$7E,$66,$66,$66,$00
	.byte	$7C,$66,$66,$7C,$66,$66,$7C,$00
	.byte	$3C,$66,$60,$60,$60,$66,$3C,$00
	.byte	$78,$6C,$66,$66,$66,$6C,$78,$00
	.byte	$7E,$60,$60,$7C,$60,$60,$7E,$00
	.byte	$7E,$60,$60,$7C,$60,$60,$60,$00
	.byte	$3C,$66,$60,$6E,$66,$66,$3C,$00
	.byte	$66,$66,$66,$7E,$66,$66,$66,$00
	.byte	$7E,$18,$18,$18,$18,$18,$7E,$00
	.byte	$3E,$0C,$0C,$0C,$0C,$6C,$38,$00
	.byte	$66,$6C,$78,$70,$78,$6C,$66,$00
	.byte	$60,$60,$60,$60,$60,$60,$7E,$00
	.byte	$63,$77,$7F,$6B,$6B,$63,$63,$00
	.byte	$66,$66,$76,$7E,$6E,$66,$66,$00
	.byte	$3C,$66,$66,$66,$66,$66,$3C,$00
	.byte	$7C,$66,$66,$7C,$60,$60,$60,$00
	.byte	$3C,$66,$66,$66,$6A,$6C,$36,$00
	.byte	$7C,$66,$66,$7C,$6C,$66,$66,$00
	.byte	$3C,$66,$60,$3C,$06,$66,$3C,$00
	.byte	$7E,$18,$18,$18,$18,$18,$18,$00
	.byte	$66,$66,$66,$66,$66,$66,$3C,$00
	.byte	$66,$66,$66,$66,$66,$3C,$18,$00
	.byte	$63,$63,$6B,$6B,$7F,$77,$63,$00
	.byte	$66,$66,$3C,$18,$3C,$66,$66,$00
	.byte	$66,$66,$66,$3C,$18,$18,$18,$00
	.byte	$7E,$06,$0C,$18,$30,$60,$7E,$00
	.byte	$7C,$60,$60,$60,$60,$60,$7C,$00
	.byte	$00,$60,$30,$18,$0C,$06,$00,$00
	.byte	$3E,$06,$06,$06,$06,$06,$3E,$00
	.byte	$18,$3C,$66,$42,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$00,$00,$FF
	.byte	$1C,$36,$30,$7C,$30,$30,$7E,$00
	.byte	$00,$00,$3C,$06,$3E,$66,$3E,$00
	.byte	$60,$60,$7C,$66,$66,$66,$7C,$00
	.byte	$00,$00,$3C,$66,$60,$66,$3C,$00
	.byte	$06,$06,$3E,$66,$66,$66,$3E,$00
	.byte	$00,$00,$3C,$66,$7E,$60,$3C,$00
	.byte	$1C,$30,$30,$7C,$30,$30,$30,$00
	.byte	$00,$00,$3E,$66,$66,$3E,$06,$3C
	.byte	$60,$60,$7C,$66,$66,$66,$66,$00
	.byte	$18,$00,$38,$18,$18,$18,$3C,$00
	.byte	$18,$00,$38,$18,$18,$18,$18,$70
	.byte	$60,$60,$66,$6C,$78,$6C,$66,$00
	.byte	$38,$18,$18,$18,$18,$18,$3C,$00
	.byte	$00,$00,$36,$7F,$6B,$6B,$63,$00
	.byte	$00,$00,$7C,$66,$66,$66,$66,$00
	.byte	$00,$00,$3C,$66,$66,$66,$3C,$00
	.byte	$00,$00,$7C,$66,$66,$7C,$60,$60
	.byte	$00,$00,$3E,$66,$66,$3E,$06,$07
	.byte	$00,$00,$6C,$76,$60,$60,$60,$00
	.byte	$00,$00,$3E,$60,$3C,$06,$7C,$00
	.byte	$30,$30,$7C,$30,$30,$30,$1C,$00
	.byte	$00,$00,$66,$66,$66,$66,$3E,$00
	.byte	$00,$00,$66,$66,$66,$3C,$18,$00
	.byte	$00,$00,$63,$6B,$6B,$7F,$36,$00
	.byte	$00,$00,$66,$3C,$18,$3C,$66,$00
	.byte	$00,$00,$66,$66,$66,$3E,$06,$3C
	.byte	$00,$00,$7E,$0C,$18,$30,$7E,$00
	.byte	$0C,$18,$18,$70,$18,$18,$0C,$00
	.byte	$18,$18,$18,$00,$18,$18,$18,$00
	.byte	$30,$18,$18,$0E,$18,$18,$30,$00
	.byte	$31,$6B,$46,$00,$00,$00,$00,$00
	.byte	$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

sprite_test1:
		.INCBIN "data/SPRITE"


letter1:
	.byte	$0D		; 	execD, execC,execA		BLTCON
	.byte	$CA		; B foreground, C background masked by A	FUNCGEN
	.byte	$FF		;					MASK_FIRST
	.byte	$FF		;					MASK_LAST
	.byte	(4-1)		; 					WIDTH
	.byte	8-1		;					HEIGHT
	.byte	0		;					SHIFT_A
	.byte	0		; SPARE
	.word	1		;					STRIDE_A
	.word	1		;					STRIDE_B
	.word	640		;					STRIDE_C
	.word	0		; SPARE
	ADDR24	$FF0000+(mostbl_chardefs+(65-32)*8) ;			ADDR_A
	.byte	$AA		;					DATA_A
	ADDR24	0		;					ADDR_B
	.byte	$33		;					DATA_B
	ADDR24	$FF3000		;					ADDR_C
	.byte	$CC		;					DATA C
	ADDR24	$0		;					ADDR_E
	.byte	$E0		; Act, cell, mo.2		BLTCON



START:

		; mode 2

		lda	#22
		jsr	OSWRCH
		lda	#2
		jsr	OSWRCH

		; col. 129
		; col. 3
		lda	#17
		jsr	OSWRCH
		lda	#129
		jsr	OSWRCH

		lda	#17
		jsr	OSWRCH
		lda	#3
		jsr	OSWRCH

		ldx	#0
		lda	#'*'
lp2:		jsr	OSWRCH
		dex
		bne	lp2


loop:



		ldx	#<letter1
		ldy	#>letter1
		jsr	_blit_ctl_full

		inc	letter1+block_ADDR_C_offs+0	; page up

		inc	letter1+block_ADDR_C_offs+1	; page up
		lda	letter1+block_ADDR_C_offs+1
		bpl	loop

		RTS

		.END
