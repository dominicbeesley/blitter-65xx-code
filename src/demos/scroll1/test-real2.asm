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

;		.SEGMENT "SCREEN"
;LOAD_BASE:	
LOAD_BASE	:= $2000

B_FONT_SPR	:=	$001000
B_FONT_MAS	:=	$007000

		.ZEROPAGE
ZP_TMP:		.RES 1

		.CODE 
		
		; change to mode 2
		lda	#22
		jsr	OSWRCH
		lda	#2
		jsr	OSWRCH

		; load sprite data to load area
		jsr	ex_osfile_load

		; copy to blitter ram
		ldx	#<bmfont_copy_to_SRAM
		ldy	#>bmfont_copy_to_SRAM
		jsr	_blit_copy

		; load mask data to load area
		lda	#'M'
		sta	fn_font_spr

		jsr	ex_osfile_load

		; copy to blitter ram
		ldx	#<bmfont_mask_copy_to_SRAM
		ldy	#>bmfont_mask_copy_to_SRAM
		jsr	_blit_copy

		lda	#12
		jsr	OSWRCH

		lda	#'D'
		sta	fn_font_spr

		jsr	ex_osfile_load



		ldx	#0
		ldy	#2
pal_lp:		lda	#19
		jsr	OSWRCH
		txa	
		jsr	OSWRCH
		lda	#16
		jsr	OSWRCH
		lda	LOAD_BASE,Y
		jsr	OSWRCH
		iny
		lda	LOAD_BASE,Y
		jsr	OSWRCH
		iny
		lda	LOAD_BASE,Y
		jsr	OSWRCH
		iny
		inx
		cpx	#16
		bne	pal_lp

		ldx	#0
		stx	ZP_TMP
lp:
;		inc 	ZP_TMP
;		beq	FINISH
;		ldx	ZP_TMP
;		stx	font_copy_from_SRAM_settings + DMAC_ADDR_D_offs + 2
		ldx	#<font_copy_from_SRAM_settings
		ldy	#>font_copy_from_SRAM_settings
		jsr	_blit_ctl_full
;		jmp	lp

FINISH:
		rts

ex_osfile_load:
		lda	#<fn_font_spr
		sta	osfile_load_fn
		lda	#>fn_font_spr
		sta	osfile_load_fn + 1
		lda	#<LOAD_BASE
		sta	osfile_load_lo
		lda	#>LOAD_BASE
		sta	osfile_load_lo + 1
		ldx	#$FF
		stx	osfile_load_lo + 2
		stx	osfile_load_lo + 3
		inx
		stx	osfile_load_ex
		ldx	#<osfile_load
		ldy	#>osfile_load
		lda	#OSFILE_LOAD
		jmp	OSFILE


		.BSS
osfile_load:
osfile_load_fn:		.res	2
osfile_load_lo:		.res	4
osfile_load_ex:		.res	4
osfile_load_st:		.res	4
osfile_load_en:		.res	4

		.DATA
fn_font_spr:		.byte	"S.FONT", $D

bmfont_copy_to_SRAM:
	.word	LOAD_BASE
	.byte	$FF
	.word	B_FONT_SPR
	.byte	$00
	.word	(16*8*192)
bmfont_mask_copy_to_SRAM:
	.word	LOAD_BASE
	.byte	$FF
	.word	B_FONT_MAS
	.byte	$00
	.word	(4*8*192)

font_copy_from_SRAM_settings:
	.byte	BLITCON_EXEC_B+BLITCON_EXEC_D				; 		 execD, execB	BLTCON
	.byte	$CC							; copy B to D, ignore A, C	FUNCGEN
	.byte	0							;				MASK_FIRST
	.byte	0							;				MASK_LAST
	.byte	(16*4-1)							; 			WIDTH
	.byte	47							;				HEIGHT
	.byte	0							;				SHIFT_A
	.byte	0		; SPARE
	.word	0							;				STRIDE_A
	.word	(16*8)							;				STRIDE_B
	.word	640							;				STRIDE_C/D
	.word	0		; SPARE
	ADDR24	0							;				ADDR_A
	.byte	$AA							;				DATA_A
	ADDR24	B_FONT_SPR						 ;				ADDR_B
	.byte	$55							;				DATA_B
	ADDR24	$FF3000							;				ADDR_C/D
	.byte	0							;				DATA_C
	ADDR24	$000000							;				ADDR_E
	.byte	BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_4BBP	; act, cell, mo.2		BLTCON




		.END
