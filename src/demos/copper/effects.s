
		.importzp tmp1, tmp2, ptr1, ptr2
		.import _pal_rainbow, _sintab, _rbo, _aeris_test_pgm_copper

		.export _effect_copper_bounce

_effect_copper_bounce:



		; p = (&aeris_test_pgm_copper);
		lda	#<(_aeris_test_pgm_copper+2)
		sta	ptr1
		lda	#>(_aeris_test_pgm_copper+2)
		sta	ptr1+1


		; //copper bounce
		; s = (&sintab)[rbo%128];
		; if (s < 0) s=-s;
		lda	_rbo
		and	#$7f
		tax
		lda	_sintab,X
		bpl	@s1
		eor	#$FF
		sec
		adc	#0
@s1:		
		; s = -(s >> 2);
		lsr	A
		lsr	A
		sta	tmp2
		lda	#32
		sec
		sbc	tmp2
		tax


		;j = 0;
		;while (s < 0) {
		;	p[2] = 0;
		;	p[3] = 0;
		;	s++;
		;	j++;
		;	p+=5;
		;}
		jsr	@clearX

		; q = (&pal_rainbow);
		lda	#<_pal_rainbow
		sta	ptr2
		lda	#>_pal_rainbow
		sta	ptr2+1

		; while (s < 32) {
		; 	p[2] = q[0];
		; 	p[3] = q[1];
		; 	p+=5;
		; 	q+=2;
		; 	s++;
		; 	j++;
		; }

		ldx	#32
		ldy	#0
@l2:		lda	(ptr2),Y
		sta	(ptr1),Y
		iny
		lda	(ptr2),Y
		sta	(ptr1),Y
		dey
		dex
		beq	@s5
		clc
		lda	ptr1
		adc	#5
		sta	ptr1
		bcc	@s3
		inc	ptr1+1
		clc
@s3:		lda	ptr2
		adc	#2
		sta	ptr2
		bcc	@l2
		inc	ptr2+1
		jmp	@l2

@s5:

		ldx	tmp2
		; drop thru

@clearX:
		ldy	#0

@l1:		txa
		beq	@s2
		tya		
		sta	(ptr1),Y
		iny
		sta	(ptr1),Y
		dey
		dex
		clc
		lda	ptr1
		adc	#5
		sta	ptr1
		bcc	@l1
		inc	ptr1+1
		bne	@l1
@s2:
		rts

