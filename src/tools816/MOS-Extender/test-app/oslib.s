	include oslib.inc 
	
	section	"DONTMERGE_text.far.create.0","acrx"
	a16
	x16
	global	_os_wrch
_os_wrch:

	COP	#00		;; call OS

	rtl
