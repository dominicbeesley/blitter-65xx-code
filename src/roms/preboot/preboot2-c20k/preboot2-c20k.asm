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

		.export initirq
		.export doneirq
		.export _testval


	.segment "ZPEXT":zeropage

zp_scrptr:	.res	2
zp_ctr:		.res	2
zp_dat_ptr:	.res	2


	.bss
irqcount:	.res 1
	.rodata

	.data
_testval:	.byte $55

	.code

initirq:	
		lda	#$AA
		sta	_testval
		lda     #.lobyte(__INTERRUPTOR_COUNT__*2)
        	sta     irqcount
;        	cli
        	rts

doneirq:	lda	#0
		sta	irqcount	; disable our handler
		rts

handle_irq:    	pha
        	txa
        	pha
        	tya
        	pha
        	tsx
        	lda     $104,x          ; Get the flags from the stack
        	and     #$10            ; Test break flag
        	bne     handle_brk

; It's an IRQ.

        	cld

; Call the chained IRQ handlers.

        	ldy     irqcount
        	beq     irqskip
	        jsr     callirq_y       ; Call the functions

; Done with the chained IRQ handlers; check the TPI for IRQs, and handle them.

irqskip:

        	pla
        	tay
        	pla
        	tax
        	pla
handle_nmi:    
		rti

handle_brk:	sei
		jmp	handle_brk


handle_reset:
		cld
		sei
		ldx	#$FF
		txs

		; set non-throttled, low-mem=turbo mode
		lda	#$7F
		sta	sheila_MEM_LOMEMTURBO
		lda	sheila_MEM_TURBO2
		and	#<~(BITS_MEM_TURBO2_THROTTLE|BITS_MEM_TURBO2_THROTTLE_MOS)
		sta	sheila_MEM_TURBO2

		; do some hardware cleanup before crt0 startup

		lda	#$7F
		sta	sheila_SYSVIA_ier	; TODO: we should maybe use this to detect hard/cold/boot and pass on to client


		ldx	#$0f
		stx	sheila_SYSVIA_ddrb
@slowb:		stx	sheila_SYSVIA_orb
		dex
		cpx	#8
		bcs	@slowb

		; page in rom E - assume this is RAM, 
		; TODO: check / report if not
		lda	#$E
		sta	sheila_ROMSEL

		jmp	crt0_startup


	.segment "VECS"	
v_nmi:		.addr	handle_nmi
v_res:		.addr	handle_reset
v_irq:		.addr	handle_irq
	.end
