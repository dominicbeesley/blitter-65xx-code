		include "mosrom.inc"
		include "oslib.inc"
		include "oslib-nat.inc"

		global 	handle_nat_irq
		global 	TRAMPO_NAT2EMU

		global 	zp_emu_sp
		zpage	zp_emu_sp
		global 	zp_nat_sp
		zpage	zp_nat_sp


		section	.nat_handler_text, "acrx"

		global handle_nat_irq
handle_nat_irq:	; save _all_ regs (possibly 16 bit)
		rep	#$30
		a16
		x16
		pha
		phx
		phy
		phb
		phd


		; swap to bank 0 data and direct page
		lda	#0
		tcd
		pha
		plb
		plb

		; swap to emu stack

		lda	zp_emu_sp
		and	#$00FF
		ora	#$0100

		tsx
		stx	zp_nat_sp

		tcs

		; switch to emu mode and call IRQ1V

		; push 8-bit RTI
		pea	handle_nat_irq_out
		php

		; push 8-bit RTI to enter IRQ1V
		lda	IRQ1V
		pha
		php

		jml	TRAMPO_NAT2EMU

		section .text
		a8
		x8
handle_nat_irq_out:
		; back from emu mode irq

		lda	#^handle_nat_irq_out_2
		pha
		pea	handle_nat_irq_out_2
		php
		jml	TRAMPO_EMU2NAT

		section	.nat_handler_text, "acrx"
handle_nat_irq_out_2:		
		; swap to nat stack
		tsx
		stx	zp_emu_sp

		rep	#$30
		a16
		x16
		lda	zp_nat_sp
		tcs		

		pld
		plb
		ply
		plx
		pla
		rti

