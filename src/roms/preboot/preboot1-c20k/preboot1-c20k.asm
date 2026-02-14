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
		.include		"preboot.inc"
		.include		"spi.inc"


KEY_COPY	= $69
KEY_BS	= $59
KEY_CTRL	= $01

	.segment "ZPEXT": zeropage

; TODO: 
; - preserve zero-page on stack?
; - preserve all memory in reserved area?
; - if checksum fails, force hard-reset
; - store map0n1 etc for preboot-2

zp_ctr	:= <$00FD
zp_cksm	:= <$00FF
	.bss

	.rodata

	.code

;;debug_hex:	pha
;;		lsr	A
;;		lsr	A
;;		lsr	A
;;		lsr	A
;;		jsr	debug_hexnyb
;;		pla
;;
;;		; fall thru
;;
;;debug_hexnyb:	and	#$F
;;		cmp	#$A
;;		bcc	@s
;;		adc	#'A'-'0'-11
;;@s:		adc	#'0'
;;
;;		; fall thru

debug_printc:	bit	debug_UART_status
		bvs	debug_printc
		sta	debug_UART_data
		rts

handle_nmi:
handle_irq:
		rti


ks:
		sta	sheila_SYSVIA_ora_nh
		bit	sheila_SYSVIA_ora_nh
		rts

handle_reset:	cld
		sei
		ldx	#$FF
		txs
		
		; prime JIM registers
		lda	#JIM_DEVNO_BLITTER
		sta	fred_JIM_DEVNO

		lda	#'A'
		jsr	debug_printc

		; check for key combo // TODO: check for other keys?
		
		lda	#3
		sta	sheila_SYSVIA_orb		; stop auto-scan
		lda	#$7F
		sta	sheila_SYSVIA_ddra	; bit 7 in, others out

		lda	#KEY_BS
		jsr	ks
		bpl	reboot
		lda	#KEY_CTRL
		jsr	ks
		bpl	reboot

		lda	#'B'
		jsr	debug_printc

		lda	#$40
		sta	zp_ctr		; number of pages to transfer

		lda	#^JIM_BOOT_BASE
		sta	fred_JIM_PAGE_HI
		lda	#>JIM_BOOT_BASE
		sta	fred_JIM_PAGE_LO
		ldy	#<JIM_BOOT_BASE

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

@lp:		jsr	spi_write_cont
		sta	JIM,Y
		clc
		adc	zp_cksm
		sta	zp_cksm
		iny
		bne	@lp
		inc	fred_JIM_PAGE_LO
		bne	@s
		inc	fred_JIM_PAGE_HI
@s:		dec	zp_ctr
		bne	@lp

		jsr	spi_write_last

		lda	zp_cksm
		bne	@badboot


		; force to map 0 mosram
		lda	sheila_MEM_TURBO2
		sta	PREBOOT_SAVE_TURBO2
		ora	#BITS_MEM_TURBO2_MAP0N1
		sta	sheila_MEM_TURBO2
		lda	sheila_MEM_CTL
		ora	#BITS_MEM_CTL_SWMOS
		sta	sheila_MEM_CTL
		jmp	reboot
@badboot:	lda	#'!'
		jsr	debug_printc

reboot:		lda	#$FF
		sta	JIM_DEVNO_BLITTER		; make sure JIM is deselected

		ldx	#stackprog_end-stackprog-1
@rlp:		lda	stackprog,X
		sta	$100,X
		dex
		bpl	@rlp
		jmp	$100


stackprog:	lda	sheila_MEM_TURBO2
		and	#<~BITS_MEM_TURBO2_PREBOOT
		sta	sheila_MEM_TURBO2
		jmp	($FFFC)
stackprog_end:


	.segment "VECS"	
v_nmi:		.addr	handle_nmi
v_res:		.addr	handle_reset
v_irq:		.addr	handle_irq
	.end
