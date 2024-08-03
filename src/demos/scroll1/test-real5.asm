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
		.include	"mosrom.inc"



		.ZEROPAGE

zp_xstart:	.RES		1			; single byte signed x offset for first char
zp_txt_ptr:	.RES		2			; word pointer for current first char of scrolltext
zp_cur_char:	.RES		1			; current char (offset from zp_txt_ptr)
zp_x:		.RES		2			; 16 bit signed X
zp_acc:		.RES		2			; temp / accumulator
zp_save_ptr:	.RES		2			; pointer to next save block
zp_save_ctr:	.RES		1

save_b_scr	:=	$0				; screen pointer
save_b_save	:=	$2				; sram pointer where data is saved
save_b_width	:=	$5
save_b_height	:=	$6
save_b_size	:=	$7

		.SEGMENT "SCREEN"
SCREEN_BASE:

B_FONT_SPR	:=	$001000				; must be page aligned for calcs
B_FONT_MAS	:=	$007000
B_BACK_SAV	:=	$010000
B_SHADOW	:=	$020000

B_SCREEN_1	:=	$FF3000				; where background is loaded to

		.CODE 

		; naughty - set jim dev but don't bother saving old 
		lda	#JIM_DEVNO_BLITTER
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO
		lda	#<jim_page_CHIPSET
		sta	fred_JIM_PAGE_LO
		lda	#>jim_page_CHIPSET
		sta	fred_JIM_PAGE_HI


		ldx	#<backosfile
		ldy	#>backosfile
		lda	#$FF
		jsr	OSFILE

		ldx	#<blit_bkg_1st
		ldy	#>blit_bkg_1st
		jsr	_blit_ctl_full

		lda	#12
		jsr	OSWRCH

		lda	#$E5
		ldx	#$FF
		ldy	#0
		jsr	OSBYTE				; escape as a key

		; init
		lda	#15
		sta	zp_xstart
		jsr	restart_scroller

		lda	#0
		sta	zp_save_ctr


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


@restore_loop:
		; see if there's anything to restore
		dec	zp_save_ctr
		bmi	@nomoresaves

		; setup registers for restore
		ldx	#<blit_restore
		ldy	#>blit_restore
		jsr	_blit_ctl_full_noExec


		; move back ptr
		sec
		lda	zp_save_ptr
		sbc	#save_b_size
		sta	zp_save_ptr
		bcs	@no_c
		dec	zp_save_ptr + 1
@no_c:

		ldy	#0
		; restore scr
		lda	(zp_save_ptr),y
		sta	jim_CS_BLIT_ADDR_C + 0
		iny
		lda	(zp_save_ptr),y
		sta	jim_CS_BLIT_ADDR_C + 1
		iny
		; restore E into B
		lda	(zp_save_ptr),y
		sta	jim_CS_BLIT_ADDR_B + 0
		iny
		lda	(zp_save_ptr),y
		sta	jim_CS_BLIT_ADDR_B + 1
		iny
		lda	(zp_save_ptr),y
		sta	jim_CS_BLIT_ADDR_B + 2
		iny
		;restore W
		lda	(zp_save_ptr),y
		sta	jim_CS_BLIT_WIDTH
		tax
		inx
		stx	jim_CS_BLIT_STRIDE_B + 0
		iny
		;restore H
		lda	(zp_save_ptr),y
		sta	jim_CS_BLIT_HEIGHT
		iny

		lda	#BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_4BBP
		sta	jim_CS_BLIT_BLITCON

		jmp	@restore_loop


@nomoresaves:
		;setup save area
		ldx	#<save_blocks_start
		stx	zp_save_ptr
		ldy	#>save_blocks_start
		sty	zp_save_ptr+1

		lda	#B_BACK_SAV / $10000
		sta	blit_ctl + block_ADDR_E_offs+2
		lda	#(B_BACK_SAV / $100) & $FF
		sta	blit_ctl + block_ADDR_E_offs+1
		lda	#(B_BACK_SAV) & $FF
		sta	blit_ctl + block_ADDR_E_offs+0
		lda	#0
		sta	zp_save_ctr

		jsr	render_scroll_line

		jmp	@lp

render_scroll_line:

		; initialise blitter regs but don't exec 
		ldx	#<blit_ctl
		ldy	#>blit_ctl
		jsr	_blit_ctl_full_noExec


		; initialise dma for save ops
		lda	#0
		sta	jim_CS_DMA_SEL
		sta	jim_CS_DMA_COUNT + 1
		lda	#$FF
		sta	jim_CS_DMA_DEST_ADDR + 2		; bank



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
		
@sk3:		
		; calculate address of mask B_FONT_MAS + 4 * (c mod 8) + &600 * (c div 8)
		pha
		and	#$07
		asl
		asl
		sta	jim_CS_BLIT_ADDR_A + 0
		pla
		clc
		and	#$18
		ror
		sta	zp_acc+1
		ror
		adc	zp_acc+1
		sta	zp_acc+1
		adc	#>B_FONT_MAS
		sta	jim_CS_BLIT_ADDR_A + 1

		; calculate address of sprite B_FONT_SPR + 16 * (c mod 8) + &1800*(c div 8)
		lda	jim_CS_BLIT_ADDR_A + 0
		asl	a
		rol	zp_acc+1
		asl	a
		sta	jim_CS_BLIT_ADDR_B + 0	; lo byte
		lda	zp_acc+1
		rol	a
		adc	#>B_FONT_SPR
		sta	jim_CS_BLIT_ADDR_B + 1; hi byte

		; calculate screen address = $2800 + 8*(x div 2); shift = x mod 2
		lda	zp_x + 1
		sta	zp_acc
		lda	zp_x
		and	#$FE
		asl	a
		rol	zp_acc
		asl	a
		rol	zp_acc
		clc
		adc	#$C0
		sta	jim_CS_BLIT_ADDR_C + 0
		lda	zp_acc
		adc	#$28
		sta	jim_CS_BLIT_ADDR_C + 1

		ldx	#$0
		ldy	#15
		lda	zp_x
		ror	a
		lda	#$FF
		bcc	@sk1
		ldx	#$11
		ldy	#16
		lda	#$7F
@sk1:		
		sta	jim_CS_BLIT_MASK_FIRST
		bmi	@sk4
		lda	#$80
@sk4:		
		sta	jim_CS_BLIT_MASK_LAST
		stx	jim_CS_BLIT_SHIFT_A
		sty	jim_CS_BLIT_WIDTH

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
		
		lda	jim_CS_BLIT_WIDTH
		sec
		sbc	#4							; subtract 4 from width
		sta	jim_CS_BLIT_WIDTH

		lda	jim_CS_BLIT_ADDR_C + 0
		clc
		adc	#32							; add 32 to screen address
		sta	jim_CS_BLIT_ADDR_C + 0

		lda	jim_CS_BLIT_ADDR_C + 1
		adc	#0
		sta	jim_CS_BLIT_ADDR_C + 1

		lda	jim_CS_BLIT_ADDR_B + 0
		adc	#4
		sta	jim_CS_BLIT_ADDR_B + 0			; add 4 to sprite pointer
		inc	jim_CS_BLIT_ADDR_A + 0			; and 1 to mask
		pla
		sec
		sbc	#4
		beq	@sk5
		bne	@lp8

@no8:		tax
		lda	masks_left, X
		sta	jim_CS_BLIT_MASK_FIRST
		jmp	@sk5

@sk8:		; see if we'll go off screen at right
		lda	zp_x + 1
		ror	a
		lda	zp_x
		ror	a			; X/2
		clc
		adc	jim_CS_BLIT_WIDTH
		sbc	#79
		bcc	@sk5
		; adjust width
		eor	#$FF
		clc
		adc	jim_CS_BLIT_WIDTH
		sta	jim_CS_BLIT_WIDTH
		lda	#$FF
		sta	jim_CS_BLIT_MASK_LAST
@sk5:

;		lda	zp_save_ptr + 1
;		sta	jim_CS_DMA_DEST_ADDR + 1
;		lda	zp_save_ptr + 0
;		sta	jim_CS_DMA_DEST_ADDR + 0
;
;		lda	#>jim_page_CHIPSET
;		sta	jim_CS_DMA_SRC_ADDR + 2
;		lda	#<jim_page_CHIPSET
;		sta	jim_CS_DMA_SRC_ADDR + 1
;		lda	#<(jim_CS_BLIT_ADDR_D)
;		sta	jim_CS_DMA_SRC_ADDR + 0
;
;		ldy	#4
;		sty	jim_CS_DMA_COUNT + 0
;
;		lda	#DMACTL_ACT + DMACTL_HALT + DMACTL_STEP_DEST_UP + DMACTL_STEP_SRC_UP
;		sta	jim_CS_DMA_CTL
;
;		iny
		
		ldy	#0

		lda	jim_CS_BLIT_ADDR_C
		sta	(zp_save_ptr), Y
		iny
		lda	jim_CS_BLIT_ADDR_C+1
		sta	(zp_save_ptr), Y
		iny
		lda	jim_CS_BLIT_ADDR_E
		sta	(zp_save_ptr), Y
		iny
		lda	jim_CS_BLIT_ADDR_E+1
		sta	(zp_save_ptr), Y
		iny
		lda	jim_CS_BLIT_ADDR_E+2
		sta	(zp_save_ptr), Y
		iny


		; - width, height
		lda	jim_CS_BLIT_WIDTH
		sta	(zp_save_ptr),y
		iny
		lda	jim_CS_BLIT_HEIGHT
		sta	(zp_save_ptr),y

		clc
		lda	zp_save_ptr
		adc	#save_b_size
		sta	zp_save_ptr
		bcc	@sk_cc
		inc	zp_save_ptr+1
@sk_cc:
		inc	zp_save_ctr

		; do blit
		lda	#BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_4BBP
		sta	jim_CS_BLIT_BLITCON

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
		.byte	BLITCON_EXEC_A+BLITCON_EXEC_B+BLITCON_EXEC_C+BLITCON_EXEC_D+BLITCON_EXEC_E	; BLTCON
		.byte	$CA		; copy B to D, mask A, C		FUNCGEN
		.byte	$FF		;				MASK_FIRST
		.byte	$FF		;				MASK_LAST
		.byte	15		; 				WIDTH
		.byte	47		;				HEIGHT
		.byte	$00		;				SHIFT_A
		.byte	0	; SPARE
		.word	32		;				STRIDE_A
		.word	128		;				STRIDE_B
		.word	1024		;				STRIDE_C/D
		.word	0	; SPARE
		ADDR24	B_FONT_MAS	;				ADDR_A
		.byte	$FF		;				DATA_A
		ADDR24	B_FONT_SPR	;				ADDR_B
		.byte	$55		;				DATA_B
		ADDR24	B_SHADOW+$1900	;				ADDR_C/D
		.byte	0		;				DATA_C
		ADDR24	B_BACK_SAV+$1900;				ADDR_E
		.byte	$1F		; BLTCON act, cell, 4bpp				!NO EXEC!



blit_bkg_1st:	
		.byte	BLITCON_EXEC_B+BLITCON_EXEC_D+BLITCON_CELL_B ;	BLTCON
		.byte	$CC		; copy B to D			FUNCGEN
		.byte	$FF		;				MASK_FIRST
		.byte	$FF		;				MASK_LAST
		.byte	80		; 				WIDTH
		.byte	255		;				HEIGHT
		.byte	$00		;				SHIFT_A
		.byte	0	; SPARE
		.word	32		;				STRIDE_A
		.word	640		;				STRIDE_B
		.word	1024		;				STRIDE_C/D
		.word	0	; SPARE
		ADDR24	0		;				ADDR_A
		.byte	0		;				DATA_A
		ADDR24   B_SCREEN_1	;				ADDR_B
		.byte	$0		;				DATA_B
		ADDR24	B_SHADOW+$C0	;				ADDR_C/D
		.byte	0		;				DATA_C
		ADDR24	0		;				ADDR_E
		.byte	BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_4BBP


blit_shadow2screen:	
		.byte	BLITCON_EXEC_B+BLITCON_EXEC_D+BLITCON_CELL_B ;	BLTCON
		.byte	$CC		; copy B to D			FUNCGEN
		.byte	$FF		;				MASK_FIRST
		.byte	$FF		;				MASK_LAST
		.byte	80		; 				WIDTH
		.byte	255		;				HEIGHT
		.byte	$00		;				SHIFT_A
		.byte	0	; SPARE
		.word	32		;				STRIDE_A
		.word	1024		;				STRIDE_B
		.word	640		;				STRIDE_C
		.word	0	; SPARE
		ADDR24	0		;				ADDR_A
		.byte	$0		;				DATA_A
		ADDR24	B_SHADOW+$C0	;				ADDR_B
		.byte	0		;				DATA_B
		ADDR24	B_SCREEN_1	;				ADDR_C/D
		.byte	$0		;				ADDR_E_BANK
		ADDR24	0		;				ADDR_E
		.byte	BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_4BBP


blit_restore:	
		.byte	BLITCON_EXEC_B+BLITCON_EXEC_D	; 		BLTCON
		.byte	$CC		; copy B to D			FUNCGEN
		.byte	$FF		;				MASK_FIRST
		.byte	$FF		;				MASK_LAST
		.byte	0		; CODE				WIDTH
		.byte	0		; CODE				HEIGHT
		.byte	$00		;				SHIFT_A
		.byte	0	; SPARE
		.word	0		;				STRIDE_A
		.word	0		; CODE				STRIDE_B
		.word	1024		;				STRIDE_C/D
		.word	0	; SPARE
		ADDR24	0		;				ADDR_A
		.byte	0		;				DATA_A
		ADDR24	0		; CODE				ADDR_B
		.byte	0		;				DATA_B
		ADDR24	B_SHADOW		; CODE				ADDR_C/D
		.byte	0		;				DATA C
		ADDR24	0		;				ADDR_E
		.byte	$00		; BLTCON act, cell, 4bpp			!! DON'T ACT - set in CODE


scrolltext:	.byte	"....Ishbel Fiona Aibhlinn Beesley.....", 0

backstr:	.byte	"S.BACK", $D
backosfile:	.word	backstr
		.word	$2FD0
		.word	$FFFF
		.byte	0

keystate:	.byte	0


save_blocks_start:
		.END
