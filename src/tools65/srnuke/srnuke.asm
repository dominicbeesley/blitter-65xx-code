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

PG_EEPROM_BASE	:=	$8000				; base phys/jim address of EEPROM is $10 0000

.macro 		M_ERROR
		brk
.endmacro


		.ZEROPAGE
ZP_NUKE_ROMSF:	.RES 1
ZP_TMPPTR:	.RES 2


		.CODE
		
		jmp	cmdSRNUKE

cmdSRNUKE_menu:
		.byte	13, "0) Exit	1) Erase Flash	2) Erase RAM", 13,0
		;;	3) Show CRC	4) Erase #", 13, 0

inkey_clear:
		ldx	#0
		ldy	#0
		lda	#OSBYTE_129_INKEY
		jsr	OSBYTE
		bcc	inkey_clear

inkey:
		pha
		tya
		pha
		ldx	#255
		ldy	#127
		lda	#OSBYTE_129_INKEY
		jsr	OSBYTE
		pla
		tay
		pla
		rts

CMDROMS_FLAGS_CRC	:=	$20
CMDROMS_FLAGS_VERBOSE	:=	$80
CMDROMS_FLAGS_ALL	:=	$40



cmdSRNUKE:	; cmdRoms no VA
		ldx	#CMDROMS_FLAGS_VERBOSE+CMDROMS_FLAGS_ALL
		stx	ZP_NUKE_ROMSF

cmdSRNUKE_mainloop:
;;		ldx	ZP_NUKE_ROMSF
;;		jsr	cmdRoms_Go
		
		; SHOW MENU
		ldx	#<cmdSRNUKE_menu
		ldy	#>cmdSRNUKE_menu
		jsr	PrintXY

@1:		jsr	inkey_clear
		bcs	@1
		txa
		jsr	OSWRCH

		cpx	#'0'
		bne	@not0
		jmp	cmdSRNUKE_exit
@not0:		cpx	#'1'
		bne	@not1
		jmp	cmdSRNUKE_flash
@not1:		cpx	#'2'
		bne	@not2
		jmp	cmdSRNUKE_ram
@not2:
;;		cpx	#'3'
;;		bne	@not3
;;		jmp	cmdSRNUKE_crctoggle
;;@not2:		cpx	#'4'
;;		bne	@not4
;;		jmp	cmdSRNUKE_erase_rom
@not4:		jmp	cmdSRNUKE_mainloop

cmdSRNUKE_crctoggle:
		lda	ZP_NUKE_ROMSF
		eor	#CMDROMS_FLAGS_CRC
		sta	ZP_NUKE_ROMSF
		jmp	cmdSRNUKE_mainloop

cmdSRNUKE_flash:
		ldx	#<str_NukePrAllFl
		ldy	#>str_NukePrAllFl
		jsr	PromptYN
		bne	cmdSRNUKE_mainloop

		ldx	#<str_NukeFl
		ldy	#>str_NukeFl
		jsr	PrintXY

		; erase entire flash chip
		jsr	FlashReset
		lda	#$80
		jsr	FlashCmdA
		lda	#$10
		jsr	FlashCmdA
;;		jsr	FlashWaitToggle

		; just RTS for now!
		rts
;;cmdSRNUKE_reboot
;;		ORCC	#CC_I+CC_F
;;		jmp	[$F7FE]				; reboot - if we're running from flash we'll crash anyway!


cmdSRNUKE_ram:	ldx	#<str_NukePrAllRa
		ldy	#>str_NukePrAllRa
		jsr	PromptYN
		bne	cmdSRNUKE_mainloop

		ldx	#<str_NukeRa
		ldy	#>str_NukeRa
		jsr	PrintXY

		; enable JIM, setup paging regs
		lda	#JIM_DEVNO_BLITTER
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO

		lda	#$00
		sta	fred_JIM_PAGE_HI
		lda	#0	
		sta	fred_JIM_PAGE_LO

;;		; copy ram nuke routine to ADDR_ERRBUF and execute from there
;;		ldx	#cmdSRNuke_RAM
;;		ldu	#ADDR_ERRBUF
;;		ldb	#cmdSRNuke_RAM_end - cmdSRNuke_RAM
;;1		lda	,X+				; copy the routine to ram buffer as we are likely to get zapped
;;		sta	,U+
;;		decb
;;		bne	1B
;;		lda	#$FF
;;		jmp	ADDR_ERRBUF


		lda	#$FF
cmdSRNuke_RAM:
@2:		ldx	#0
@1:		sta	JIM,X
		inx
		bne	@1
		inc	fred_JIM_PAGE_LO
		bne	@2
		inc	fred_JIM_PAGE_HI
		ldx	fred_JIM_PAGE_HI
		cpx	#$20
		bne	@3
		rts

@3:		lda	fred_JIM_PAGE_HI
		jsr	PrintHex
		lda	fred_JIM_PAGE_LO
		jsr	PrintHex
		jsr	OSNEWL
		lda	#255
		bne	@2

cmdSRNUKE_exit:
		rts

IsFlashBank:
		; rom id in A, returns EQ if this is a Flash Bank, do NOT rely 
		; on value returned in A!
		cmp	#$4
		bcc	@1
		cmp	#$9
		bcc	@2				; treat SYStem sockets (4..7) as RAM (they might be?!)
@1:		eor	#$F
		and	#1
@2:		rts

;------------------------------------------------------------------------------
; Flash utils
;------------------------------------------------------------------------------

FlashReset:
		pha
		lda	#$F0
		jsr	FlashCmdA
		pla
		rts

FlashCmdA:
		pha
		txa
		pha
		; enable JIM
		lda	zp_mos_jimdevsave
		pha
		lda	#JIM_DEVNO_BLITTER
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO

		ldx	#>(PG_EEPROM_BASE+$0055)
		stx	fred_JIM_PAGE_HI
		ldx	#<(PG_EEPROM_BASE+$0055)
		stx	fred_JIM_PAGE_LO
		lda	#$AA
		sta	JIM + $55

		ldx	#>(PG_EEPROM_BASE+$002A)
		stx	fred_JIM_PAGE_HI
		ldx	#<(PG_EEPROM_BASE+$002A)
		stx	fred_JIM_PAGE_LO
		lda	#$55
		sta	JIM + $AA

		ldx	#>(PG_EEPROM_BASE+$0055)
		stx	fred_JIM_PAGE_HI
		ldx	#<(PG_EEPROM_BASE+$0055)
		stx	fred_JIM_PAGE_LO

		tsx
		lda	$103,X				; get back A from stack
		sta	JIM + $55

		pla
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO

		pla
		txa
		pla
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


PrintXY:	stx	ZP_TMPPTR
		sty	ZP_TMPPTR + 1
		ldy	#0
@lp:		lda	(ZP_TMPPTR),Y
		beq	@out
		jsr	OSASCI
		iny
		bne	@lp
@out:		rts


PromptYN:	jsr	PrintXY
		ldx	#<str_YN
		ldy	#>str_YN
		jsr	PrintXY
@1:		jsr	WaitKey
		bcs	PromptRTS
		cmp	#'Y'
		beq	PromptYes
		cmp	#'N'
		bne	@1
PromptNo:	ldx	#<strNo
		ldy	#>strNo
		jsr	PrintXY
		lda	#$FF
		clc
		rts
PromptYes:	ldx	#<strYes
		ldy	#>strYes
		jsr	PrintXY
		lda	#0
		clc
PromptRTS:	rts


WaitKey:	pha
		txa
		pha
		tya
		pha
@2:		lda	#OSBYTE_129_INKEY
		ldy	#$7F
		ldx	#$FF
		jsr	OSBYTE
		bcs	@1
		txa		
		tsx
		sta	$103,X
		clc
		pla
		tay
		pla
		tax
		pla
		rts
@1:		cpy	#27				; check for escape
		bne	@2
		jmp	ackEscape

CheckESC:	bit	zp_mos_ESC_flag			; TODO - system call for this?
		bpl	ceRTS
ackEscape:	ldx	#$FF
		lda	#OSBYTE_126_ESCAPE_ACK
		jsr	OSBYTE
brkEscape:	M_ERROR
		.byte	17, "Escape",0
ceRTS:		rts

str_Copying:		.byte	"Copying...", 0
str_OK:			.byte	$D, "OK.", $D, 0
str_NukePrAllFl:	.byte	"Erase whole Flash", 0
str_NukePrAllRa:	.byte	"Erase whole SRAM", 0
str_NukePrRom:		.byte	"Erase rom ",0
str_YN:			.byte	" (Y/N)?",0
str_FailedAt:		.byte	"failed at ",0
strErrsDet:		.byte	" errors detected", 0
strNo:			.byte	"No", $D, 0
strYes:			.byte	"Yes", $D, 0
str_NukeFl:		.byte	"Erasing flash...", $D, 0
str_NukeRa:		.byte	"Erasing SRAM $000000 to $1FFFFF, please wait...", $D, 0
