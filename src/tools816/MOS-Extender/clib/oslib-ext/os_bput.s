		include oslib-ext.inc
		section "text","acrx"
		a16
		x16
		extern	retcheck
		global _xos_bput
_xos_bput:	tay			; (handle)
		lda	4,S		; (char)
		cop	#COP_0B_OPBPT
		jmp	retcheck


