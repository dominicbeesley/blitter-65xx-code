		.include "mosrom.inc"
		.include "oslib.inc"
		.include "oslib-nat.inc"

		.export 	handle_nat_irq
		.importzp 	TRAMPO_NAT2EMU
		.importzp 	TRAMPO_EMU2NAT

		.importzp 	zp_emu_sp
		.importzp 	zp_nat_sp


		.segment	"NATHANDLER"

handle_nat_irq:	; save _all_ regs (possibly 16 bit)
		rep	#$30
		.a16
		.i16
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

		.code
		.a8
		.i8
handle_nat_irq_out:
		; back from emu mode irq

		lda	#^handle_nat_irq_out_2
		pha
		pea	handle_nat_irq_out_2
		php
		jml	TRAMPO_EMU2NAT

		.segment	"NATHANDLER"
handle_nat_irq_out_2:		
		; swap to nat stack
		tsx
		stx	zp_emu_sp

		rep	#$30
		.a16
		.i16
		lda	zp_nat_sp
		tcs		

		pld
		plb
		ply
		plx
		pla
		rti

