		include oslib-ext.inc
		section "text","acrx"
		a16
		x16
		global _xos_find_close
_xos_find_close:	
		tay
		cop	#COP_45_OPCLS		
