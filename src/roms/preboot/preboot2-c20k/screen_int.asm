	.export		_screen_addr
	.importzp	sp, sreg, regsave, regbank
	.importzp	tmp1, tmp2, tmp3, tmp4, ptr1, ptr2, ptr3, ptr4

; ---------------------------------------------------------------
; __near__ unsigned char * __near__ screen_addr (const point *p)
; ---------------------------------------------------------------

.segment	"CODE"

.proc	_screen_addr: near

	.dbg	func, "screen_addr", "00", extern, "_screen_addr"
	.dbg	sym, "x", "00", auto, 1
	.dbg	sym, "y", "00", auto, 0

	sta	ptr1
	stx	ptr1+1

	ldy	#0
	lda	(ptr1),Y
	bmi	@badaddr
	cmp	#$28
	bcs	@badaddr
	pha			; X checked and on machine stack

	iny
	lda	(ptr1),Y
	bmi	@badaddr2
	cmp	#$19
	bcs	@badaddr2
	sta	tmp1

	asl	A
	asl	A
	adc	tmp1		; *5
	asl	A		; *10
	sta	tmp1
	lda	#0
	asl	tmp1		; *20
	rol	A
	asl	tmp1		; *40
	rol	A
	ora	#$7C
	tax
	pla			; X saved above add to AX
	adc	tmp1
	bcc	@s
	inx
@s:	rts


@badaddr:
	pla
@badaddr2:
	lda	#$FF
	tax
	rts

.endproc