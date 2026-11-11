		include oslib-nat.inc 
	
		section	"DONTMERGE_text.far.create.0","acrx"
		a16
		x16

		global	_os_wrch
_os_wrch:	cop	#COP_00_OPWRC	;; call OS
		rtl

		global   _os_newl
_os_newl:	cop	#COP_03_OPNLI	;; call OS
		rtl

		global	_os_writes
_os_writes:	; pointer in X/A
		sep	#$10
		phx
		plb
		rep	#$10
		ldx	#0
		cop	#COP_02_OPWRA
		rtl