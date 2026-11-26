		include oslib-ext.inc
		section "text","acrx"
		a16
		x16
		extern	retcheck
		global _xos_byte
_xos_byte:	pha
		lda	6,S
		tax
		lda 	8,S
		tay	
		pla

		cop	#COP_06_OPOSB
	
		jmp	retcheck
		
