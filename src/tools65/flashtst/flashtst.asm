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


; (c) Dossytronics 2017
;
; Demonstrates reading the manufacturer codes of the Flash EEPROM of
; the Blitter (mk2 or mk3) board via the JIM interface.
; This assumes that the Flash EEPROM is mapped at JIM addres 80 0000 

		.include	"oslib.inc"
		.include	"common.inc"
		.include	"hardware.inc"
		.include	"mosrom.inc"

.macro 		M_ERROR
		brk
.endmacro

.macro          M_PRINT addr
		ldx	#<addr
		ldy	#>addr
		jsr	PrintXY
.endmacro

.macro		M_ADDR 	addr
		lda	#(addr >> 16) & $FF
		sta	zp_addr+2
		lda	#(addr >> 8) & $FF
		sta	zp_addr+1
		lda	#addr & $FF
		sta	zp_addr+0
.endmacro

.macro 		M_ADDR_5555
		M_ADDR $805555
.endmacro

.macro 		M_ADDR_2AAA
		M_ADDR $802AAA
.endmacro

.macro		M_DATA 	data
		lda	#data
		sta	zp_data
.endmacro


ADDR_MAX	:= $1FFFFF
DEVNO		:= JIM_DEVNO_BLITTER

		.ZEROPAGE
zp_tmpptr:	.res	2
zp_addr:	.res	3
zp_data:	.res	1
zp_fail:	.res	1

		.BSS
orgstack:	.res	1	; original stack pointer
addr_max:	.res	3
manu_id:	.res 	1
dev_id:		.res	1
		.CODE
		
;==============================================================================
; M A I N
;==============================================================================

		; save original stack pointer for exit
		tsx
		stx	orgstack

		; enter software ID mode
		M_ADDR_5555
		M_DATA 	$AA
		jsr	jimwrite
		M_ADDR_2AAA
		M_DATA 	$55
		jsr	jimwrite
		M_ADDR_5555
		M_DATA 	$90
		jsr	jimwrite



		M_ADDR 	$800000	
		jsr	jimreadA
		sta	manu_id

		M_ADDR 	$800001
		jsr	jimreadA
		sta	dev_id

		M_DATA 	$F0
		jsr	jimwrite

		M_PRINT str_man

		lda	manu_id
		cmp	#$BF
		bne	@s1
		M_PRINT str_sst
		beq	@s2
@s1:		jsr	uk
@s2:

dev:
		M_PRINT str_dev

		lda	dev_id
		cmp	#$D5
		beq	@s010
		cmp	#$D6
		beq	@s020
		cmp	#$D7
		beq	@s040
@s1:		jsr	uk
		jmp	@s2
@s010:		M_PRINT str_dev_010
		jmp	@s2
@s020:		M_PRINT str_dev_020
		jmp	@s2
@s040:		M_PRINT str_dev_040
		jmp	@s2
@s2:


		rts

uk:		pha			
		M_PRINT str_uk
		pla
		jsr	PrintHex
		lda	#')'
		jsr	OSWRCH
		jmp	OSNEWL



jimwrite:
		jsr	jimaddr
		lda	zp_data
		ldx	zp_addr+0
		sta	JIM,X
		rts

jimreadA:
		jsr	jimaddr
		ldx	zp_addr+0
		lda	JIM,X
		rts


exit:		ldx	orgstack
		txs
		rts


jimaddr:
		lda	#DEVNO
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO
		lda	zp_addr+2
		sta	fred_JIM_PAGE_HI
		lda	zp_addr+1
		sta	fred_JIM_PAGE_LO
		rts


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

PrintAddr:	lda	zp_addr+2
		jsr	PrintHex
		lda	zp_addr+1
		jsr	PrintHex
		lda	zp_addr+0
		jmp	PrintHex
PrintData:	lda	zp_data
		jmp	PrintHex

PrintXY:	stx	zp_tmpptr
		sty	zp_tmpptr + 1
		ldy	#0
@lp:		lda	(zp_tmpptr),Y
		beq	@out
		jsr	OSASCI
		iny
		bne	@lp
@out:		rts



Print13:	lda	#13
		jmp	OSWRCH

PrintSpc:	lda	#' '
		jmp	OSWRCH




str_man:	.byte	"Manufacturer :", 0
str_dev:	.byte	"Device       :", 0
str_uk:		.byte	"Unknown (&", 0
str_sst:	.byte	"SST/Microchip", $D, 0
str_dev_010:	.byte	"SST39*F010", $D, 0
str_dev_020:	.byte	"SST39*F020", $D, 0
str_dev_040:	.byte	"SST39*F040", $D, 0

