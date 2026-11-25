		include oslib-ext.inc
		section "text","acrx"
		a16
		x16
		extern	retcheck
		global	_xos_writes
_xos_writes:	ldy	#0
		; pointer in X/A
		cop	#COP_02_OPWRA
		jmp	retcheck

