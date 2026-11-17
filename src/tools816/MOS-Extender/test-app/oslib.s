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
		
		global _os_find_open
_os_find_open:	phb
		phd
		phk
		phx
		pha

		; stack	
		;	14..17  handle pointer
		;	12..13	mode
		;	9..11	RTL
		;	8	B
		;	6..7	D
		;	5	- dummy (for easy cleanup)
		;	1..4	X/A pointer

		lda	12,S
		and	#$00FF
		tay			; mode

		pla
		plb
		pld			; discard stuff
		cop	#COP_44_OPOPN

		; stack	
		;	9..12	handle pointer
		;	7..8	mode
		;	4..6	RTL
		;	3	B
		;	1..2	D


		bcs	.err

		tsc
		tcd

		tya
		sta	[<9]

		lda	#0
		tax
		pld
		plb
		rtl

.err:		pha
		sep	#$30
		phb
		plx
		rep	#$30
		tsc
		tcd
		lda	#0
		sta	[<11]		
		pla
		pld
		plb
		rtl

		global _os_find_close
_os_find_close:	
		tay
		cop	#COP_45_OPCLS

		; assume no error
		lda	#0
		tax
		rtl

		global _os_bget
_os_bget:	tay			; (handle)
		cop	#COP_0A_OPBGT
		bcc	.ok
		; Cy=EOF
		lda	#$FFFF		; -1 = EOF
		rtl
.ok:		and	#$00FF
		rtl

