		include oslib-ext.inc
		section "text","acrx"
		a16
		x16
		extern	retcheck
		global _xos_word
_xos_word:	and	#$00FF
		tay			; reason code
		lda	6,S
		tax
		lda	4,S

		cop	#COP_07_OPOSW

		; note this won't return Y for RDLIN
		jmp	retcheck
		
