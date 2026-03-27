	.export		_screen_addr
	.importzp	sp, sreg, regsave, regbank
	.importzp	tmp1, tmp2, tmp3, tmp4, ptr1, ptr2, ptr3, ptr4

	.include "hardware.inc"

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
	sta	tmp1
	iny
	lda	(ptr1),Y
	sta	tmp2
	; fall thru to _screen_addr_int
.endproc


	; tmp1 = X
	; tmp2 = Y
.proc	_screen_addr_int: near

	lda	tmp1
	bmi	@badaddr
	cmp	#$28
	bcs	@badaddr
	pha			; X checked and on machine stack

	lda	tmp2
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
@s:	clc
	rts


@badaddr:
	pla
@badaddr2:
	lda	#$FF
	tax
	sec
	rts

.endproc

;; void screen_init(void)

	.export  _screen_init
.proc _screen_init:near
	lda	#$4B
	sta	sheila_VIDPROC
	ldx	#13
@lp:	stx	sheila_CRTC_IX
	lda	mo7_crtc, X
	sta	sheila_CRTC_DAT
	dex
	bpl	@lp

	lda	#0
	tax

	rts
.endproc



;;void screen_print_at(const point *sp, char c) {

	.export _screen_print_at
.proc _screen_print_at:near
	pha
	jsr	popax
	jsr	_screen_addr	
	bcs	@o
	sta	ptr1
	stx	ptr1+1
	pla
	ldy	#0
	sta	(ptr1),Y
@o2:	lda	#0
	tax
	rts
@o:	pla
	jmp	@o2
.endproc




	.rodata

mo7_crtc: 
	.byte $3f				; 0 Horizontal Total	 =64
	.byte $28				; 1 Horizontal Displayed =40
	.byte $33				; 2 Horizontal Sync	 =&33  Note: &31 is a better value
	.byte $24				; 3 HSync Width+VSync	 =&24  VSync=2, HSync=4
	.byte $1e				; 4 Vertical Total	 =30
	.byte $02				; 5 Vertical Adjust	 =2
	.byte $19				; 6 Vertical Displayed	 =25
	.byte $1b				; 7 VSync Position	 =&1B
	.byte $93				; 8 Interlace+Cursor	 =&93  Cursor=2, Display=1, Interlace=Sync+Video
	.byte $12				; 9 Scan Lines/Character =19
	.byte $72				; 10 Cursor Start Line	  =&72	Blink=On, Speed=1/32, Line=18
	.byte $13				; 11 Cursor End Line	  =19
	.byte $28				; 12 start H
	.byte $0					; 13 start L

