		include oslib-ext.inc
		section "text","acrx"
		a16
		x16
		extern	retcheck
		global	_xos_wrch
_xos_wrch:	cop	#COP_00_OPWRC	;; call OS
		jmp	retcheck

