		include oslib-ext.inc
		section "text","acrx"
		a16
		x16
		global	retcheck

retcheck:	bvs	.reterr
		lda	#0
		tax
.reterr:	rtl

