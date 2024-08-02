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
		.include	"hardware.inc"
		.include	"mosrom.inc"

SPEED_B :=		30

		.ZEROPAGE
zp_TMP:		.res 1
zp_SCR_ST:	.res 2		; screen address of start point
zp_CTR_A:	.res 1		; start point angle counter
zp_CTR_B:	.res 1		; end point angle counter
zp_SPD_CTR:	.res 1
		.CODE

		; mode 4
		lda	#8
		sta	zp_TMP
		lda	#0
@flp:		jsr	OSWRCH			; flush VDU buffer just in case
		dec	zp_TMP
		bne	@flp


		lda	#22
		jsr	OSWRCH
		lda	#4
		jsr	OSWRCH

		; enable jim
		lda	#JIM_DEVNO_BLITTER
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO
		lda	fred_JIM_DEVNO	
	
		jsr	jimDMACPAGE

		lda	#SPEED_B
		sta	zp_SPD_CTR

loop:		inc	zp_CTR_A

		dec	zp_SPD_CTR
		bpl	@s1
		inc	zp_CTR_B
		lda	#SPEED_B
		sta	zp_SPD_CTR
@s1:
		ldx	zp_CTR_A
		lda	sintab, X
		sta	X1
		txa
		clc
		adc	#$40
		tax
		lda	sintab, X
		sta	Y1

		ldx	zp_CTR_B
		lda	sintab, X
		sta	X2
		txa
		clc
		adc	#$40
		tax
		lda	sintab, X
		sta	Y2


;		ldx	X1
;		ldy	Y1
;		jsr	calcSCRADDR
;		ldy	#0
;		eor	(zp_SCR_ST),Y
;		sta	(zp_SCR_ST),Y


		jsr	line_draw
		lda	#19
		jsr	OSBYTE

;		ldx	X1
;		ldy	Y1
;		jsr	calcSCRADDR
;		ldy	#0
;		eor	(zp_SCR_ST),Y
;		sta	(zp_SCR_ST),Y

		jsr	line_draw

		jmp	loop

		.byte	$5C


		rts


jimDMACPAGE:
		pha
		lda	#<jim_page_CHIPSET
		sta	fred_JIM_PAGE_LO
		lda	#>jim_page_CHIPSET
		sta	fred_JIM_PAGE_HI
		pla
		rts


line_draw:

		; find deltaX
		sec
		lda	X1
		sbc	X2
		php
		ror	zp_TMP	; save sign of X1-X2
		plp
		bcs	@s1
		eor	#$FF
		adc	#1	
@s1:		sta	DX	; magnitude DX

		; find deltaY
		sec
		lda	Y1
		sbc	Y2
		php
		ror	zp_TMP	; save sign of Y1-Y2
		plp
		bcs	@s2
		eor	#$FF
		adc	#1
@s2:		sta	DY	; magnitude DX

		; compare DX/DY
		sec
		sbc	DX
		bcs	@s3

		; X is major axis
		lda	DY
		sta	DMIN
		lda	DX
		sta	DMAJ

		lda	#BLITCON_ACT_ACT + BLITCON_ACT_CELL + BLITCON_ACT_LINE

		; get X/Y coordinates
		; get rightmost coordinate
		; check sign of sub in zp_TMP
		bit	zp_TMP
		bvs	@swap1
		ldx	X1
		ldy	Y1
		bit	zp_TMP
		bpl	@noccw3
		ora	#BLITCON_LINE_MINOR_CCW		; we're going RIGHT and UP
@noccw3:	jmp	@s4


@swap1:		ldx	X2
		ldy	Y2
		bit	zp_TMP
		bmi	@noccw4
		ora	#BLITCON_LINE_MINOR_CCW		; we're going RIGHT and UP
@noccw4:	jmp	@s4

@s3:	
		; Y is major axis
		lda	DX
		sta	DMIN
		lda	DY
		sta	DMAJ

		lda	#BLITCON_ACT_ACT + BLITCON_ACT_CELL + BLITCON_ACT_LINE + BLITCON_LINE_MAJOR_UPnRIGHT	; we're going UP

		; get X/Y coordinates
		; get bottom-most coordinate
		; check sign of sub in zp_TMP
		bit	zp_TMP
		bpl	@swap2
		ldx	X1
		ldy	Y1

		bvc	@noccw1
		ora	#BLITCON_LINE_MINOR_CCW		; we're going UP and LEFT
@noccw1:	jmp	@s4

@swap2:		ldx	X2
		ldy	Y2
		bvs	@noccw2
		ora	#BLITCON_LINE_MINOR_CCW		; we're going UP and LEFT
@noccw2:	jmp	@s4
@s4:
		pha		; save the BLTCON value for later

		jsr	calcSCRADDR
		; mask value
		sta	jim_CS_BLIT_DATA_A	; set pixel mask

		; set screen address start point
		lda	#$FF
		sta	jim_CS_BLIT_ADDR_C+2
		lda	zp_SCR_ST
		sta	jim_CS_BLIT_ADDR_C+0
		lda	zp_SCR_ST+1
		sta	jim_CS_BLIT_ADDR_C+1


		; set colour to white
		lda	#$FF
		sta	jim_CS_BLIT_DATA_B

		; set function generator to set B masked by A XOR C masked by not A
		lda	#$4A				
		sta	jim_CS_BLIT_FUNCGEN

		lda	#BLITCON_EXEC_C + BLITCON_EXEC_D
		sta	jim_CS_BLIT_BLITCON

		; set major / error acc /minor
		lda	#0
		sta	jim_CS_BLIT_ADDR_B+1
		sta	jim_CS_BLIT_ADDR_A+1
		sta	jim_CS_BLIT_STRIDE_A+1
		sta	jim_CS_BLIT_WIDTH
		
		lda	DMAJ
		sta	jim_CS_BLIT_ADDR_B+0
		sta	jim_CS_BLIT_HEIGHT
		lsr	A
		sta	jim_CS_BLIT_ADDR_A+0
		lda	DMIN
		sta	jim_CS_BLIT_STRIDE_A+0

		; set stride
		lda	#>320
		sta	jim_CS_BLIT_STRIDE_C+1
		sta	jim_CS_BLIT_STRIDE_D+1
		lda	#<320
		sta	jim_CS_BLIT_STRIDE_C+0
		sta	jim_CS_BLIT_STRIDE_D+0

		; execute!
		pla
		sta	jim_CS_BLIT_BLITCON
	

		rts

calcSCRADDR:
		; calculate starting screen address and mask value
	
		lda	#$58
		sta	zp_SCR_ST+1
		lda	#0
		sta	zp_SCR_ST

		lda	#0
		sta	zp_TMP
		tya		; Y coordinate (top down)
		pha
		and	#$F8	; mask out character cell row
		; multiply by 40*8 = 320 = $140
		asl	A
		rol	zp_TMP	
		asl	A
		rol	zp_TMP	
		asl	A
		rol	zp_TMP	; ZP_TMP|A contains char row * $40
		jsr	addSCRST
		asl	A
		rol	zp_TMP	
		asl	A
		rol	zp_TMP	
		jsr	addSCRST

		lda	#0
		sta	zp_TMP
		pla		; get back intra cell ro
		and	#$07
		jsr	addSCRST; add to address

		; now do X 
		txa
		pha
		and	#$F8		; character CELL
		jsr	addSCRST

		pla
		and	#$07
		tax
		lda	PIXMASKS,X
		rts


addSCRST:
		pha
		adc	zp_SCR_ST
		sta	zp_SCR_ST
		lda	zp_SCR_ST+1
		adc	zp_TMP
		sta	zp_SCR_ST+1
		pla
		rts


		.DATA
X1:		.byte	140
Y1:		.byte	50
X2:		.byte	128
Y2:		.byte	128

DX:		.byte	0
DY:		.byte	0

DMAJ:		.byte	0
DMIN:		.byte	0



		.RODATA

PIXMASKS:	.byte $80, $40, $20, $10, $08, $04, $02, $01

	; sine table 2's complement 256 entries
sintab:


		.byte	$80, $83, $86, $89, $8C, $8F, $92, $95, $98, $9B, $9E, $A1, $A4, $A7, $AA, $AD
		.byte	$B0, $B3, $B6, $B9, $BB, $BE, $C1, $C3, $C6, $C9, $CB, $CE, $D0, $D2, $D5, $D7
		.byte	$D9, $DB, $DE, $E0, $E2, $E4, $E6, $E7, $E9, $EB, $EC, $EE, $F0, $F1, $F2, $F4
		.byte	$F5, $F6, $F7, $F8, $F9, $FA, $FB, $FB, $FC, $FD, $FD, $FE, $FE, $FE, $FE, $FE
		.byte	$FF, $FE, $FE, $FE, $FE, $FE, $FD, $FD, $FC, $FB, $FB, $FA, $F9, $F8, $F7, $F6
		.byte	$F5, $F4, $F2, $F1, $F0, $EE, $EC, $EB, $E9, $E7, $E6, $E4, $E2, $E0, $DE, $DB
		.byte	$D9, $D7, $D5, $D2, $D0, $CE, $CB, $C9, $C6, $C3, $C1, $BE, $BB, $B9, $B6, $B3
		.byte	$B0, $AD, $AA, $A7, $A4, $A1, $9E, $9B, $98, $95, $92, $8F, $8C, $89, $86, $83
		.byte	$80, $7C, $79, $76, $73, $70, $6D, $6A, $67, $64, $61, $5E, $5B, $58, $55, $52
		.byte	$4F, $4C, $49, $46, $44, $41, $3E, $3C, $39, $36, $34, $31, $2F, $2D, $2A, $28
		.byte	$26, $24, $21, $1F, $1D, $1B, $19, $18, $16, $14, $13, $11, $0F, $0E, $0D, $0B
		.byte	$0A, $09, $08, $07, $06, $05, $04, $04, $03, $02, $02, $01, $01, $01, $01, $01
		.byte	$01, $01, $01, $01, $01, $01, $02, $02, $03, $04, $04, $05, $06, $07, $08, $09
		.byte	$0A, $0B, $0D, $0E, $0F, $11, $13, $14, $16, $18, $19, $1B, $1D, $1F, $21, $24
		.byte	$26, $28, $2A, $2D, $2F, $31, $34, $36, $39, $3C, $3E, $41, $44, $46, $49, $4C
		.byte	$4F, $52, $55, $58, $5B, $5E, $61, $64, $67, $6A, $6D, $70, $73, $76, $79, $7C


	.END