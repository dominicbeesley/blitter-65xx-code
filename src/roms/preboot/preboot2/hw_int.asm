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

	
;; extern void keyb_irq_t1(void);
;; extern void keyb_irq_ca2(void);
;; unsigned char hw_interrupt(void) {


	.export	_hw_interrupt:near
	.proc	_hw_interrupt:near

	lda	sheila_SYSVIA_ifr
	and	sheila_SYSVIA_ier

	bpl	@sknovia

	and	#$7F
	pha

	and	#VIA_IFR_BIT_T1
	beq	@skt1
	
	; T1 interrupt
	inc	_time
	bne	@st
	inc	_time+1
	bne	@st
	inc	_time+2
	bne	@st
	inc	_time+3
@st:
	lda	sheila_SYSVIA_ier
	and	#VIA_IFR_BIT_CA2
	bne	@skendvia
	jsr	_keyb_irq_t1
	jmp	@skendvia
@skt1:	pla
	pha
	and	#VIA_IFR_BIT_CA2
	beq	@skendvia
	jsr	_keyb_irq_ca2
@skendvia:
	pla
	sta	sheila_SYSVIA_ifr

@sknovia:
	lda	#1
	ldx	#0
	rts


	.endproc
