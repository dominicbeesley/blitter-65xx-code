; MIT License
; 
; Copyright (c) 2026 Dossytronics
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
		.include	"blit_lib.inc"


		; quick test program - change HDMI to mode 2, non-interlaced and copy current screen contents to base
		; of hdmi memory

HDMI_PAGE_MEM		:=	$FA00
HDMI_PAGE_REGS		:=	$FBFE
HDMI_ADDR_VIDPROC_CTL	:=	$FD20
HDMI_ADDR_VIDPROC_PAL	:=	$FD21
HDMI_ADDR_CRTC_IX	:=	$FD00
HDMI_ADDR_CRTC_DAT	:=	$FD01


zp_ptr			:=	$70


		.CODE

START:

		lda	#$40
		sta	$FE22		; reset NULA

		lda	#22
		jsr	OSWRCH
		lda	#2
		jsr	OSWRCH

		ldy	#2
		ldx	#0
@lp:		txa
		and	#$3F
		adc	#' '
		jsr	OSWRCH
		inx
		bne	@lp
		dey
		bne	@lp


again:
;;		lda	#$D1
;;		sta	$EE
;;		sta	$FCFF
;;		lda	#$10
;;		sta	$FCFD
;;		lda	#0
;;		sta	$FCFE
;;
;;		lda	#$30
;;		sta	@lp+2
;;
;;		ldx	#0
;;@lp:		lda	$3000,X
;;		sta	$FD00,X
;;		inx
;;		bne	@lp
;;
;;		inc	$FCFE
;;		bne	@s
;;		inc	$FCFD	
;;@s:		inc	@lp+2
;;		lda	@lp+2
;;		cmp	#$80
;;		bne	@lp

		ldx	#<screen_copy_to_SRAM
		ldy	#>screen_copy_to_SRAM
		jsr	_blit_copy

		lda	#12
		jsr	OSWRCH


;;		lda	#$D1
;;		sta	$EE
;;		sta	$FCFF
;;		lda	#$10
;;		sta	$FCFD
;;		lda	#0
;;		sta	$FCFE
;;
;;		lda	#$30
;;		sta	@lp2+5
;;
;;		ldx	#0
;;@lp2:		lda	$FD00,X
;;		sta	$3000,X
;;		inx
;;		bne	@lp2
;;
;;		inc	$FCFE
;;		bne	@s2
;;		inc	$FCFD	
;;@s2:		inc	@lp2+5
;;		lda	@lp2+5
;;		cmp	#$80
;;		bne	@lp2


		ldx	#<screen_copy_from_SRAM
		ldy	#>screen_copy_from_SRAM
		jsr	_blit_copy

		jmp	again

		rts



screen_copy_to_SRAM:
	.word	$3000
	.byte	$FF
	.word	0
	.byte	$10
	.word	20*1024-1
screen_copy_from_SRAM:
	.word	0
	.byte	$10
	.word	$3000
	.byte	$FF
	.word	20*1024-1



		.END