		include oslib-ext.inc
		section "text","acrx"
		a16
		x16
		extern	retcheck
		global _xos_file
_xos_file:	and	#$00FF
		tay			; function code
		lda	6,S
		tax
		lda	4,S
		cop	#COP_0C_OPFILE
		jmp	retcheck






