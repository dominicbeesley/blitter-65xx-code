		include oslib-ext.inc
		section "text","acrx"
		a16
		x16
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
