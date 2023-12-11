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

		.include "maths.inc"

		.global	sprite_data, sprite_data_end

jim_page_SPRITE_REGS = $FBFF

SPR_RUN	= $5000
SPR_LIST = $3000
	.zeropage

zp_ptr1:	.res	2
zp_ptr2:	.res	2
zp_ctr:	.res	2
zp_tmp:	.res	1

	.macro	MEM_CPY src, dest, len

		lda	#<len
		sta	zp_ctr
		lda	#>len
		sta	zp_ctr+1
		lda	#<src
		sta	zp_ptr1
		lda	#>src
		sta	zp_ptr1+1
		lda	#<dest
		sta	zp_ptr2
		lda	#>dest
		sta	zp_ptr2+1
		jsr	memcpy


	.endmacro

	.code

		; enable jim
		lda	#JIM_DEVNO_BLITTER
		sta	fred_JIM_DEVNO
		lda	fred_JIM_DEVNO	


		lda	#22
		jsr	OSWRCH
		lda	#0
		jsr	OSWRCH

		; copy sprite data up to above 3000
		MEM_CPY	sprite_data, SPR_RUN, (sprite_data_end-sprite_data)
		MEM_CPY	spr_list, SPR_LIST, 8

		jsr	jimSPRPage
		lda	#<SPR_LIST
		sta	$FD0C
		lda	#>SPR_LIST
		sta	$FD0D
		lda	#0
		sta	$FD0E

here:		lda	#19
		jsr	OSBYTE

		lda	zp_ctr
		ldx	zp_ctr+1
		jsr	math_sin
		txa
		rol	A
		php
		txa
		adc	#250
		sta	SPR_LIST+0
		lda	#0
		adc	#0
		plp
		adc	#0
		ror	A
		lda	SPR_LIST+3
		and	#$FE
		adc	#0
		sta	SPR_LIST+3
		
		lda	zp_ctr
		ldx	zp_ctr+1
		jsr	math_cos
		txa
		rol	A
		php
		txa
		adc	#160
		sta	SPR_LIST+1
		lda	#0
		adc	#0
		plp
		adc	#0
		ror	A
		lda	SPR_LIST+3
		and	#$FD
		php
		adc	#0
		plp
		adc	#0
		sta	SPR_LIST+3



		clc
		lda	#5
		adc	zp_ctr
		sta	zp_ctr
		lda	zp_ctr+1
		adc	#0
		sta	zp_ctr+1

		jmp	here

memcpy:		lda	zp_ctr+1
		beq	@skp
		ldy	#0
@plp:		lda	(zp_ptr1),Y
		sta	(zp_ptr2),Y
		iny
		bne	@plp
		dec	zp_ctr+1
		bne	@plp
@skp:		ldx	zp_ctr
		beq	@end
		ldy	#0	
@lp2:		lda	(zp_ptr1),Y
		sta	(zp_ptr2),Y
		iny
		dex
		bne	@lp2
@end:		rts

jimSPRPage:
		pha
		lda	#<jim_page_SPRITE_REGS
		sta	fred_JIM_PAGE_LO
		lda	#>jim_page_SPRITE_REGS
		sta	fred_JIM_PAGE_HI
		pla
		rts

spr_list:	.dword	$00908090
		.dword	SPR_RUN

		.END