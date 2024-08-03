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
		.include	"common.inc"
		.include	"hardware.inc"
		.include	"blit_lib.inc"


vec_nmi		:=	$D00

		.ZEROPAGE

		.SEGMENT "SCREEN"
SCREEN_BASE:

B_SHADOW	:=	$020000
B_BACK_SAV	:=	$030000
B_FONT_SPR	:=	$041000				; must be page aligned for calcs
B_FONT_MAS	:=	$047000

		.ZEROPAGE
ZP_TMP:		.RES 1

		.CODE 

		lda	#22
		jsr	OSWRCH
		lda	#2
		jsr	OSWRCH

;		lda	#$FF
;		sta	sheila_DMAC_DATA_B

;		lda	#$00
;		sta	sheila_DMAC_STRIDE_A
;		lda	#$19
;		sta	sheila_DMAC_STRIDE_A + 1

		ldx	#<spr_plot_blk
		ldy	#>spr_plot_blk
		jsr	_blit_plot_masked

		ldx	#<test_a_stride
		ldy	#>test_a_stride
		jsr	_blit_ctl_full

		RTS

		.DATA

spr_plot_blk:	.word	$3000			; dest_addr
		.byte	$FF			; dest bank
		.word	.loword(B_FONT_SPR)	; src addr
		.byte	.bankbyte(B_FONT_SPR)	; src bank
		.word	.loword(B_FONT_MAS)	; mask addr
		.byte	.bankbyte(B_FONT_MAS)	; mask bank
		.byte	0			; shift
		.byte	95			; height -1 
		.byte	31			; width - 1
		.word	640			; dest stride
		.word	128			; sprite source stride
		.word	32			; mask stride
		.byte	$E0			; BLTCON act, cell, 4bpp

test_a_stride:
	.byte	BLITCON_EXEC_A+BLITCON_EXEC_B+BLITCON_EXEC_C+BLITCON_EXEC_D		; execD, execC, execB, execA 	BLTCON 
	.byte	$CA								; copy B to D, mask A, C		FUNCGEN
	.byte	$FF								;				MASK_FIRST
	.byte	$FF								;				MASK_LAST
	.byte	31								; 				WIDTH
	.byte	95								;				HEIGHT
	.byte	0								;				SHIFT
	.byte	0	; SPARE
	.word	32								;				STRIDE_A
	.word	128								;				STRIDE_B
	.word	640								;				STRIDE_C
	.word	0	; SPARE
	ADDR24	(B_FONT_MAS+8)							;				ADDR_A
	.byte	$AA								;				DATA_A
	ADDR24	(B_FONT_SPR+32)							;				ADDR_B
	.byte	$55								;				DATA_B
	ADDR24	$FF4000								;				ADDR_C/D
	.byte	0								;				DATA_C
	ADDR24	$0								;				ADDR_E
	.byte	BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_4BBP		; BLTCON act, cell, 4bpp


		.END
