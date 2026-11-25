		include oslib-ext.inc
		section "text","acrx"
		a16
		x16
		extern	retcheck
		global _xos_gbpb
_xos_gbpb:	and	#$00FF
		tay			; function code
		lda	6,S
		tax
		lda	4,S
		cop	#COP_4C_OPGBPB
		jmp	retcheck

