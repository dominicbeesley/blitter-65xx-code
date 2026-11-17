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

		global _os_word
_os_word:	phb		

		sta	<r2
		lda	5,S
		sta	<r0
		lda	7,S
		sta	<r1
		ldy	<r2

		; is now r0/r1 points at block, Y contains reason code
		phk		; make an off push on stack
		lda	<r1
		pha
		plb
		pla
		lda	<r0
		cop	#COP_07_OPOSW

		; note this won't return Y for RDLIN
		plb
		rtl
