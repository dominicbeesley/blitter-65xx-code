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


		.include 	"oslib.inc"
		.include	"common.inc"
		.include	"hardware.inc"
		.include	"mosrom.inc"



.macro 		M_ERROR
		ldx	orgstack
		txs
		jsr	restore_dev
		brk
.endmacro

.macro          M_PRINT addr
		ldx	#<addr
		ldy	#>addr
		jsr	PrintXY
.endmacro

		.ZEROPAGE
zp_tmpptr:	.res	2
remainder:	.res	1
dividend:	.res	2
		.CODE
		
;==============================================================================
; M A I N
;==============================================================================

		; save original stack pointer for exit
		tsx
		stx	orgstack

		lda	zp_mos_jimdevsave
		sta	old_dev_no
		lda	fred_JIM_PAGE_HI
		sta	old_pag+1
		lda	fred_JIM_PAGE_LO
		sta	old_pag


		; select Blitter and check that it responds
		; enable blitter device
		lda	#JIM_DEVNO_BLITTER
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO

		eor	fred_JIM_DEVNO
		cmp	#$FF
		beq	@ok1

		; if we're here there's no blitter

		M_ERROR
		.byte	$ff, "Blitter not detected",0

@ok1:		M_PRINT s_welcome

		lda	#0
		sta	fred_JIM_PAGE_LO

		; save old RAM contents
		ldx	#$7F
@lp:		stx	fred_JIM_PAGE_HI
		lda	JIM
		sta	ram_save,X
		stx	JIM
		dex
		bpl	@lp

		; loop through ram looking for ranges of 64k blocks with correct marker
		lda	#0
		sta	had_range
		sta	in_range
		sta	total
		ldx	#0
@lp3:		stx	fred_JIM_PAGE_HI
		cpx	JIM
		beq	@range_cont
		jsr	end_range
		jmp	@sk3
@range_cont:	jsr	cont_range
@sk3:		inx
		bpl	@lp3
		jsr	end_range

		; restore old RAM contents
		ldx	#0
@lp2:		stx	fred_JIM_PAGE_HI
		lda	ram_save,X
		sta	JIM
		inx
		bpl	@lp2

		M_PRINT	s_total

		lda	total
		jsr	printBlockSize

		lda	#'K'
		jsr	OSWRCH

		jsr	OSNEWL



		jmp	restore_dev		; exit to OS

cont_range:	lda	in_range
		bne	@cc
		inc	in_range
		stx	start_range
@cc:		inc	total
		rts

end_range:	lda	in_range
		beq	@ex
		lda	#0
		sta	in_range

		jsr	PrintSpc
		jsr	PrintSpc
		lda	start_range
		jsr	PrintHex
		jsr	PrintSpc
		lda	#0
		jsr	PrintHex
		lda	#0
		jsr	PrintHex
		jsr	PrintSpc
		lda	#'-'
		jsr	OSWRCH
		jsr	PrintSpc
		txa
		clc
		sbc	#0
		jsr	PrintHex
		jsr	PrintSpc
		lda	#$FF
		jsr	PrintHex
		lda	#$FF
		jsr	PrintHex

		jsr	PrintSpc
		lda	#'='
		jsr	OSWRCH
		jsr	PrintSpc

		; get number of K
		txa
		sec
		sbc	start_range

		jsr	printBlockSize

		lda	#'K'
		jsr	OSWRCH


		jsr	OSNEWL

@ex:		rts



restore_dev:	php
		sei
		pha
		lda	old_dev_no
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO
		lda	old_pag+1
		sta	fred_JIM_PAGE_HI
		lda	old_pag
		sta	fred_JIM_PAGE_LO
		pla
		plp
		rts

printBlockSize:
		ldy	#0
		sty	dividend
		lsr	A
		ror	dividend
		lsr	A
		ror	dividend
		sta	dividend+1


print10s:
		ldy	#4
@tenslp1:
		jsr	div10
		lda	remainder
		pha
		dey
		bne	@tenslp1

		ldy	#4
@tenslp2:	pla
		ora	#'0'
		jsr	OSWRCH
		dey
		bne	@tenslp2
		rts


PrintXY:	stx	zp_tmpptr
		sty	zp_tmpptr + 1
		ldy	#0
@lp:		lda	(zp_tmpptr),Y
		beq	@out
		jsr	OSASCI
		iny
		bne	@lp
@out:		rts

; see http://www.obelisk.me.uk/6502/algorithms.html
PrintHex:
		pha                        
		lsr 	A
		lsr	A
		lsr 	A
		lsr	A
		jsr 	PrIntHexNyb
		pla
		and 	#$0F
PrIntHexNyb:
		sed
		clc
		adc	#$90
		adc	#$40
		cld
		jmp	OSWRCH

PrintSpc:	lda	#' '
		jmp	OSWRCH


		; adapted from https://codebase64.org/doku.php?id=base:16bit_division_16-bit_result

div10:		txa
		pha

		lda 	#0	        ;preset remainder to 0
		sta 	remainder
		ldx 	#16	        ;repeat for each bit: ...

@lp:		asl	dividend	;dividend lb & hb*2, msb -> Carry
		rol	dividend+1	
		rol	remainder	;remainder lb & hb * 2 + msb from carry
		lda	remainder
		sec
		sbc	#10		;substract divisor to see if it fits in
		bcc	@skip		;if carry=0 then divisor didn't fit in yet

		sta	remainder	
		inc	dividend	;and INCrement result cause divisor fit in 1 times
@skip:		dex
		bne	@lp
		pla
		tax
		rts

		.DATA
s_welcome:	.byte	"Testing Blitter Memory Size",13,0
s_total:	.byte	"Total ",0

		.BSS
orgstack:	.res	2
old_dev_no:	.res	1
old_pag:	.res	2
had_range:	.res	1
in_range:	.res	1
start_range:	.res	1
total:		.res	1

ram_save:	.res	$80
