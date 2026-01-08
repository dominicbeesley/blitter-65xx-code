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


SPI_BOOT_BASE	:=	$700000
JIM_BOOT_BASE	:=	$1FC000


	.zeropage

zp_scrptr:	.res	2
zp_ctr:	.res	1

	.bss

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

		; mode 7
		lda	#$4b
		sta	sheila_VIDPROC
		ldx	#13
@lp1:		stx	sheila_CRTC_IX
		lda	crtc_mo_7, X
		sta	sheila_CRTC_DAT
		dex
		bpl	@lp1
		lda	#$7C
		sta	zp_scrptr+1
		lda	#0
		sta	zp_scrptr

		lda	#'0'
		sta	$7C00


		lda	#$40
		sta	zp_ctr		; number of pages to transfer


		; start SPI bulk read
		jsr	spi_reset
		lda	#$0B		; fast read
		jsr	spi_write_cont
		lda	#^SPI_BOOT_BASE
		jsr	spi_write_cont
		lda	#>SPI_BOOT_BASE
		jsr	spi_write_cont
		lda	#<SPI_BOOT_BASE
		jsr	spi_write_cont
		lda	#$FF		; dummy
		jsr	spi_write_cont

		; prime JIM registers
		lda	#JIM_DEVNO_BLITTER
		sta	fred_JIM_DEVNO
		lda	#^JIM_BOOT_BASE
		sta	fred_JIM_PAGE_HI
		lda	#>JIM_BOOT_BASE
		sta	fred_JIM_PAGE_LO
		ldy	#<JIM_BOOT_BASE

@lp:		jsr	spi_write_cont
		sta	JIM,Y
		iny
		bne	@lp
		inc	fred_JIM_PAGE_LO
		bne	@s
		inc	fred_JIM_PAGE_HI
@s:		dec	zp_ctr
		bne	@lp

		jsr	spi_write_last

		lda	#'1'
		sta	$7C00


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
;;;		.proc	pr
;;;		ldy	#0
;;;		sta	(zp_scrptr),Y
;;;		inc	zp_scrptr
;;;		bne	:+
;;;		inc	zp_scrptr+1
;;;:		rts
;;;		.endproc


;=============================================
; S P I
;=============================================

	.proc	spi_reset
		lda	#$10
		sta	fred_SPI_DIV		; fast spi
		lda	#$1C			; select nCS[7]
		sta	fred_SPI_CTL
		sta	fred_SPI_WRITE_END	; start and reset
		jsr	spi_wait_rd
		lda	#$00			; select nCS[0]
		sta	fred_SPI_CTL
		jmp	spi_wait_rd
	.endproc 

	.proc	spi_write_last
		sta	fred_SPI_WRITE_END
		jmp	spi_wait_rd
	.endproc

	.proc	spi_write_cont
		sta	fred_SPI_WRITE_CONT
		;;;;; FALL THRU ;;;;;
	.endproc

	.proc	spi_wait_rd
		bit	fred_SPI_STAT
		bmi	spi_wait_rd
		lda	fred_SPI_READ_DATA
		rts
	.endproc


	.segment "VECS"	
v_nmi:		.addr	handle_nmi
v_res:		.addr	handle_reset
v_irq:		.addr	handle_irq
	.end
