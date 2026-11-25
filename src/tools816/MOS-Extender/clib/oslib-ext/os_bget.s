		include oslib-ext.inc
		section "text","acrx"
		a16
		x16
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

