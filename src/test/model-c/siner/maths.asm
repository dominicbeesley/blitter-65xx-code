


		.import sintab

		.importzp zp_acc
		.export math_sin
		.export math_cos

		.zeropage

zp_math_ptr:	.res 2

		.code

	; on entry ax contains 0..1024
	; on exit zp_acc contains -32768..32767
math_sin:	clc
sin_int:	pha
		txa
		adc	#0
		and	#3
		clc		
		adc	#>sintab
		sta	zp_math_ptr+1
		lda	#<sintab
		sta	zp_math_ptr
		pla
		and	#$FE
		tay
		lda	(zp_math_ptr),Y
		sta	zp_acc
		iny
		lda	(zp_math_ptr),Y
		sta	zp_acc+1
		rts

math_cos:	sec
		bcs	sin_int
