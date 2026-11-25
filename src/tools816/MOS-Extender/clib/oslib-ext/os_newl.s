		include oslib-ext.inc
		section "text","acrx"
		a16
		x16
		extern	retcheck
		global   _xos_newl
_xos_newl:	cop	#COP_03_OPNLI	;; call OS
		jmp	retcheck

