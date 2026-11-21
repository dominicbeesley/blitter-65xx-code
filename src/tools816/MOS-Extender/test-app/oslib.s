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
_os_writes:	ldy	#0
		; pointer in X/A
		cop	#COP_02_OPWRA
		rtl

		global _os_word
_os_word:	tay			; reason code
		lda	6,S
		tax
		lda	4,S

		cop	#COP_07_OPOSW

		; note this won't return Y for RDLIN
		rtl
		
		global _os_find_open
_os_find_open:	
		pha
		lda	6,S
		tay
		pla
		cop	#COP_44_OPOPN
		bvs	.reterr

		lda 	6,S
		sta 	<r0
		lda 	8,S
		sta 	<r0+2

		tya
		sta	[r0]
		lda	#0
		tax

.reterr:	rtl

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

		global _os_bput
_os_bput:	tay			; (handle)
		lda	4,S		; (char)
		cop	#COP_0B_OPBPT
		rtl


		global _os_gbpb
_os_gbpb:	tay			; function code
		lda	6,S
		tax
		lda	4,S
		cop	#COP_4C_OPGBPB
		bvs	.err
		lda	#0
		tax
.err:		rtl

		global _os_file
_os_file:	tay			; function code
		lda	6,S
		tax
		lda	4,S
		cop	#COP_0C_OPFILE
		bvs	.err
		lda	#0
		tax
.err:		rtl





