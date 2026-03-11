

	.include "surface.inc"
	.include "zeropage.inc"


	.export _surface_from_rect

	.bss
temprect:	.tag rectangle

	.code

;;bool surface_from_rect(surface *parent, surface *new, const rectangle *clientrect) {

.proc	_surface_from_rect:near

	sta	ptr1
	stx	ptr1+1

	; temprect = *clientrect
	ldy	#.sizeof(rectangle) -1			
@lp:	lda	(ptr1), Y
	sta	temprect, Y
	dey
	bpl	@lp

	jsr	popax
	sta	ptr2
	stx	ptr2+1			; ptr2 = new

	jsr	popax
	sta	ptr3
	stx	ptr3+1			; ptr3 = parent

	lda	#0
	sta	tmp1			;; SCX = 0
	sta	tmp2			;; SCY = 0

	lda	temprect + rectangle::topleft + point::PX
	clc
	ldy	#surface::screenrect + rectangle::topleft + point::PX
	adc 	(ptr3),Y
	bvs	@bad2
	sec
	ldy	#surface::scroll + point::PX
	sbc	(ptr3),Y
	bvs	@bad2
	sta	tmp3			;; SX = r.topleft.X + parent->screenrect.topleft.X - parent->scroll.X;

	lda	temprect + rectangle::topleft + point::PY
	clc
	ldy	#surface::screenrect + rectangle::topleft + point::PY
	adc 	(ptr3),Y
	bvs	@bad2
	sec
	ldy	#surface::scroll + point::PY
	sbc	(ptr3),Y
	bvs	@bad2
	sta	tmp4			;; SY = r.topleft.Y + parent->screenrect.topleft.Y - parent->scroll.Y;

	;; left bound check

;; 	//left bound check
;; 	diff = parent->screenrect.topleft.X + parent->screenrect.size.W - (SX + r.size.W);
;; 	if (diff < 0)
;; 		r.size.W += diff;

;; 	if (r.size.W < 0) goto bad;

	lda	temprect + rectangle::size + size::W
	beq	@bad2
	bmi	@bad2
	eor	#$FF
	sec

	ldy	#surface::screenrect + rectangle::topleft + point::PX
	adc 	(ptr3),Y
	clc
	ldy	#surface::screenrect + rectangle::size + size::W
	adc 	(ptr3),Y
	bvs	@bad2
	sec
	sbc	tmp3
	bvs	@bad2
	bpl	@sk1
	
	clc
	adc	temprect + rectangle::size + size::W
	sta	temprect + rectangle::size + size::W
	bmi	@bad2
	beq	@bad2
@sk1:

	;; bottom bound check

;; 	//bottom bound check
;; 	diff = (parent->screenrect.topleft.Y + parent->screenrect.size.H) - (SY + r.size.H);
;; 	if (diff < 0)
;; 		r.size.H += diff;

; 	if (r.size.H < 0) goto bad;

	lda	temprect + rectangle::size + size::H
	beq	@bad2
	bmi	@bad2
	eor	#$FF
	sec

	ldy	#surface::screenrect + rectangle::topleft + point::PY
	adc 	(ptr3),Y
	clc
	ldy	#surface::screenrect + rectangle::size + size::H
	adc 	(ptr3),Y
	bvs	@bad2
	sec
	sbc	tmp4
	bvs	@bad2
	bpl	@sk2
	
	clc
	adc	temprect + rectangle::size + size::H
	sta	temprect + rectangle::size + size::H
	bmi	@bad2
	bne	@sk2
@bad2:	jmp	@bad
@sk2:

;; 	//right bound check
;; 	diff = SX - parent->screenrect.topleft.X;
;; 	if (diff < 0) {
;; 		r.size.W += diff;
;;	 	if (r.size.W < 0) goto bad;
;; 		SX -= diff;
;; 		SCX = -diff;
;; 	}

	lda	tmp3
	sec
	ldy	#surface::screenrect + rectangle::topleft + point::PX
	sbc	(ptr3),y
	bvs	@bad
	bpl	@sk3

	sta	sreg	; save it
	clc
	adc	temprect + rectangle::size + size::W
	sta	temprect + rectangle::size + size::W
	bmi	@bad
	beq	@bad
	
	lda	sreg
	eor	#$FF
	clc
	adc	#1
	sta	tmp1	; SCX

	clc
	adc	tmp3
	sta	tmp3	; SX
	bvs	@bad
@sk3:

;; 	//top bound check
;; 	diff = SY - parent->screenrect.topleft.Y;
;; 	if (diff < 0) {
;; 		r.size.H += diff;
;; 		if (r.size.H < 0) goto bad;	
;; 		SY -= diff;
;; 		SCY = -diff;
;; 	}

	lda	tmp4
	sec
	ldy	#surface::screenrect + rectangle::topleft + point::PY
	sbc	(ptr3),y
	bvs	@bad
	bpl	@sk4

	sta	sreg	; save it
	clc
	adc	temprect + rectangle::size + size::H
	sta	temprect + rectangle::size + size::H
	bmi	@bad
	beq	@bad
	
	lda	sreg
	eor	#$FF
	clc
	adc	#1
	sta	tmp2	; SCY

	clc
	adc	tmp4
	sta	tmp4	; SY
	bvs	@bad
@sk4:
	
;; 	new->screenrect.topleft.X = SX;
;; 	new->screenrect.topleft.Y = SY;
;; 	new->screenrect.size.W = r.size.W;
;; 	new->screenrect.size.H = r.size.H;
;; 	new->scroll.X = SCX;
;; 	new->scroll.Y = SCY;
	ldy	#0
	lda	tmp3
	sta	(ptr2), Y		; topleft.X
	iny
	lda	tmp4
	sta	(ptr2), Y		; topleft.Y
	iny

	lda	temprect + rectangle::size + size::W
	sta	(ptr2), Y		; size.W
	iny
	lda	temprect + rectangle::size + size::H
	sta	(ptr2), Y		; size.H
	iny

	lda	tmp1
	sta	(ptr2), Y		; scroll.X
	iny
	lda	tmp2
	sta	(ptr2), Y		; scroll.Y


; 	return 1;
	lda	#1
	ldx	#0
	rts


@bad:
	lda	#0
	tax
	rts
	
.endproc