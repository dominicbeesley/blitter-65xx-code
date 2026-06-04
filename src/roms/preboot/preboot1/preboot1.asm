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

.ifdef C20K
		.include 	"c20k-hardware.inc"
.endif
		.include 	"hardware.inc"
		.include		"preboot.inc"
		.include		"spi.inc"


KEY_COPY	= $69
KEY_BS	= $59
KEY_CTRL	= $01

LAT_KEYSCAN = 3
LAT_SHIFT = 6
LAT_CAPS = 7

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

spi_head:.byte	$FF, <SPI_BOOT_BASE, >SPI_BOOT_BASE, ^SPI_BOOT_BASE, $B

	.code

handle_nmi:
handle_irq:
		rti

flash:		
		jsr	flash2
		eor	#8
flash2:		sta	sheila_SYSVIA_orb
		ldx	#0
		ldy	#0
@l:		dey
		bne	@l
		dex
		bne	@l
@w:		rts

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



		; check for key combo // TODO: check for other keys?

		lda	#$F
		sta	sheila_SYSVIA_ddrb	; slow latch setup
		lda	#LAT_KEYSCAN
		sta	sheila_SYSVIA_orb		; stop auto-scan
		lda	#$7F
		sta	sheila_SYSVIA_ddra	; bit 7 in, others out

		lda	#LAT_CAPS+8
		sta	sheila_SYSVIA_orb
		lda	#LAT_SHIFT+8
		sta	sheila_SYSVIA_orb


		lda	#KEY_BS
		jsr	ks
		bpl	reboot
		lda	#KEY_CTRL
		jsr	ks
		bpl	reboot

		lda	#LAT_CAPS
		jsr	flash
		

		lda	#$40
		sta	zp_ctr		; number of pages to transfer

		lda	#^JIM_BOOT_BASE
		sta	fred_JIM_PAGE_HI
		lda	#>JIM_BOOT_BASE
		sta	fred_JIM_PAGE_LO
		ldy	#<JIM_BOOT_BASE

		; start SPI bulk read
		jsr	spi_reset
		ldx	#4
@hl:		lda	spi_head, X
		jsr	spi_write_cont
		dex	
		bpl	@hl

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
@badboot:	lda	#LAT_SHIFT
		jsr	flash


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
