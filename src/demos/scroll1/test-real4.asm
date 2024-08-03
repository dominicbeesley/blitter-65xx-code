; MIT License
; 
; Copyright (c) 2023 Dossytronics
; https://github.com/dominicbeesley/blitter-65xx-code
; 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

		.include	"oslib.inc"
		.include	"common.inc"
		.include	"hardware.inc"
		.include	"blit_lib.inc"


vec_nmi		:=	$D00

		.ZEROPAGE

zp_xstart:	.RES		1			; single byte signed x offset for first char
zp_txt_ptr:	.RES		2			; word pointer for current first char of scrolltext
zp_cur_char:	.RES		1			; current char (offset from zp_txt_ptr)
zp_x:		.RES		2			; 16 bit signed X
zp_acc:		.RES		2			; temp / accumulator

		.SEGMENT "SCREEN"
SCREEN_BASE:

B_SHADOW	:=	$020000
B_BACK_SAV	:=	$030000
B_FONT_SPR	:=	$041000				; must be page aligned for calcs
B_FONT_MAS	:=	$047000

		.CODE 

		ldx	#<backosfile
		ldy	#>backosfile
		lda	#$FF
		jsr	OSFILE

		ldx	#<blit_save_bkg
		ldy	#>blit_save_bkg
		jsr	_blit_ctl_full
		ldx	#<blit_bkg_1st
		ldy	#>blit_bkg_1st
		jsr	_blit_ctl_full


		lda	#$E5
		ldx	#$FF
		ldy	#0
		jsr	OSBYTE				; escape as a key

		; init
		lda	#15
		sta	zp_xstart
		jsr	restart_scroller

@lp:
		lda	#$79
		ldx	#$80 + $70			; escape
		jsr	OSBYTE
		txa
		bpl	@noesc				


		lda	#$E5
		ldx	#0
		ldy	#0
		jsr	OSBYTE				; reset escape

		lda	#$0F
		ldx	#1
		jsr	OSBYTE				; flush input buffer

		rts
@noesc:
		lda	#$FF
		sta	sheila_reg_debug

		lda	#19
		jsr	OSBYTE

		lda	#0
		sta	sheila_reg_debug


		lda	#$79
		ldx	#$80
		jsr	OSBYTE
		txa
		bpl	@sk_shift			; stop if shift
		lda	#0
		sta	keystate
		jmp	@lp
@sk_shift:	

		lda	#$79
		ldx	#$81
		jsr	OSBYTE
		txa
		and	#$80
		eor	keystate
		bmi	@ctlch
		beq	@sk_ctrl
		bne	@lp
@ctlch:		txa
		ora	#1
		sta	keystate

@sk_ctrl:	

		ldx	#<blit_shadow2screen
		ldy	#>blit_shadow2screen
		jsr	_blit_ctl_full

		ldx	#<blit_bkg
		ldy	#>blit_bkg
		jsr	_blit_ctl_full

		jsr	render_scroll_line

		jmp	@lp

render_scroll_line:
		; initialize X
		lda	#0
		sta	zp_cur_char
		lda	zp_xstart
		sta	zp_x				; sign extend X
		ora	#$7F
		bmi	@n
		lda	#0
@n:		sta	zp_x + 1
@scroll_intra_line_loop:
		ldy	zp_cur_char
		lda	(zp_txt_ptr),Y
		bne	@sk2
		jmp	@atendoftext
@sk2:		inc	zp_cur_char
		jsr	mapchar
		cmp	#' '
		bne	@sk3
		jmp	@skip_space
		; calculate address of sprite B_FONT_SPR + 16 * (c mod 8) + &1800*(c div 8)
@sk3:		pha
		and	#$07
		asl
		asl
		asl
		asl
		sta	blit_ctl + block_ADDR_B_offs + 0	; lo byte
		pla
		pha
		and	#$18
		sta	zp_acc
		asl
		adc	zp_acc
		adc	#>B_FONT_SPR
		sta	blit_ctl + block_ADDR_B_offs + 1; hi byte
		; calculate address of mask B_FONT_MAS + 4 * (c mod 8) + &600 * (c div 8)
		pla
		pha
		and	#$07
		asl
		asl
		sta	blit_ctl + block_ADDR_A_offs + 0
		pla
		clc
		and	#$18
		ror
		sta	zp_acc
		ror
		adc	zp_acc
		adc	#>B_FONT_MAS
		sta	blit_ctl + block_ADDR_A_offs + 1
		; calculate screen address = $1900 + 8*(x div 2); shift = x mod 2
		lda	zp_x
		and	#$FE
		sta	zp_acc
		lda	zp_x + 1
		asl	zp_acc
		rol	a
		asl	zp_acc
		rol	a
		clc
		adc	#$19
		sta	blit_ctl + block_ADDR_C_offs + 1
		lda	zp_acc
		sta	blit_ctl + block_ADDR_C_offs + 0
		ldx	#$0
		ldy	#15
		lda	zp_x
		ror	a
		lda	#$FF
		bcc	@sk1
		ldx	#$1
		ldy	#16
		lda	#$7F
@sk1:		
		sta	blit_ctl + block_MASK_FIRST_offs
		bmi	@sk4
		lda	#$80
@sk4:		
		sta	blit_ctl + block_MASK_LAST_offs
		stx	blit_ctl + block_SHIFT_A_offs
		sty	blit_ctl + block_WIDTH_offs

		; check left screen edge violation
		lda	zp_x + 1
		bpl	@sk8
		lda	zp_x
		eor	#$FF
		clc
		ror	a
		sec
		adc	#0			; A = -X/2
@lp8:		cmp	#4
		bcc	@no8
		pha								; more than 4 move a whole 8 pixels along
		
		lda	blit_ctl + block_WIDTH_offs
		sec
		sbc	#4							; subtract 4 from width
		sta	blit_ctl + block_WIDTH_offs

		lda	blit_ctl + block_ADDR_C_offs + 0
		clc
		adc	#32							; add 32 to screen address
		sta	blit_ctl + block_ADDR_C_offs + 0

		lda	blit_ctl + block_ADDR_C_offs + 1
		adc	#0
		sta	blit_ctl + block_ADDR_C_offs + 1

		lda	blit_ctl + block_ADDR_B_offs + 0
		adc	#4
		sta	blit_ctl + block_ADDR_B_offs + 0				; add 4 to sprite pointer
		inc	blit_ctl + block_ADDR_A_offs + 0				; and 1 to mask
		pla
		sec
		sbc	#4
		beq	@sk5
		bne	@lp8

@no8:		tax
		lda	masks_left, X
		sta	blit_ctl + block_MASK_FIRST_offs
		jmp	@sk5

@sk8:		; see if we'll go off screen at right
		lda	zp_x + 1
		ror	a
		lda	zp_x
		ror	a			; X/2
		clc
		adc	blit_ctl + block_WIDTH_offs
		sbc	#79
		bcc	@sk5
		; adjust width
		eor	#$FF
		clc
		adc	blit_ctl + block_WIDTH_offs
		sta	blit_ctl + block_WIDTH_offs
		lda	#$FF
		sta	blit_ctl + block_MASK_LAST_offs
@sk5:

		ldx	#<blit_ctl
		ldy	#>blit_ctl
		jsr	_blit_ctl_full



@skip_space:						; got a space
		lda	#32
		clc
		adc	zp_x
		sta	zp_x
		lda	zp_x+1
		adc	#0
		sta	zp_x+1
		lda	zp_x
		cmp	#160
		bcs	@atendofline
		jmp	@scroll_intra_line_loop		; next char



@atendoftext:						; encountered 0 don't render rest of line
@atendofline:
		dec	zp_xstart
		lda	zp_xstart
		cmp	#256-32
		bne	@sk7
		lda	#0
		sta	zp_xstart
		inc	zp_txt_ptr
		bne	@sk6
		inc	zp_txt_ptr + 1
@sk6:		ldy	#0
		lda	(zp_txt_ptr),Y
		bne	@sk7
		jsr	restart_scroller
@sk7:		rts

restart_scroller:
		lda	#<scrolltext
		sta	zp_txt_ptr
		lda	#>scrolltext
		sta	zp_txt_ptr + 1
		rts


mapchar:	; convert an ASCII char to sprite number 32 == space and EQ, >$80 and MI equals unknown
		and	#$DF		; to uppercase
		beq	@space
		cmp	#'A'
		bcc	@notalpha
		cmp	#'Z'+1
		bcs	@notalpha
		sbc	#'A'-1
		rts
@notalpha:
		cmp	#'!' & $DF
		beq	@pling
		cmp	#'.' & $DF
		beq	@dot
		cmp	#',' & $DF
		beq	@comma
		cmp	#'?' & $DF
		beq	@ques
		cmp	#'1' & $DF
		beq	@one
		cmp	#'2' & $DF
		beq	@two
		lda	#$80
		rts
@pling:		lda	#26
		rts
@dot:		lda	#27
		rts
@comma:		lda	#28
		rts
@ques:		lda	#29
		rts
@one:		lda	#30
		rts
@two:		lda	#31
		rts
@space:		lda	#' '
		rts


;;PRHEX:		pha
;;		ror	a
;;		ror	a
;;		ror	a
;;		ror	a
;;		jsr	PRHEXDIG
;;		pla
;;PRHEXDIG:	and	#$0F
;;		cmp	#10
;;		bcc	@sk1
;;		adc	#6
;;@sk1:		adc	#'0'
;;		jmp	OSWRCH

		.DATA

masks_left:	.byte	$FF, $3F, $0F, $03

		.global blit_ctl
blit_ctl:
		.byte	BLITCON_EXEC_A+BLITCON_EXEC_B+BLITCON_EXEC_C+BLITCON_EXEC_D	; execD, execC, execB, execA	BLTCON
		.byte	$CA								; copy B to D, mask A, C	FUNCGEN
		.byte	$FF								;				MASK_FIRST
		.byte	$FF								;				MASK_LAST
		.byte	15								; 				WIDTH
		.byte	47								;				HEIGHT
		.byte	$00								;				SHIFT A
		.byte	0	;SPARE
		.word	32								;				STRIDE_A
		.word	128								;				STRIDE_B
		.word	640								;				STRIDE_C/D
		.word	0	;SPARE
		ADDR24	B_FONT_MAS							;				ADDR_A
		.byte	$AA								;				DATA_A
		ADDR24	B_FONT_SPR							;				ADDR_B
		.byte	$55								;				DATA_B
		ADDR24	B_SHADOW+$1900							;				ADDR_C/D
		.byte	0								;				DATA_C
		ADDR24	0								;				ADDR_E
		.byte	BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_4BBP		; BLTCON act, cell, 4bpp

blit_bkg:	
		.byte	BLITCON_EXEC_B+BLITCON_EXEC_D+BLITCON_CELL_B			; 				BLTCON  
		.byte	$CC								; copy B to D			FUNCGEN
		.byte	$FF								;				MASK_FIRST
		.byte	$FF								;				MASK_LAST
		.byte	80								; 				WIDTH
		.byte	48								;				HEIGHT
		.byte	$00								;				SHIFT_a
		.byte	0	;SPARE
		.word	0								;				STRIDE_A
		.word	640								;				STRIDE_B
		.word	640								;				STRIDE_C/D
		.word	0	; SPARE
		ADDR24	0								;				ADDR_A
		.byte	0								;				DATA_A
		ADDR24	B_BACK_SAV + $1900						;				ADDR_B
		.byte	0								;				DATA_B
		ADDR24	B_SHADOW + $1900						;				ADDR_C/D
		.byte	0								;				DATA_C
		ADDR24	0								;				ADDR_E
		.byte	BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_4BBP		; BLTCON act, cell, 4bpp

blit_bkg_1st:	
		.byte	BLITCON_EXEC_B+BLITCON_EXEC_D+BLITCON_CELL_B			; exec B,D B in cell mode	BLTCON
		.byte	$CC								; copy B to D			FUNCGEN
		.byte	$FF								;				MASK_FIRST
		.byte	$FF								;				MASK_LAST
		.byte	80								; 				WIDTH
		.byte	255								;				HEIGHT
		.byte	$00								;				SHIFT_A
		.byte	0	; SPARE
		.word	0								;				STRIDE_A
		.word	640								;				STRIDE_B
		.word	640								;				STRIDE_C
		.word	0	; SPARE
		ADDR24	0								;				ADDR_A
		.byte	0								;				DATA_A
		ADDR24	B_BACK_SAV							;				ADDR_B
		.byte	0								;				DATA_B		
		ADDR24	B_SHADOW							;				ADDR_C/D
		.byte	0								;				DATA_C
		ADDR24	0								;				ADDR_E
		.byte	BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_4BBP		; BLTCON act, cell, 4bpp



blit_save_bkg:	
		.byte	BLITCON_EXEC_B+BLITCON_EXEC_D+BLITCON_CELL_B			; exec B,D B in cell mode	BLTCON
		.byte	$CC								; copy B to D			FUNCGEN
		.byte	$FF								;				MASK_FIRST
		.byte	$FF								;				MASK_LAST
		.byte	80								; 				WIDTH
		.byte	255								;				HEIGHT
		.byte	$00								;				SHIFT_A
		.byte	0	; SPARE
		.word	32								;				STRIDE_A
		.word	640								;				STRIDE_B
		.word	640								;				STRIDE_C/D
		.word	0	; SPARE
		ADDR24	0								;				ADDR_A
		.byte	0								;				DATA_A
		ADDR24	$FF3000								;				ADDR_B
		.byte	0								;				DATA_B
		ADDR24	B_BACK_SAV							;				ADDR_C/D
		.byte	0								;				DATA_C
		ADDR24	0								;				ADDR_E
		.byte	BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_4BBP		; BLTCON act, cell, 4bpp
						
blit_shadow2screen:	
		.byte	BLITCON_EXEC_B+BLITCON_EXEC_D+BLITCON_CELL_B			; exec B,D B in cell mode	BLTCON
		.byte	$CC								; copy B to D			FUNCGEN
		.byte	$FF								;				MASK_FIRST
		.byte	$FF								;				MASK_LAST
		.byte	80								; 				WIDTH
		.byte	255								;				HEIGHT
		.byte	$00								;				SHIFT
		.byte	0	; SPARE
		.word	0								;				STRIDE_A
		.word	640								;				STRIDE_B
		.word	640								;				STRIDE_C/D
		.word	0	; SPARE
		ADDR24	0								;				ADDR_A
		.byte	0								;				DATA_A
		ADDR24	B_SHADOW							;				ADDR_B
		.byte	0								;				DATA_B
		ADDR24	$FF3000								;				ADDR_C/D
		.byte	$0								;				DATA_C
		ADDR24	$0								;				ADDR_E
		.byte	BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_4BBP		; BLTCON act, cell, 4bpp



scrolltext:	.byte	"...............Hello Stardot     Blitter hardware demo with double buffering................", 0

backstr:	.byte	"S.BACK", $D
backosfile:	.word	backstr
		.word	$2FD0
		.word	$FFFF
		.byte	0

keystate:	.byte	0

		.END
