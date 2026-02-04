	.include "hardware.inc"

	.export _intoff
	.export _intrestore
	.export _jim_page
	.importzp tmp1

;; unsigned char intoff();

_intoff:
	php
	pla
	sei
	ldx	#0
	rts

;; void intrestore(unsigned char P);
_intrestore:
	pha
	plp
	rts


_jim_page:
	sta	tmp1

	lda	#JIM_DEVNO_BLITTER
	sta	fred_JIM_DEVNO

	lda	fred_JIM_PAGE_LO
	pha
	lda	tmp1
	sta	fred_JIM_PAGE_LO

	lda	fred_JIM_PAGE_HI
	pha
	stx	fred_JIM_PAGE_HI

	pla
	tax
	pla
	rts