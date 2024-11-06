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

		.include "mosrom.inc"
		.include "oslib.inc"
		.include "bltutil.inc"

		.export FlashReset
		.export FlashReset_Q
		.export FlashEraseROM
		.export romWriteInit
		.export FlashCmdAWT
		.export brkEraseFailed
		.export romRead
		.export romWrite
		.export FlashCmdA
		.export Flash_SRLOAD
		
;=======================================================
		.SEGMENT "CODE_FLASH"
;=======================================================

; write to either JIM at zp_SRLOAD_bank/zp_mos_genPTR or if bank=$FF at rom Y/genptr
; if CS on entry expecting flash/waittoggle
sev:		.byte	$40

romRead:	bit	sev				; set overflow for read
		bvs	romRead2
romWrite:
		clv
romRead2:
		php		
		pha
		txa
		pha
		tya
		pha
		sei
		ldx	zp_SRLOAD_bank
		inx
		beq	@sys
		dex		
		stx	fred_JIM_PAGE_HI
		lda	zp_mos_genPTR+1
		sta	fred_JIM_PAGE_LO
		bvs	@jimread
		tsx
		lda	$103,X				; get A back from stack
		ldx	zp_mos_genPTR
		sta	JIM,X
		bvc	@ret
@jimread:	ldx	zp_mos_genPTR
		lda	JIM,X
		tsx
		sta	$103,X				; put A back from stack
@ret:		pla
		tay
		pla
		tax
		pla
		plp
		bvs	@rts
		bcs	FlashWaitToggle
@rts:		rts
@sys:		lda	zp_mos_curROM
		pha
		sty	zp_mos_curROM
	.ifdef MACH_ELK
		lda	#$0C
		sta	SHEILA_ROMCTL_SWR
	.endif
		sty	SHEILA_ROMCTL_SWR
		ldy	#0
		bvs	@sysrd
		tsx
		lda	$104,X				; get A back from stack
		sta	(zp_mos_genPTR),Y
		bvc	@syswr1
@sysrd:
		lda	(zp_mos_genPTR),Y
		tsx
		sta	$104,X				; put A back from stack
@syswr1:	pla
		sta	zp_mos_curROM
	.ifdef MACH_ELK
		ldx	#$0C
		stx	SHEILA_ROMCTL_SWR
	.endif
		sta	SHEILA_ROMCTL_SWR
		jmp	@ret



FlashCmdAWT:
		jsr FlashCmdA
FlashWaitToggle:
		php
		sei
FlashWaitToggle_lp:	
		lda	JIM
		cmp	JIM
		bne	FlashWaitToggle_lp
@1:		plp
		rts



;------------------------------------------------------------------------------
; Flash utils
;------------------------------------------------------------------------------


FlashJim0055:
		ldx	#<(PG_EEPROM_BASE+$0055)
		ldy	#>(PG_EEPROM_BASE+$0055)
JimXY:		stx	fred_JIM_PAGE_LO
		sty	fred_JIM_PAGE_HI
		rts

FlashJim5555eqAAthen2A:
		jsr	FlashJim0055
		lda	#$AA
		sta	JIM + $55
FlashJim2AAAeq55:
		ldy	#>(PG_EEPROM_BASE+$002A)
		ldx	#<(PG_EEPROM_BASE+$002A)
		jsr	JimXY
		lda	#$55
		sta	JIM + $AA
		rts
FlashCmdA:
		pha
		txa
		pha
		tya
		pha

		jsr	FlashJim5555eqAAthen2A
		jsr	FlashJim0055

		tsx
		lda	$103,X				; get back A from stack
		sta	JIM + $55

		jmp	FlashExitPLAXY


FlashCmdShort:	pha
		txa
		pha
		tya
		pha

		jsr	FlashJim5555eqAAthen2A
		jmp	FlashExitPLAXY

		; address is in zp_mos_genPTR and ROM in Y
FlashSectorErase:
		pha
		txa
		pha
		tya
		pha

		lda	#$80
		jsr	FlashCmdA
		jsr	FlashCmdShort
		lda	#$30
		sec
		jsr	romWrite
		clc
		lda	zp_mos_genPTR + 1
		adc	#$10
		sta	zp_SRLOAD_tmpA			; page after end of sector

		; check that sector has been erased
@1:		jsr	romRead
		cmp	#$FF
		bne	FlashSectorEraseErr
		inc	zp_mos_genPTR
		bne	@1
		ldx	zp_mos_genPTR+1
		inx
		stx	zp_mos_genPTR+1
		cpx	zp_SRLOAD_tmpA			; check for end
		bne	@1

FlashSectorEraseOK:
		clc
		beq	FlashSectorEraseExit
FlashSectorEraseErr:
		lda	#'E'
		jsr	OSWRCH
		lda	zp_ERASE_bank
		jsr	FLPrintHexA
		lda	zp_mos_genPTR + 1
		jsr	FLPrintHexA
		lda	zp_mos_genPTR
		jsr	FLPrintHexA
		sec
FlashSectorEraseExit:
FlashExitPLAXY:
		pla
		tay
FlashExitPLAX:
		pla
		tax
		pla
		rts


		; The business end of SRLOAD needs to be copied to main RAM
		; in case we want to overwrite this ROM!
Flash_SRLOAD:

		; check to see if dest is Flash - if so initialise flash writer
		lda	#OSWORD_BLTUTIL_RET_FLASH
		and	zp_SRLOAD_flags
		beq	cmdSRLOAD_go			; ram 

		jsr	FlashReset			; in case we're in software ID mode
		ldy	zp_SRLOAD_dest
		lda	zp_mos_genPTR+1
		pha
		jsr	FlashEraseROM
		pla	
		sta	zp_mos_genPTR+1			; restore pointer to start of rom again
		lda	#0
		sta	zp_mos_genPTR
cmdSRLOAD_go:
cmdSRLOAD_go_lp:
		ldy	#0
		lda	(zp_SRLOAD_ptr),Y		
		sta	zp_SRLOAD_tmpA			; save A for later
		lda	zp_SRLOAD_flags
		ldy	zp_SRLOAD_dest
		rol	A				; Cy contains FLASH bit
		lda	zp_SRLOAD_tmpA
		bcc	@skFl				; not EEPROM, just write to ROM
		; flash write byte command
		lda	#$A0		
		jsr	FlashCmdA			; Flash write byte command
		lda	zp_SRLOAD_tmpA			; get back value to write
		sec					; indicate to do FlashWriteToggle
@skFl:		jsr	romWrite
		jsr	romRead
		cmp	zp_SRLOAD_tmpA
		beq	@ok
		plp
		jmp	cmdSRCOPY_verfail
@ok:		jsr	FLPTRinc
		inc	zp_SRLOAD_ptr
		bne	cmdSRLOAD_go_lp
		inc	zp_SRLOAD_ptr + 1

		lda	zp_SRLOAD_ptr + 1
		and	#$07
		bne	@ss
		lda	#'.'
		jsr	OSASCI
@ss:		lda	zp_SRLOAD_ptr + 1
		cmp	#SRLOAD_buffer_page+$40
		bne	cmdSRLOAD_go_lp

		lda	#'O'
		jsr	OSASCI
		lda	#'K'
		jsr	OSASCI
		jsr	OSNEWL

		ldy	zp_SRLOAD_dest
		cpy	zp_mos_curROM
		bne	@out
		lda	#OSWORD_BLTUTIL_RET_ISCUR
		bit	zp_SRLOAD_flags
@stuck:		bne	@stuck
@out:		rts

cmdSRCOPY_verfail:
		pha
		lda	#'V'
		jsr	OSASCI				; TODO:debug - remove
		lda	zp_SRLOAD_bank
		jsr	FLPrintHexA
		lda	zp_mos_genPTR + 1
		jsr	FLPrintHexA
		lda	zp_mos_genPTR
		jsr	FLPrintHexA
		lda	#':'
		jsr	OSASCI
		pla
		jsr	FLPrintHexA
		lda	#'<'
		jsr	OSASCI
		lda	#'>'
		jsr	OSASCI
		lda	zp_SRLOAD_tmpA
		jsr	FLPrintHexA
		jsr	OSNEWL
@here:		jmp	@here
;		M_ERROR
;		.byte	$81, "Verify fail", 0


FLPTRinc:
		inc	zp_mos_genPTR
		bne	@sk
		inc	zp_mos_genPTR+1
@sk:		rts


FlashReset:
		pha
		lda	#$F0
		jsr	FlashCmdA
		pla
		rts


brkEraseFailed: M_ERROR
		.byte	$80, "Erase fail", 0

		; erase ROM slot Y (4 banks)
FlashEraseROM:
		pha
		txa
		pha
		tya
		pha
		lda	#4
		sta	zp_trans_acc+3			; erase the 4 sectors		
@1:		jsr	FlashSectorErase
		bcs	brkEraseFailed		
		dec	zp_trans_acc+3
		bne	@1
		pla
		tay
		pla
		tax
		pla
		rts

FLPrintHexA:	pha
		lsr	a
		lsr	a
		lsr	a
		lsr	a
		jsr	FLPrintHexNybA
		pla
		pha
		jsr	FLPrintHexNybA
		pla
		rts
FLPrintHexNybA:	and	#$0F
		cmp	#10
		bcc	@1
		adc	#'A'-'9'-2
@1:		adc	#'0'
		jmp	OSASCI



;=======================================================
		.CODE
;=======================================================


;------------------------------------------------------------------------------
; Write to ROM # in Y, addr in zp_mos_genPTR, data in A
;------------------------------------------------------------------------------
;
; have to copy this to main memory somewhere so we can access roms whilst
; flash is being twiddled with
; TODO: this is likely to corrupt main memory and render OLD useless at boot!
;

romWriteInit:	pha
		txa
		pha
		tya
		pha

		lda	zp_trans_acc
		pha
		lda	zp_trans_acc+1
		pha
		lda	zp_trans_acc+2
		pha
		lda	zp_trans_acc+3
		pha

		lda	#<__CODE_FLASH_LOAD__
		sta	zp_trans_acc
		lda	#>__CODE_FLASH_LOAD__
		sta	zp_trans_acc+1
		lda	#<__CODE_FLASH_RUN__
		sta	zp_trans_acc+2
		lda	#>__CODE_FLASH_RUN__
		sta	zp_trans_acc+3

		ldy	#0
		ldx	#>(__RAM_TRANS_FL_LAST__-__RAM_TRANS_FL_START__+1)
@2:		cpx	#0
		beq	@lastbit
@1:		lda	(zp_trans_acc+0),Y
		sta	(zp_trans_acc+2),Y
		iny
		bne	@1
		inc	zp_trans_acc+1
		inc	zp_trans_acc+3
		dex
		bpl	@2

@lastbit:
		ldy 	#<(__RAM_TRANS_FL_LAST__-__RAM_TRANS_FL_START__+1)
@ll:		dey
		lda	(zp_trans_acc+0),Y
		sta	(zp_trans_acc+2),Y
		tya
		bne	@ll		

		
		pla
		sta	zp_trans_acc+3
		pla
		sta	zp_trans_acc+2
		pla
		sta	zp_trans_acc+1
		pla
		sta	zp_trans_acc+0

		pla
		tay
		pla
		tax
		pla
		rts





FlashJim0055_Q:
		ldx	#<(PG_EEPROM_BASE+$0055)
		ldy	#>(PG_EEPROM_BASE+$0055)
JimXY_Q:		stx	fred_JIM_PAGE_LO
		sty	fred_JIM_PAGE_HI
		rts

FlashJim5555eqAAthen2A_Q:
		jsr	FlashJim0055_Q
		lda	#$AA
		sta	JIM + $55
FlashJim2AAAeq55_Q:
		ldy	#>(PG_EEPROM_BASE+$002A)
		ldx	#<(PG_EEPROM_BASE+$002A)
		jsr	JimXY_Q
		lda	#$55
		sta	JIM + $AA
		rts

FlashReset_Q:
		pha
		txa
		pha
		tya
		pha

;		jsr	FlashJim5555eqAAthen2A_Q
;		jsr	FlashJim0055_Q

		sei
		ldx	#FlashReset_Q_ACT_len
@lp:		lda	FlashReset_Q_ACT-1,X
		sta	a:$100-1,X
		dex
		bne	@lp

		lda	#$F0
;		jsr	$100
		cli

		pla
		tay
		pla
		tax
		pla
		rts

		; the next bit must be copied to low memory (stack base)
		; as the actual reset command will cause flash to reset for 150ns
FlashReset_Q_ACT:
		sta	JIM+$55
		rts

FlashReset_Q_ACT_len := *-FlashReset_Q_ACT
