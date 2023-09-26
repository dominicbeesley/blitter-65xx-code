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


		.import	vid_init

		.CODE

START:
		jsr	vid_init

		lda	$296			; time 
		sta	seed
		lda	#<VDU_MEM_BASE
		sta	zp_ptr
		lda	#>VDU_MEM_BASE
		sta	zp_ptr+1
		ldy	#0
@l1:		jsr	rnd8
		sta	(zp_ptr),Y
		iny
		bne	@l1
		inc	zp_ptr+1
		bpl	@l1

@loop:
		; test scrolling
		lda	#20
		sta	zp_tmp
@wl:		lda	#19
		jsr	OSBYTE
		dec	zp_tmp
		bne	@wl

		clc
		lda	crtc_addr
		adc	#80
		sta	crtc_addr
		lda	crtc_addr+1
		adc	#0
		and	#$0F
		sta	crtc_addr+1
@sk1:		
		lda	crtc_addr+1
		ldx	crtc_addr
		ldy 	#12
		jsr	set_crtc_YeqAX

		lda	crtc_addr+1
		ldx	crtc_addr
		ldy 	#14
		jsr	set_crtc_YeqAX

		jmp	@loop	

		rts


set_crtc_YeqAX:	php
		sei
		sty	sheila_CRTC_ix
		sta	sheila_CRTC_dat
		iny
		sty	sheila_CRTC_ix
		txa
		sta	sheila_CRTC_dat
		plp
		rts

crtc_addr:	.word	0

rnd8:	
		lda seed
        		beq @doEor
         	asl
         	beq @noEor ;if the input was $80, skip the EOR
         	bcc @noEor
@doEor:    	eor #$1d
@noEor: 		sta seed
		rts

seed:		.byte	0
		.END