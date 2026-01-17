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


	.rodata
	.code
handle_nmi:
handle_irq:
		rti


handle_reset:
		cld
		sei
		ldx	#$FF
		txs

		; do some hardware cleanup before crt0 startup


		lda	#$7F
		sta	sheila_SYSVIA_ier	; TODO: we should maybe use this to detect hard/cold/boot and pass on to client


		ldx	#$0f
		stx	sheila_SYSVIA_ddrb
@slowb:		stx	sheila_SYSVIA_orb
		dex
		cpx	#8
		bcs	@slowb

		jmp	crt0_startup


	.segment "VECS"	
v_nmi:		.addr	handle_nmi
v_res:		.addr	handle_reset
v_irq:		.addr	handle_irq
	.end
