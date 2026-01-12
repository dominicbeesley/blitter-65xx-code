; MIT License
; 
; Copyright (c) 2025 Dossytronics
; https://github.com/dominicbeesley/blitter-vhdl-6502
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

		.include 	"c20k-hardware.inc"
		.include 	"hardware.inc"
		.include	"preboot.inc"
		.include	"spi.inc"


	.zeropage

zp_scrptr:	.res	2
zp_ctr:		.res	2
zp_dat_ptr:	.res	2


	.bss

genbuf:		.res	256

	.rodata
;********* 6845 REGISTERS 0-11 FOR SCREEN TYPE 4 - MODE 7 ****************
crtc_mo_7:
			.byte	$3f				; 0 Horizontal Total	 =64
			.byte	$28				; 1 Horizontal Displayed =40
			.byte	$33				; 2 Horizontal Sync	 =&33  Note: &31 is a better value
			.byte	$24				; 3 HSync Width+VSync	 =&24  VSync=2, HSync=4
			.byte	$1e				; 4 Vertical Total	 =30
			.byte	$02				; 5 Vertical Adjust	 =2
			.byte	$19				; 6 Vertical Displayed	 =25
			.byte	$1b				; 7 VSync Position	 =&1B
			.byte	$93				; 8 Interlace+Cursor	 =&93  Cursor=2, Display=1, Interlace=Sync+Video
			.byte	$12				; 9 Scan Lines/Character =19
			.byte	$72				; 10 Cursor Start Line	  =&72	Blink=On, Speed=1/32, Line=18
			.byte	$13				; 11 Cursor End Line	  =19
			.byte	0
			.byte	0
	.code
handle_nmi:
handle_irq:
		rti


handle_reset:
		cld
		sei
		ldx	#$FF
		txs

		jmp	crt0_startup
		
		jsr	spi_reset

		lda	#'C'
		jsr	pr


		lda	#<ROM_IMAGE_BASE
		sta	zp_spi_addr
		lda	#>ROM_IMAGE_BASE
		sta	zp_spi_addr+1
		lda	#^ROM_IMAGE_BASE
		sta	zp_spi_addr+2

		lda	#<.sizeof(pb_romset)
		sta	zp_spi_len
		lda	#>.sizeof(pb_romset)
		sta	zp_spi_len+1

		lda	#<genbuf
		sta	zp_spi_memptr
		lda	#>genbuf
		sta	zp_spi_memptr+1

		lda	#'B'
		jsr	pr

		jsr	spi_read_buf

		lda	#'A'
		jsr	pr

		ldx	#0
@pr0:		lda	genbuf+pb_romset::title,X
		beq	@pr0out
		jsr	pr
		inx
		bne	@pr0
@pr0out:



HERE:		jmp	HERE

;;;		.proc 	hex
;;;		pha
;;;		lsr	A
;;;		lsr	A
;;;		lsr	A
;;;		lsr	A
;;;		jsr	hex_nyb
;;;		pla
;;;hex_nyb:		and	#$F
;;;		cmp	#9
;;;		bcc	:+
;;;		adc	#'A'-'0'-10-1
;;;:		adc	#'0'
;;;		jmp	pr		
;;;		.endproc
;;;	
		.proc	pr
		pha
		tya
		pha
		txa
		pha
		tsx
		lda	$103,X
		ldy	#0
		sta	(zp_scrptr),Y
		inc	zp_scrptr
		bne	:+
		inc	zp_scrptr+1
:		pla
		tax
		pla
		tay
		pla
		rts
		.endproc


	.segment "VECS"	
v_nmi:		.addr	handle_nmi
v_res:		.addr	handle_reset
v_irq:		.addr	handle_irq
	.end
