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


; (c) Dossytronics 2021
; dump/change contents of runtime clock

;NOTE: uses new i2c component

		.include 	"oslib.inc"
		.include	"common.inc"
		.include	"hardware.inc"
		.include	"mosrom.inc"

I2C_ADDR := $A2

.macro 		M_ERROR
		brk
.endmacro

.macro          M_PRINT addr
		ldx	#<addr
		ldy	#>addr
		jsr	PrintXY
.endmacro

		.ZEROPAGE
zp_tmpptr:	.res	2
zp_trans_acc:	
zp_addr:	.res	2
zp_data:	.res	1
zp_fail:	.res	1
zp_ctr1:	.res 	1
		.CODE
		
;==============================================================================
; M A I N
;==============================================================================

ENTER:
		; read command line params

		lda	#1
		ldy	#0
		ldx	#<zp_trans_acc
		jsr	OSARGS
		lda	zp_trans_acc
		sta	zp_mos_txtptr
		lda	zp_trans_acc+1
		sta	zp_mos_txtptr+1

ENTER_DEBUG:

		; save original stack pointer for exit
		tsx
		stx	orgstack

		; set dev and save old
		lda	zp_mos_jimdevsave
		sta	org_dev_no
		lda	#JIM_DEVNO_BLITTER
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO
		eor	fred_JIM_DEVNO
		cmp	#$FF
		beq	@okblt
		brk
		.byte	$D1, "No blitter",0
		brk
@okblt:		
		lda	#<jim_page_DMAC
		sta	fred_JIM_PAGE_LO
		lda	#>jim_page_DMAC
		sta	fred_JIM_PAGE_HI

		; default range
		lda	#0
		sta	addr_start
		lda	#$11
		sta	addr_max
		ldy	#0

		jsr	SkipSpacesPTR
		cmp	#$D
		beq	@plus2
		cmp	#'C'
		bne	@nclk
		jmp	doclock
@nclk:		cmp	#'W'
		bne	@now1
@w1:		jmp	dowrite
@now1:		cmp	#'w'
		beq	@w1


@trynum:	jsr	ParseHex
		bcc	@cmdok
		jmp	brkBadCommand
@cmdok:		lda	zp_trans_acc
		sta	addr_start

		lda	#0
		sta	zp_tmpptr
		jsr	SkipSpacesPTR
		cmp	#'+'
		bne	@noplus
		dec	zp_tmpptr
		iny
@noplus:	jsr	ParseHex
		bcs	@plus2
		lda	zp_trans_acc
		sta	addr_max

		lda	zp_tmpptr
		beq	@noplus2
		clc
		lda	addr_start
		adc	addr_max
		sbc	#0
		sta	addr_max
@noplus2:
@plus2:

		ldx	#<s_Banner
		ldy	#>s_Banner
		jsr	PrintXY

		lda	addr_start
		jsr	PrintHex

		ldx	#<s_Banner2
		ldy	#>s_Banner2
		jsr	PrintXY

		lda	addr_max
		jsr	PrintHex


		lda	addr_start
		sta	zp_tmpptr
		cmp	addr_max
		bcs	@out

		clv
		jsr	i2c_setaddr
		bvc	@ss
		jmp	brkNoRTC
@ss:		sec
		jsr	i2c_addrrnw
		

@byteloop_a:	; print address and start a line of 8 values
		jsr	CheckESC
		jsr	OSNEWL

		lda	zp_tmpptr
		jsr	PrintHex

		jsr	PrintSpc
		lda	#':'
		jsr	OSASCI
		jsr	PrintSpc

		ldx	#8
		stx	zp_ctr1


@byteloop:	clv
		clc
		lda	zp_tmpptr
		cmp	addr_max		; set cy if >=
		jsr	i2c_readbyte
		jsr	PrintHex

		
@ss1:		lda	zp_tmpptr
		eor	addr_max
		beq	@out
		inc	zp_tmpptr
@ss2:		dec	zp_ctr1
		beq	@byteloop_a
		jsr	PrintSpc
		bne	@byteloop
@out:		jsr	OSNEWL


EXIT:
		lda	org_dev_no
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO

		ldx	orgstack
		txs

		rts


dowrite:	iny
		jsr	ParseHex
		bcc	@sk
		jmp	brkBadCommand
@sk:
@cmdok:		lda	zp_trans_acc
		sta	zp_tmpptr

@w_lp:
		; set write addr and keep open
		clv
		jsr	i2c_setaddr
		bvs	brkNoRTC

		jsr	ParseHex
		bcs	EXIT

		; send write with STOP
		clc
		bit	bit_SEV
		lda	zp_trans_acc
		jsr	i2c_write_byte

		inc	zp_tmpptr
		bne	@w_lp
		jmp	EXIT

		; show a clock on screen at 0,0
doclock:	lda	#31
		jsr	OSWRCH
		lda	#0
		jsr	OSWRCH
		jsr	OSWRCH

		; get data from RTC to a buffer

		clc
		jsr	i2c_addrrnw		; write address 0
		bvs	brkNoRTC
		lda	#0
		clc
		clv
		jsr	i2c_write_byte


		sec
		jsr	i2c_addrrnw		; start read

		ldx	#0	
		stx	zp_ctr1	
@lp:		lda	zp_ctr1
		cmp	#$11			; CS if >=
		jsr	i2c_readbyte
		ldx	zp_ctr1
		sta	buf,X
		lda	zp_ctr1
		cmp	#$11
		beq	@sk2
		inc	zp_ctr1
		bne	@lp

@sk2:		; rtc data in buffer now...print the time!
		lda	buf+6
		jsr	PrintHex	;hours
		lda	#':'
		jsr	OSWRCH
		lda	buf+5		;minutes
		jsr	PrintHex
		lda	#':'
		jsr	OSWRCH
		lda	buf+4		;seconds
		and	#$7F
		jsr	PrintHex

		jsr	CheckESC

		; wait 1/5 second
		lda	#$81
		ldx	#20
		ldy	#0
		jsr	OSBYTE

		jmp	doclock



brkNoRTC:	brk
		.byte	0, "NO RTC", 0



brkBadCommand:	brk
		.byte	0, "Bad Command: RTCDUMP C|[<start> [<end|+len>]]|W <addr> <D>+", 0



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

PrintAddr:	lda	zp_addr+1
		jsr	PrintHex
		lda	zp_addr+0
		jmp	PrintHex

PrinY:		stx	zp_tmpptr
		sty	zp_tmpptr + 1
		ldy	#0
@lp:		lda	(zp_tmpptr),Y
		beq	@out
		jsr	OSASCI
		iny
		bne	@lp
@out:		rts



CheckESC:	bit	zp_mos_ESC_flag			; TODO - system call for this?
		bpl	ceRTS
ackEscape:	ldx	#$FF
		lda	#OSBYTE_126_ESCAPE_ACK
		jsr	OSBYTE
brkEscape:	M_ERROR
		.byte	17, "Escape",0
ceRTS:		rts


;------------------------------------------------------------------------------
; Parsing
;------------------------------------------------------------------------------
SkipSpacesPTR:	lda	(zp_mos_txtptr),Y
		iny
		beq	@s
		cmp	#' '
		beq	SkipSpacesPTR
@s:		dey
		rts

ToUpper:	cmp	#'a'
		bcc	@1
		cmp	#'z'+1
		bcs	@1
		and	#$DF
@1:		rts


ParseHex:
		ldx	#$FF				; indicates first char
		jsr	zeroAcc
		jsr	SkipSpacesPTR
		cmp	#$D
		beq	ParseHexErr
ParseHexLp:	lda	(zp_mos_txtptr),Y
		iny
		jsr	ToUpper
		inx	
		beq	@1
		cmp	#'+'
		beq	ParseHexDone	
@1:		cmp	#' '+1
		bcc	ParseHexDone
		cmp	#'0'
		bcc	ParseHexErr
		cmp	#'9'+1
		bcs	ParseHexAlpha
		sec
		sbc	#'0'
ParseHexShAd:	jsr	asl4Acc				; multiply existing number by 16
		jsr	addAAcc				; add current digit
		jmp	ParseHexLp
ParseHexAlpha:	cmp	#'A'
		bcc	ParseHexErr
		cmp	#'F'+1
		bcs	ParseHexErr
		sbc	#'A'-11				; note carry clear 'A'-'F' => 10-15
		jmp	ParseHexShAd
ParseHexErr:	sec
		rts
ParseHexDone:	dey
		clc
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

PrintSpc:	lda	#' '
		jmp	OSASCI

;------------------------------------------------------------------------------
; Arith
;------------------------------------------------------------------------------
zeroAcc:	pha
		lda	#0
		sta	zp_trans_acc
		sta	zp_trans_acc + 1
		sta	zp_trans_acc + 2
		sta	zp_trans_acc + 3
		pla
		rts

asl4Acc:
		pha
		txa
		pha
		ldx	#4
@1:		asl	zp_trans_acc + 0
		rol	zp_trans_acc + 1
		rol	zp_trans_acc + 2
		rol	zp_trans_acc + 3
		dex
		bne	@1
		pla
		tax
		pla
		rts

addAAcc:
		pha
		clc
		adc	zp_trans_acc + 0
		sta	zp_trans_acc + 0
		bcc	@1
		inc	zp_trans_acc + 1
		bne	@1
		inc	zp_trans_acc + 2
		bne	@1
		inc	zp_trans_acc + 3
@1:		pla
		rts

	.macro I2C_WAIT
		.local lp
lp:		bit	jim_I2C_STAT
		bmi	lp
	.endmacro


i2c_write_byte:	; on entry A contains byte to write, Cy = start, Ov = stop
		; on exit CS if not ACK
		php
		I2C_WAIT		
		plp
		sta	jim_I2C_DATA
		lda	#I2C_BUSY
		bcc	@nostart
		ora	#I2C_START
@nostart:	bvc	@nostop
		ora	#I2C_STOP|I2C_NACK
@nostop:	sta	jim_I2C_STAT
		I2C_WAIT
		rts




i2c_readbyte:	; on entry Cy contains NOT Ack|Stop
		php
		I2C_WAIT
		plp
		lda	#I2C_BUSY|I2C_RNW
		bcc	@nostop
		ora	#I2C_NACK|I2C_STOP
@nostop:	sta	jim_I2C_STAT
		I2C_WAIT
		lda	jim_I2C_DATA
		rts


i2c_addrrnw:	; on entry Cy contains 1 for read else write
		pha
		lda	#I2C_ADDR>>1
		rol	A
		sec
		clv
		jsr	i2c_write_byte
		pla
		rts


i2c_setaddr:	; On entry Ov contains STOP
		php
		clc
		jsr	i2c_addrrnw
		plp
		clc
		lda	zp_tmpptr
		jmp	i2c_write_byte		


bit_SEV:	.byte	$C0

		.RODATA
s_Banner:	.byte 	"RTCDUMP - showing ",0
s_Banner2:	.byte	" to ",0

		.BSS
org_dev_no:		.res 1
addr_start:		.res 1
addr_max:		.res 1
orgstack:		.res 1
buf:			.res 17