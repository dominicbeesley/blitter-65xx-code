		include oslib-ext.inc
		section "text","acrx"
		a16
		x16
		extern	retcheck
		global _xos_byte_ret
_xos_byte_ret:	phd
		tax			; save A - reason code
		tsc
		tcd
		sep	#$30
		a8
		x8

		lda	[6]
		xba			; H=passed in X
		lda	[10]
 		tay			; Y = Y param
		txa
		xba			; A = X param, B = reason
		tax
		xba                     	; A = reason
		cop	#COP_06_OPOSB
		bvs	.rr		; preserve AX if error
		txa
		sta	[6]
		tya
		sta	[10]		
.rr:		rep	#$30
		a16
		x16
		pld
		jmp	retcheck	
