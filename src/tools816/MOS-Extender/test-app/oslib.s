		include oslib-nat.inc 
	
		section	"DONTMERGE_text.far.create.0","acrx"
		a16
		x16

		global	_xos_wrch
_xos_wrch:	cop	#COP_00_OPWRC	;; call OS
		jmp	retcheck

		global   _xos_newl
_xos_newl:	cop	#COP_03_OPNLI	;; call OS
		jmp	retcheck

		global	_xos_writes
_xos_writes:	ldy	#0
		; pointer in X/A
		cop	#COP_02_OPWRA
		jmp	retcheck

		global _xos_word
_xos_word:	and	#$00FF
		tay			; reason code
		lda	6,S
		tax
		lda	4,S

		cop	#COP_07_OPOSW

		; note this won't return Y for RDLIN
		jmp	retcheck
		
		global _xos_find_open
_xos_find_open:	
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

		global _xos_find_close
_xos_find_close:	
		tay
		cop	#COP_45_OPCLS		
retcheck:	bvs	.reterr
		lda	#0
		tax
.reterr:	rtl

		global _xos_bget
_xos_bget:	tay			; (handle)
		lda 	4,S
		sta	<r0
		lda 	6,S
		sta	<r0+2
		cop	#COP_0A_OPBGT
		bvs	.reterr
		bcc	.neof
		; Cy=EOF
		lda	#$FFFF		; -1 = EOF
.neof:		sta	[r0]
		lda	#0
		tax
.reterr		rtl

		global _xos_bput
_xos_bput:	tay			; (handle)
		lda	4,S		; (char)
		cop	#COP_0B_OPBPT
		jmp	retcheck


		global _xos_gbpb
_xos_gbpb:	and	#$00FF
		tay			; function code
		lda	6,S
		tax
		lda	4,S
		cop	#COP_4C_OPGBPB
		jmp	retcheck

		global _xos_file
_xos_file:	and	#$00FF
		tay			; function code
		lda	6,S
		tax
		lda	4,S
		cop	#COP_0C_OPFILE
		jmp	retcheck





