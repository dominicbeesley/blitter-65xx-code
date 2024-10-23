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


;TODO: 
;      - SRNUKE erase current part of rom/ram space map / switch
;      - SRSAVE
;      - SRCOPY

; 2020/02/19 - reset flash in case stuck in programming/softid mode?



		.include	"mosrom.inc"
		.include 	"oslib.inc"
		.include	"common.inc"
		.include	"hardware.inc"
		.include	"bltutil.inc"


		.export cmdBLTurbo
		.export cmdXMdump
		.export cmdSRLOAD
		.export cmdSRNUKE
		.export cmdSRNUKE_reboot
		.export cmdSRNUKE_lang
		.export cmdSRERASE
		.export cmdSRCOPY
		.export cmdRoms
		.export cmdXMLoad
		.export cmdXMSave
		.export throttleInit
		.export cmdBLTurbo_PrintRomsInit
		.export cmdBLTurbo_PrintRomsA
		.export cmdBLTurbo_PrintRomsDone

		.CODE

;------------------------------------------------------------------------------
; Commands
;------------------------------------------------------------------------------

ParseIX01Flags:
		; check flags I, X|0|1
		lda	#OSWORD_BLTUTIL_FLAG_CURRENT
		sta	zp_SRLOAD_flags
@flagloop:	jsr	SkipSpacesPTR
		iny
		cmp	#13
		beq	@flagloopexit
		jsr	ToUpper
		cmp	#'I'
		beq	@flag_I
		cmp	#'X'
		beq	@flag_X
		cmp	#'0'
		beq	@flag_0
		cmp	#'1'
		beq	@flag_1
		jmp	brkBadCommand
@flag_I:	lda	zp_SRLOAD_flags
		ora	#OSWORD_BLTUTIL_FLAG_IGNOREMEMI
		bne	@nextflag
@flag_X:	lda	zp_SRLOAD_flags
		ora	#OSWORD_BLTUTIL_FLAG_ALTERNATE|OSWORD_BLTUTIL_FLAG_CURRENT
		bne	@nextflag
@flag_0:	lda	zp_SRLOAD_flags
		and	#OSWORD_BLTUTIL_FLAG_CURRENT
		bne	@nextflag
@flag_1:	lda	zp_SRLOAD_flags
		and	#OSWORD_BLTUTIL_FLAG_CURRENT^$FF
		ora	#1
@nextflag:	sta	zp_SRLOAD_flags
		jmp	@flagloop

@flagloopexit:

		pha					; blank for return hi
		lda	zp_SRLOAD_flags
		pha					; flags in to OSWORD
		lda	zp_SRLOAD_dest
		pha					; rom #
		lda	#5
		pha					; return length in bytes
		lda	#4				; send length in bytes
		tsx					; get X for OSWORD
		pha					
		lda	#OSWORD_BLTUTIL
		ldy	#1
		jsr	OSWORD
		pla
		pla
		pla
		sta	zp_SRLOAD_flags
		pla	
		sta	zp_mos_genPTR + 1			
		pla	
		sta	zp_SRLOAD_bank

		rts


cmdSRLOAD:	jsr	CheckBlitterPresentBrk		

		; force mode 7
		lda	#22
		jsr	OSWRCH
		lda	#7
		jsr	OSWRCH


@bp:		jsr	SkipSpacesPTR
		cmp	#$D
		bne	@s1
		jmp	brkBadCommand			; no filename!
@s1:		clc
		tya
		adc	zp_mos_txtptr
		sta	ADDR_ERRBUF			; store pointer to filename for OSFILE later
		lda	zp_mos_txtptr + 1
		adc	#0
		sta	ADDR_ERRBUF + 1
		dey
@lp1:		iny
		lda	(zp_mos_txtptr),Y		
		cmp	#' '
		bcs	@s3
		jmp	brkBadId			; < ' ' means end of command no id!
@s3:		bne	@lp1
		lda	#$D
		sta	(zp_mos_txtptr),Y		; overwrite ' ' with $D to terminate filename
		iny
		jsr	SkipSpacesPTR

		jsr	ParseHex
		bcc	@s2
		jmp	brkBadId
@s2:		jsr	CheckId
		sta	zp_SRLOAD_dest			; dest id

		jsr	ParseIX01Flags


		jsr	PrintImmedT
		.byte	"Loading ROM..."
		.byte 	13|$80

		; setup OSFILE block to point at $FFFF4000 and load there
		lda	#SRLOAD_buffer_page
		sta	ADDR_ERRBUF + 3
		ldx	#0
		stx	ADDR_ERRBUF + 2
		stx	ADDR_ERRBUF + 6			; clear exec address low byte (use my address)
		ldx	#$FF
		stx	ADDR_ERRBUF + 4
		stx	ADDR_ERRBUF + 5
		txa
		ldx	#<ADDR_ERRBUF
		ldy	#>ADDR_ERRBUF
		jsr	OSFILE				; load file

		jsr	PrintImmedT
		TOPTERM	"Writing"

		; now copy to flash/sram
		jsr	romWriteInit			; initialise the ROM writer - any error will trash this!


		php
		sei					; try inhibit interrupts; TODO: is this necessary?

		ldy	#0
		sty	zp_mos_genPTR
		sty	zp_SRLOAD_ptr
		lda	#SRLOAD_buffer_page
		sta	zp_SRLOAD_ptr + 1

		jsr	Flash_SRLOAD

		plp
		rts

cmdBLTurboQry:
		tya
		pha					; preserve command ptr
		ldx	#<strCmdBLTurbo
		ldy	#>strCmdBLTurbo
		jsr	PrintXY				; "BLTURBO"
		jsr	PrintSpc
		; lomem
		lda	#'L'				; "Lxx"
		jsr	OSWRCH
		lda	sheila_MEM_LOMEMTURBO
		jsr	PrintHexA
		jsr	PrintSpc
		; mos
		lda	#'M'				; "M[-]"
		jsr	OSWRCH
		lda	SHEILA_ROMCTL_MOS
		and	#BITS_MEM_CTL_SWMOS
		cmp	#BITS_MEM_CTL_SWMOS
		beq	@smoff
		lda	#'-'
		jsr	OSWRCH
@smoff:		
		jsr	PrintSpc
		; throttle
		lda	#'T'
		jsr	OSWRCH
		lda	sheila_MEM_TURBO2
		bmi	@ton
		lda	#'-'
		jsr	OSWRCH
@ton:

		jsr	cfgGetAPISubLevel_1_2
		bcc	cmdBLTurboEnd

		; Throttled ROMS
		lda	sheila_ROM_THROTTLE_0
		ora	sheila_ROM_THROTTLE_1
		beq	@noroms
		jsr	PrintSpc

		jsr	cmdBLTurbo_PrintRomsInit
		lda	sheila_ROM_THROTTLE_0
		jsr	cmdBLTurbo_PrintRomsA
		lda	sheila_ROM_THROTTLE_1
		jsr	cmdBLTurbo_PrintRomsA
		jsr	cmdBLTurbo_PrintRomsDone

@noroms:	jsr	OSNEWL

		pla
		tay					; restore command pointer
		jmp	cmdBLTurbo_NextClr

cmdBLTurbo_PrintRomsInit:
		ldx	#0
		stx	zp_trans_tmp			; flags $80 had hit
		rts

cmdBLTurbo_PrintRomsA:

@bltrom8:	sta	zp_trans_tmp+2
		ldy	#8
@bltrom8lp:	ror	zp_trans_tmp+2
		bcc	@no
		bit	zp_trans_tmp
		bvs	@bltrom8nxt
		bmi	@already
		lda	#'R'
		bne	@blsk1
@already:	lda	#','
@blsk1:		jsr	PrintA
		txa
		jsr	PrintDecA
		lda	#$C0
		sta	zp_trans_tmp			; mark already
		stx	zp_trans_tmp+1			; first in range
@bltrom8nxt:	inx
		dey
		bne	@bltrom8lp
		rts
@no:		jsr	@checkclose
		jmp	@bltrom8nxt

@checkclose:
cmdBLTurbo_PrintRomsDone:
		bit	zp_trans_tmp
		bpl	@r
		bvc	@r				; no range open
		lda	#$80
		sta	zp_trans_tmp
		dex
		cpx	zp_trans_tmp+1			; check if range
		beq	@s
		lda	#'-'
		jsr	PrintA
		txa
		jsr	PrintDecA
@s:		inx
@r:		rts



cmdBLTurboEnd:
		rts
cmdBLTurbo:	
		jsr	CheckBlitterPresentBrk	
cmdBLTurbo_NextClr:					; return here after doing a command to clear flags
		lda	#0
		sta	zp_trans_tmp	
cmdBLTurbo_Next:					; return here to retain flags

		jsr	SkipSpacesPTR
		iny
		jsr	ToUpper
		cmp	#'T'
		beq	cmdBLTurboThrottle
		cmp	#'M'
		beq	cmdBLTurboMos
		cmp	#'R'
		bne	:+
		jmp	cmdBLTurboRom
:		cmp	#'L'
		bne	:+
		jmp	cmdBLTurboLo
:		cmp	#'?'
		bne	:+
		jmp	cmdBLTurboQry
:		cmp	#13
		beq	cmdBLTurboEnd
		cmp	#'-'
		bne	:+
		lda	#$40
		jsr	setf
		bne	cmdBLTurbo_Next
:		jmp	brkBadCommand
setf:		ora	zp_trans_tmp
		sta	zp_trans_tmp
		rts

cmdBLTCheckEnd:
		jsr	SkipSpacesPTR
		cmp	#' '+1
		bcc	:+
		jmp	brkBadCommand
:		bit	zp_trans_tmp
		rts
cmdBLTurboThrottle:
		jsr	cmdBLTCheckEnd
		bvs	@cmdBLTurboThrottle_off
@cmdBLTurboThrottle_on:
		lda	sheila_MEM_TURBO2
		ora	#BITS_MEM_TURBO2_THROTTLE
		bne	@s2
@cmdBLTurboThrottle_off:
		lda	sheila_MEM_TURBO2
		and	#BITS_MEM_TURBO2_THROTTLE ^ $FF
@s2:		sta	sheila_MEM_TURBO2		
		jmp	cmdBLTurbo_NextClr


cmdBLTurboMos:	jsr	cmdBLTCheckEnd
		bvs	cmdBLTurboMos_off

		tya
		pha	
		php					; preserve command pointer and interrupts

		; check to find the ROM slot to use
		pha					; + 4	reserve for return value
		lda	#OSWORD_BLTUTIL_FLAG_CURRENT
		pha					; + 3	flags in
		lda	#8				; rom # to use for shadow MOS
		pha					; + 2	rom no
		lda	#5
		pha					; output length
		lda	#4
		tsx
		pha					; input length
		ldy	#1
		lda	#OSWORD_BLTUTIL
		jsr	OSWORD
		pla
		pla
		pla
		sta	zp_blturbo_fl
		pla
		sta	zp_blturbo_ptr
		pla
		sta	zp_blturbo_ptr+1

		lda	#OSWORD_BLTUTIL_RET_MAP1
		and	zp_blturbo_fl
		bne	cmdBLTurbo_MOSWarnAlready

		; This is map one, the MOS is already from a fast chip
		lda	#OSWORD_BLTUTIL_RET_FLASH|OSWORD_BLTUTIL_RET_SYS
		and	zp_blturbo_fl
		beq	:+
		jmp	cmdBLTurbo_MOSBadSlot
:

		lda	#OSWORD_BLTUTIL_RET_MEMI
		and	zp_blturbo_fl
		beq	:+
		jmp	cmdBLTurbo_MOSInhib
:


		; check to see if rom #8 is booted
		lda	oswksp_ROMTYPE_TAB+8
		beq	:+
		jmp	cmdBLTurbo_MOSBadSlot
:


		; copy mos rom from FFCxxx to 7F0xxx
		ldx	#$C0

@l1:		jsr	bljimFF				; copy mos to SWROM slot 8
		stx	fred_JIM_PAGE_LO
		lda	JIM,Y
		pha
		lda	zp_blturbo_ptr
		sta	fred_JIM_PAGE_LO
		lda	zp_blturbo_ptr+1
		sta	fred_JIM_PAGE_HI
		pla
		sta	JIM,Y
		iny
		bne	@l1
		inc	zp_blturbo_ptr
		inx
		beq	@s1
		cpx	#$FC				; skip hardware pages		
		bne	@l1
		; skip pages FC-FE
		inx
		inx
		inx
		inc	zp_blturbo_ptr		
		inc	zp_blturbo_ptr		
		inc	zp_blturbo_ptr		
		bne	@l1


@s1:
		sei
		lda	SHEILA_ROMCTL_MOS
		ora	#BITS_MEM_CTL_SWMOS		; start shadow mos
		sta	SHEILA_ROMCTL_MOS	
		bne	cmdBLTurbo_NextMOS	

cmdBLTurboMos_off:

		sei
		iny					; skip -
		lda	sheila_MEM_CTL
		and	#(~BITS_MEM_CTL_SWMOS) & $FF
		sta	sheila_MEM_CTL
cmdBLTurbo_NextMOS:
		plp
		pla
		tay
		jmp	cmdBLTurbo_NextClr
cmdBLTurbo_MOSWarnAlready:
		jsr	PrintImmedT
		.byte	"Map 1: MOS already turbo"
		.byte 	13|$80

		jmp	cmdBLTurbo_NextMOS
cmdBLTurbo_MOSBadSlot:
		M_ERROR
		.byte	$FF, "Slot 8 is not RAM or is in use",0
cmdBLTurbo_MOSInhib:
		M_ERROR
		.byte	$FF, "Blitter inhibited",0

cmdBLTurbo_NotSupp:
		M_ERROR
		.byte	$FF, "Not supported",0


cmdBLTurboRom:
		jsr	cfgGetAPISubLevel_1_2
		bcc	cmdBLTurbo_NotSupp
		
		jsr	cmdBLTurboRomsParse

		tya
		pha
		bit	zp_trans_tmp		; get V flag for V=1 clear, V=0 set
		ldy	#0
		lda	zp_trans_tmp+1
		jsr	@setclr
		lda	zp_trans_tmp+2
		ldy	#2
		jsr	@setclr

		pla
		tay

		jmp	cmdBLTurbo_NextClr

@setclr:	sta	zp_trans_tmp		; we don't need this any more for flags use as temp
		lda	sheila_ROM_THROTTLE_0,Y
		bvc	@f1
		eor	#$FF
@f1:		ora	zp_trans_tmp
		bvc	@f2
		eor	#$FF
@f2:		sta	sheila_ROM_THROTTLE_0,Y
		rts

	; on entry zp_tran_tmp contains the +/- flag in $40
	; but should be otherwise empty
	;
	; enabled/disabled roms set in zp_trans_tmp+1,2
	; 

cmdBLTurboRomsParse:
		clc
		ror	zp_trans_tmp			; move +/- flag into $20
		lda	#0
		sta	zp_trans_tmp+1
		sta	zp_trans_tmp+2

@lp:		lda	(zp_mos_txtptr),Y
		cmp	#' '+1
		bcc	@endcheck
		cmp	#'-'
		beq	@range
		cmp	#','
		beq	@sep
		
		jsr	ParseDecOrHex
		bcs	@brkInvalidArgument3
		
		; check for 0..15
		lda	zp_trans_acc+3
		ora	zp_trans_acc+2
		ora	zp_trans_acc+1
		bne	@brkInvalidArgument3
		lda	zp_trans_acc+0
		cmp	#16
		bcs	@brkInvalidArgument3

		; we have a number, if we just had a hyphen close range
		lda	#1
		bit	zp_trans_tmp
		bne	@closerange
		
		; flag we've had a number
		lda	#$C0
		jsr	setf				; had number, open number ready for '-'
		lda	zp_trans_acc
		sta	zp_trans_tmp+3			; remember last number (for ranges)
		jsr	@setA

		jmp	@lp

@closerange:	; had a range 
		ldx	zp_trans_acc		
@closerangenxt:
		cpx	zp_trans_tmp+3
		bcc	@clearng			; if end of range exit and reset range flags
		txa
		jsr	@setA
		dex
		bne	@closerangenxt

@setA:		cmp	#$8
		php					; set Cy if in 2nd byte
		and	#$7
		jsr	MaskBitA
		plp
		bcs	@h
		ora	zp_trans_tmp+1
		sta	zp_trans_tmp+1
		rts
@h:		ora	zp_trans_tmp+2
		sta	zp_trans_tmp+2
		rts
@clearng:	lda	#$FE
		bne	@nextF

@sep:		iny
		bit	zp_trans_tmp
		bpl	@brkInvalidArgument3		; not had a number error
		bvc	@brkInvalidArgument3		; range not open
		lda	#$A0
@nextF:		and	zp_trans_tmp			; clear range open, had hyphen flags
		bne	@nxt		

@range:		iny
		bit	zp_trans_tmp
		bpl	@brkInvalidArgument3		; not had a number error
		bvc	@brkInvalidArgument3		; range not open
		lda	#1
		ora	zp_trans_tmp			; indicate we've had a -
@nxt:		sta	zp_trans_tmp
		bne	@lp				




@endcheck:	lda	#1
		bit	zp_trans_tmp			
		bpl	@brkInvalidArgument3		; we've not had anything throw error
		bne	@brkInvalidArgument3		; range left hanging
		rol	zp_trans_tmp
		rts


@brkInvalidArgument3:
		jmp	brkInvalidArgument
		


cmdBLTurboLo:	
		jsr	ParseHex		
		bcc	cmdBLTurboLo_s1
brkInvalidArgument2:
		jmp	brkInvalidArgument
cmdBLTurboLo_s1:		
		tya
		pha					; store text pointer
		php					; save interrupt status
		sei					; disable interrupts as memory is going to move
		
		jsr	jimSetDEV_blitter

		lda	zp_trans_acc+0
		sta	zp_blturbo_new			; save the new mask in the old zp
		pha
		lda	sheila_MEM_LOMEMTURBO
		sta	zp_blturbo_old			; get the old mask and store in the old zp

		; suspect zp_blturbo_ptr is not needed (see 6809 implementation)
		lda	#0
		sta	zp_blturbo_ptr
		sta	zp_blturbo_ptr+1
@l1:		; compare flags in old/new:
		; - if old = 1 and new = 0 then copy from JIM to SYS else 
		; - if old = 0 and new = 1 then copy from SYS to JIM else
		; - do nowt

		ldx	#$10				; preload number of pages
		ldy	#0				; and page counter

		ror	zp_blturbo_new
		bcc	@new_not_turbo
		; new is turbo, check old
		ror	zp_blturbo_old
		bcs	@donowt
		; new is turbo, old is not, copy SYS to JIM
@s2jl2:
		lda	zp_blturbo_ptr+1
		sta	fred_JIM_PAGE_LO
@s2jl:		jsr	bljimFF
		lda	JIM,Y				; read from SYS
		jsr	bljim0
		sta	JIM,Y				; write to shadow
		iny
		bne	@s2jl
		inc	zp_blturbo_ptr+1		; incremenet page
		dex	
		bne	@s2jl2
		beq	@snext				; copy done

@new_not_turbo:	
		ror	zp_blturbo_old
		bcc	@donowt
		; new is SYS, old is not, copy JIM to SYS
@j2sl2:
		lda	zp_blturbo_ptr+1
		sta	fred_JIM_PAGE_LO
@j2sl:		jsr	bljim0
		lda	JIM,Y				; read from shadow
		jsr	bljimFF
		sta	JIM,Y				; write to sys
		iny
		bne	@j2sl
		inc	zp_blturbo_ptr+1		; incremenet page
		dex	
		bne	@j2sl2
		beq	@snext				; copy done
@donowt:	clc
		lda	zp_blturbo_ptr+1
		adc	#$10
		sta	zp_blturbo_ptr+1
@snext:		lda	zp_blturbo_ptr+1
		bpl	@l1



		pla
		sta	sheila_MEM_LOMEMTURBO		; switch to new map
		plp					; restore interrupts
		pla
		tay					; get back text pointer

		jmp	cmdBLTurbo_Next
bljim0:		pha
		lda	#0
		sta	fred_JIM_PAGE_HI
		pla
		rts
bljimFF:	pha
		lda	#$FF
		sta	fred_JIM_PAGE_HI
		pla
		rts
bljim7F:	pha
		lda	#$7F
		sta	fred_JIM_PAGE_HI
		pla
		rts


; these flags match those into OSWORD 99
CMDROMS_FLAGS_CURRENT		:=	$80			; when set show current/alternate set, when clear bit 0 indicates which map
CMDROMS_FLAGS_ALTERNATE		:=	$40			; when set show alternate roms
CMDROMS_FLAGS_IGNOREMEMI	:=	$20			; ignore memi
CMDROMS_FLAGS_MAP1		:=	$01
CMDROMS_FLMASK			:=	$E1			; used to map out non OSWORD 99 flags

CMDROMS_FLAGS_VERBOSE		:=	$08
CMDROMS_FLAGS_CRC		:=	$04
CMDROMS_FLAGS_ALL		:=	$02


		;	FLAG	OR			AND
cmdRoms_tbl:	.byte	'C',	CMDROMS_FLAGS_CRC,				$FF
		.byte	'V',	CMDROMS_FLAGS_VERBOSE,				$FF
		.byte	'A',	CMDROMS_FLAGS_ALL,				$FF
		.byte	'X',	CMDROMS_FLAGS_CURRENT|CMDROMS_FLAGS_ALTERNATE,	$FF ^ CMDROMS_FLAGS_MAP1
		.byte	'0',	0,						$FF ^ (CMDROMS_FLAGS_MAP1|CMDROMS_FLAGS_CURRENT|CMDROMS_FLAGS_ALTERNATE)
		.byte	'1',	CMDROMS_FLAGS_MAP1,				$FF ^ (CMDROMS_FLAGS_MAP1|CMDROMS_FLAGS_CURRENT|CMDROMS_FLAGS_ALTERNATE)
		.byte	'I',	CMDROMS_FLAGS_IGNOREMEMI,			$FF
cmdRoms_tbl_len :=	*-cmdRoms_tbl


cmdRomsCopyAddr:
		lda	#<$8007
		sta	zp_mos_genPTR
		ldy	zp_ROMS_ctr
		jsr	cmdRoms_ReadRom2
		sta	zp_mos_genPTR
@s1:		rts


cmdRoms:	
		lda	#CMDROMS_FLAGS_CURRENT
		sta	zp_ROMS_flags
cmdRomsNextArg:
		jsr	SkipSpacesPTR
		cmp	#13
		beq	cmdRoms_Go
		iny
		cmp	#'-'
		beq	cmdRomsNextArg
		jsr	ToUpper
		ldx	#cmdRoms_tbl_len
@l1:		cmp	cmdRoms_tbl-3,X
		bne	@s1
		lda	zp_ROMS_flags
		and	cmdRoms_tbl-1,X
		ora	cmdRoms_tbl-2,X
		sta	zp_ROMS_flags
		jmp	cmdRomsNextArg
@s1:		dex
		dex
		dex
		bne	@l1
@s7:		jmp	brkInvalidArgument


cmdRoms_Go:		
		jsr	PrintImmedT
		.byte	"  # act  crc typ ver Title", 13
		.byte	" == === ==== === === ====="
		.byte	$D|$80

		lda	#0
		sta	zp_ROMS_ctr
cmdRoms_lp:	
		; get rom base using OSWORD 99
		lda	#0
		sta	zp_mos_genPTR
		pha					; return hi
		lda	zp_ROMS_flags
		and	#CMDROMS_FLMASK
		pha
		lda	zp_ROMS_ctr
		pha
		lda	#5				; OSWORD return len
		pha
		lda	#4				; OSWORD in len
		tsx
		pha
		ldy	#1
		lda	#OSWORD_BLTUTIL
		jsr	OSWORD
		pla
		pla					; ignore lengths
		pla					
		sta	zp_ROMS_OS99ret			; contains return flags from OS99
		pla			
		sta	zp_mos_genPTR+1			; LO page
		pla	
		sta	zp_ROMS_bank			; HI page

		jsr	cfgGetAPISubLevel_1_2
		bcc	@s3

		; print "T" for rom throttle active

		lda	zp_ROMS_OS99ret
		and	#OSWORD_BLTUTIL_RET_ISCUR
		bne	@st1a

	.assert BLTUTIL_CMOS_FW_ROM_THROT = 0, error, "Code assumes offset 0"
		; alt set - get from CMOS
		lda	zp_ROMS_OS99ret
		and	#1
		clc
		ror	A
		ror	A
		ror	A			; get map 0/1 into bit 6
		ldy	zp_ROMS_ctr
		cpy	#8
		rol	A			; bit 0 = 1 if >8 bit 7 = 1 if map 1
		tax
		jsr	CMOS_ReadYX
		eor	#$FF
		tay
		lda	zp_ROMS_ctr
		jmp	@s1

@st1a:		lda	zp_ROMS_ctr
		ldy	sheila_ROM_THROTTLE_0
		cmp	#8
		bcc	@s1
		ldy	sheila_ROM_THROTTLE_1
@s1:		and	#$7
		tax
		tya
@l1:		dex
		bmi	@s2
		ror	A		
		bne	@l1
@s2:		and	#1
		beq	@s3
		
		lda	#'T'
		jsr	OSWRCH
		jsr	PrintSpc
		jmp	@s4

@s3:		jsr	Print2Spc
@s4:	

		lda	zp_ROMS_ctr
		jsr	PrintHexNybA			; rom #
		jsr	Print2Spc



		lda	zp_ROMS_OS99ret
		and	#OSWORD_BLTUTIL_RET_ISCUR
		bne	@st1

		; print na
		lda	#'-'
		jsr	OSWRCH
		jsr	OSWRCH
		jsr	PrintSpc
		jmp	cmdRoms_fullcheck

		; print "active" rom type from OS table
@st1:		ldy	zp_ROMS_ctr
		lda	oswksp_ROMTYPE_TAB,Y
		pha
		jsr	PrintHexA
		jsr	PrintSpc

		pla
		bne	cmdRoms_checkedOStab	

		lda	zp_ROMS_flags
		and	#CMDROMS_FLAGS_ALL
		bne	cmdRoms_fullcheck
		beq	cmdRoms_sk_notrom

cmdRoms_checkedOStab:

		jsr	cmdRoms_DoCRC

		jsr	cmdRomsCopyAddr			; get copyright pointer
		lda	zp_mos_genPTR
		sta	zp_ROMS_copyptr			; store for compare

		; tis a ROM, print type
		lda	#<$8006
		sta	zp_mos_genPTR
		ldy	zp_ROMS_ctr
		jsr	cmdRoms_ReadRom2

		jsr	PrintHexA
		jsr	Print2Spc

		jsr	PTRinc
		jsr	PTRinc				; point at 8008


		; print version
		jsr	cmdRoms_ReadRom2
		jsr	PrintHexA
		jsr	PrintSpc

		jsr	PTRinc				; point at 8009		

		; print title / all strings
		lda	zp_ROMS_flags
		and	#CMDROMS_FLAGS_VERBOSE
		beq	cmdRoms_NoVer

@1:		jsr	cmdRoms_PrintPTR		; print title and optional version str
		jsr	PrintSpc
		lda	zp_mos_genPTR
		cmp	zp_ROMS_copyptr			; copyright offset
		bcc	@1

cmdRoms_NoVer:	jsr	cmdRoms_PrintPTR		; print copyright string
		jmp	cmdRoms_sk_nextrom

cmdRoms_fullcheck:
		

		; if this is SYS and not the current map then skip with SYS message
		lda	zp_ROMS_OS99ret
		and 	#OSWORD_BLTUTIL_RET_SYS|OSWORD_BLTUTIL_RET_ISCUR
		cmp 	#OSWORD_BLTUTIL_RET_SYS
		bne	@notsys1

		jsr	PrintImmedT
		TOPTERM "-- SYS"

		jmp	cmdRoms_sk_nextrom


@notsys1:	; check for (C) symbol, if not present skip this rom
		jsr	cmdRomsCopyAddr
		; PTR now points at (C) of copyright
		ldx	#0
		ldy	zp_ROMS_ctr
@lp:		jsr	cmdRoms_ReadRom2
		cmp	Copyright,X
		beq	@s
		jmp	cmdRoms_sk_notrom
@s:		inx
		cpx	#4
		beq	cmdRoms_checkedOStab
		jsr	PTRinc
		bne	@lp

cmdRoms_sk_notrom:

		lda	#CMDROMS_FLAGS_ALL
		bit	zp_ROMS_flags
		beq	@1				; not VA
		jsr	cmdRoms_DoCRC
@1:		jsr	PrintImmedT
		TOPTERM "--"

cmdRoms_sk_nextrom:
		jsr	PrintNL
		inc	zp_ROMS_ctr
		lda	#15
		cmp	zp_ROMS_ctr
		bcc	@s1
		jmp	cmdRoms_lp
@s1:		rts


cmdRoms_DoCRC:
		lda	#CMDROMS_FLAGS_CRC
		bit	zp_ROMS_flags		
		beq	cmdRoms_skipCRC
		lda	#<$8000
		sta	zp_mos_genPTR
		lda	zp_mos_genPTR+1
		pha					; save rom base page
		lda	#0
		sta	zp_trans_acc
		sta	zp_trans_acc + 1		
		ldx	#$40				; # of pages to process
@1:		ldy	zp_ROMS_ctr
		jsr	cmdRoms_ReadRom2
		jsr	crc16
		inc	zp_mos_genPTR		
		bne	@1
		jsr	CheckESC
		inc	zp_mos_genPTR + 1
		dex
		bne	@1
		lda	zp_trans_acc + 1
		jsr	PrintHexA
		lda	zp_trans_acc + 0
		jsr	PrintHexA
		pla
		sta	zp_mos_genPTR+1			; restore rom base page
		jmp	Print2Spc


cmdRoms_skipCRC:
		jsr	Print2Spc
		jsr	Print2Spc
		jmp	Print2Spc


cmdRoms_PrintPTR:
		ldy	zp_ROMS_ctr
		ldx	#40
@1:		jsr	cmdRoms_ReadRom2
		jsr	PTRinc
		cmp	#0
		beq	@2
		cmp	#' '
		bcc	@1				; skip CR/LF in BASIC (C)
		jsr	PrintA
		dex
		bne	@1
@2:		rts


		; this is not copied to trampoline but accessed in this rom
cmdRoms_ReadRom2:
		pha
		tya
		pha
		txa
		pha
		ldx	zp_ROMS_bank
		inx
		bne	cmdRoms_ReadRom2_JIM
		jsr	OSRDRM
cmdRoms_ReadRom2_ret:
		tsx
		sta	$103,X
		pla
		tax
		pla
		tay
		pla
		rts
cmdRoms_ReadRom2_JIM:
		lda	zp_ROMS_bank
		sta	fred_JIM_PAGE_HI
		lda	zp_mos_genPTR+1
		sta	fred_JIM_PAGE_LO
		ldx	zp_mos_genPTR
		lda	JIM,X
		jmp	cmdRoms_ReadRom2_ret


ERASE_FLAG_FORCE	:= $02

cmdSRERASE:
		jsr	CheckBlitterPresentBrk	
		jsr	romWriteInit			; initialise the ROM writer - any error will trash this!
		lda	#0
		sta	zp_ERASE_flags
		jsr	ParseHex
		bcc	@s1
		jmp	brkBadId
@s1:		jsr	CheckId
		sta	zp_ERASE_dest			; dest id
		jsr	SkipSpacesPTR
		jsr	ToUpper
		cmp	#'F'
		bne	@1
		iny
		lda	#ERASE_FLAG_FORCE
		sta	zp_ERASE_flags		
@1:		lda	zp_ERASE_flags
		pha					; push force flag
		jsr	ParseIX01Flags
		pla	
		ora	zp_ERASE_flags
		sta	zp_ERASE_flags

		jsr	PrintErase

		; check for EEPROM
		and	#OSWORD_BLTUTIL_RET_FLASH
		beq	cmdSRERASE_RAM


		jsr	PrintFlash
		jsr	PrintAt
		lda	zp_ERASE_dest
		tay
		jsr	PrintHexNybA
		jsr	PrintElip
		jmp	FlashEraseROM

cmdSRERASE_RAM:

		jsr	PrintSRAM
		jsr	PrintAt
		lda	zp_ERASE_dest
		jsr	PrintHexNybA
		jsr	PrintElip

		lda	#0
		sta	zp_ERASE_errct			; fail counter
		sta	zp_ERASE_errct + 1
		sta	zp_mos_genPTR
		lda	#$40
		sta	zp_ERASE_ctr

@1:		ldy	zp_ERASE_dest
		lda	#$FF
		clc
		jsr	romWrite
		jsr	romRead
		cmp	#$FF
		bne	@2
@3:		inc	zp_mos_genPTR
		bne	@1
		inc	zp_mos_genPTR + 1
		dec	zp_ERASE_ctr
		bne	@1
		lda	zp_ERASE_errct
		ora	zp_ERASE_errct+1
		bne	@4
		jsr	PrintOK
		rts
@4:		; got to end with errors
		lda	#'&'
		jsr	PrintA
		lda	zp_ERASE_errct + 1
		jsr	PrintHexA
		lda	zp_ERASE_errct
		jsr	PrintHexA
		jmp	PrintImmedT
		TOPTERM	" errors detected"
@2:		inc	zp_ERASE_errct
		bne	@s
		inc	zp_ERASE_errct + 1
@s:		lda	ERASE_FLAG_FORCE
		bit	zp_ERASE_flags
		bne	@3				; continue - F switch in force		
		jsr	PrintImmedT
		TOPTERM	"failed at "
		lda	zp_SRLOAD_bank
		jsr	PrintHexA
		lda	zp_mos_genPTR + 1
		jsr	PrintHexA
		lda	zp_mos_genPTR + 0
		jsr	PrintHexA
		jmp	brkEraseFailed

cmdSRCOPY:
		jsr	CheckBlitterPresentBrk		
		M_ERROR
		.byte 	$FF, "Not implemented", 0
		rts
;X;		jsr	romWriteInit			; initialise the ROM writer - any error will trash this!
;X;
;X;		jsr	ParseHex
;X;		lbcs	brkBadId
;X;		jsr	CheckId
;X;		sta	zp_SRCOPY_dest			; dest id
;X;		jsr	ParseHex
;X;		lbcs	brkBadId
;X;		jsr	CheckId
;X;		sta	zp_SRCOPY_src			; src id
;X;		jsr	SkipSpacesX
;X;		cmpa	#$D
;X;		lbne	brkBadCommand
;X;
;X;		lda	zp_SRCOPY_dest
;X;		cmpa	zp_SRCOPY_src
;X;		lbeq	brkBadCommand			; don't copy to self
;X;
;X;		clr	zp_SRCOPY_flags
;X;		; check to see if dest is ROM (4-7)
;X;		jsr	IsFlashBank
;X;		bne	cmdSRCOPY_init_RAM		; ram in odd banks
;X;		dec	zp_SRCOPY_flags
;X;
;X;		ldx	#strSRCOPY2FLASH
;X;		lda	zp_SRCOPY_dest
;X;		jsr	PrintMsgThenHexNybImmed
;X;		
;X;
;X;		clra
;X;		ldb	zp_SRCOPY_dest
;X;		tfr	D,Y				; rom #
;X;
;X;		jsr	FlashReset			; in case we're in software ID mode
;X;		jsr	FlashEraseROM
;X;		bra	cmdSRCOPY_go
;X;
;X;cmdSRCOPY_init_RAM
;X;		ldx	#strSRCOPY2RAM
;X;		lda	zp_SRCOPY_dest
;X;		jsr	PrintMsgThenHexNyb
;X;
;X;cmdSRCOPY_go
;X;		ldx	#str_Copying
;X;		jsr	PrintX
;X;		ldx	#$8000
;X;		ldb	zp_SRCOPY_src
;X;		clra
;X;		std	zp_trans_acc
;X;		ldb	zp_SRCOPY_dest
;X;		clra
;X;		std	zp_trans_acc + 2
;X;
;X;cmdSRCOPY_go_lp
;X;		ldy	zp_trans_acc			; src ROM #
;X;		jsr	OSRDRM
;X;		ldy	zp_trans_acc + 2		; dest ROM #
;X;		pshs	A				; save A for later
;X;		tst	zp_SRCOPY_flags
;X;		bpl	1F				; not EEPROM, just write to ROM
;X;		; flash write byte command
;X;		lda	#$A0
;X;		jsr	FlashCmdA			; Flash write byte command
;X;		lda	,S
;X;1		jsr	romWrite
;X;		tst	zp_SRCOPY_flags
;X;		bpl	1F
;X;		jsr	FlashWaitToggle
;X;1		jsr	OSRDRM
;X;		cmpa	,S+
;X;		bne	cmdSRCOPY_verfail
;X;
;X;		leax	1,X
;X;		cmpx	#$C000
;X;		bne	cmdSRCOPY_go_lp
;X;		ldx	#str_OK
;X;		jmp	PrintX



CheckId:
		lda	zp_trans_acc + 3		; check acc > 16
		ora	zp_trans_acc + 2
		ora	zp_trans_acc + 1
		bne	brkBadId
		lda	zp_trans_acc + 0
		cmp	#$10
		bcs	brkBadId
		rts
brkBadId:
		M_ERROR
		.byte	$FC, "Bad Id", 0

brkFileNotFound:
		M_ERROR
		.byte	$D6, "File not found", 0

		; BRK handler

cmdSRNUKE_lang_brk:
		; skip pushed flags
		plp
		pla					; address of brk+2
		sec
		sbc	#1
		sta	zp_tmp_ptr
		pla
		sbc	#0
		sta	zp_tmp_ptr + 1
		ldy	#0
		lda	(zp_tmp_ptr),Y
		iny
		jsr	OSNEWL
		jsr	PrintHexA
		jsr	PrintSpc
		jsr	PrintPTR
		jsr	OSNEWL
		jsr	OSNEWL

		ldx	ZP_NUKE_S_TOP
		tsx					; restore stack

		bne	cmdSRNUKE



cmdSRNUKE_lang:	;Set ourselves up as a language and take over the machine
		;This is not working - at present only captures BRK handler!

		ldx	sysvar_CUR_LANG
		stx	ZP_NUKE_PREVLANG		; remember prev language

		ldx	zp_mos_curROM
		stx	sysvar_CUR_LANG			; become language

		lda	#<cmdSRNUKE_lang_brk
		sta	BRKV
		lda	#>cmdSRNUKE_lang_brk
		sta	BRKV+1

		tsx
		stx	ZP_NUKE_S_TOP				; where to reset stack to on error
		cli
		jsr	cmdSRNUKE

		jmp	cmdSRNUKE_reboot


cmdSRNUKE:	

		; cmdRoms no VA
		ldx	#CMDROMS_FLAGS_VERBOSE+CMDROMS_FLAGS_ALL
		stx	ZP_NUKE_ROMSF

cmdSRNUKE_mainloop:
		ldx	ZP_NUKE_ROMSF
		stx	zp_ROMS_flags
		jsr	cmdRoms_Go
		
		; SHOW MENU
		jsr	PrintImmedT
		.byte	13, "0) Exit	1) Erase Flash	2) Erase RAM	3) Show CRC	4) Erase #"
		.byte   13|$80

		jsr	CheckBlitterPresent
		bcc	@s
		jsr	PrintImmedT
		.byte 	"WARNING: blitter not detected!"
		.byte	13|$80

@s:


@1:		jsr	inkey_clear
		bcs	@1
		txa
		jsr	CheckESC

		cpx	#'0'
		bne	@not0
		jmp	cmdSRNUKE_exit
@not0:		cpx	#'1'
		bne	@not1
		jmp	cmdSRNUKE_flash
@not1:		cpx	#'2'
		bne	@not2
		jmp	cmdSRNUKE_ram
@not2:		cpx	#'3'
		bne	@not3
		jmp	cmdSRNUKE_crctoggle
@not3:		cpx	#'4'
		bne	@not4
		jmp	cmdSRNUKE_erase_rom
@not4:		jmp	cmdSRNUKE_mainloop

cmdSRNUKE_crctoggle:
		lda	ZP_NUKE_ROMSF
		eor	#CMDROMS_FLAGS_CRC
		sta	ZP_NUKE_ROMSF
		jmp	cmdSRNUKE_mainloop

cmdSRNUKE_erase_rom:
		jsr	PrintErase
		jsr	PrintImmedT
		TOPTERM "which ROM?"
		jsr	inkey_clear
		txa
		sta	STR_NUKE_CMD			; enter the keyed number as a phoney param to cmdSRERASE
		jsr	OSASCI
		jsr	OSNEWL
		bcc	:+
		jmp	cmdSRNUKE_mainloop
:		lda	#13
		sta	STR_NUKE_CMD+1			; terminate command buffer
		lda	#<STR_NUKE_CMD
		sta	zp_mos_txtptr
		lda	#>STR_NUKE_CMD
		sta	zp_mos_txtptr+1
		ldy	#0
		jsr	cmdSRERASE
cmdSRNUKE_mainloop2:
		jmp	cmdSRNUKE_mainloop


cmdSRNUKE_flash:
		jsr	PrintErase
		jsr	PrintWhole
		jsr	PrintFlash
		jsr	PromptYN
		bne	cmdSRNUKE_mainloop2

str_NukeFl:	
		jsr	PrintErase
		jsr	PrintFlash
		jsr	PrintElip

		; erase entire flash chip
		jsr	FlashReset
		lda	#$80
		jsr	FlashCmdA
		lda	#$10
		jsr	FlashCmdAWT
		jmp	cmdSRNUKE_reboot


cmdSRNUKE_ram:	jsr	PrintErase
		jsr	PrintWhole
		jsr	PrintSRAM
		jsr	PromptYN
		beq	@s
		jmp	cmdSRNUKE_mainloop
@s:
		jsr	PrintErase
		jsr	PrintSRAM
		jsr	PrintImmedT
		TOPTERM " $7C0000-$7FFFFF"
		jsr	PrintElip

		; enable JIM, setup paging regs
		jsr	jimSetDEV_blitter

		lda	#$7C				
		sta	fred_JIM_PAGE_HI
		lda	#0	
		sta	fred_JIM_PAGE_LO

		; copy ram nuke routine to ADDR_ERRBUF and execute from there
		lda	#<cmdSRNuke_RAM
		sta	zp_tmp_ptr
		lda	#>cmdSRNuke_RAM
		sta	zp_tmp_ptr + 1
		ldy	#cmdSRNUKE_RAM_len-1
@1:		lda	(zp_tmp_ptr),Y			; copy the routine to ram buffer as we are likely to get zapped
		sta	ADDR_ERRBUF,Y
		dey
		bpl	@1
		lda	#$FF
		jmp	ADDR_ERRBUF


cmdSRNuke_RAM:
@2:		ldx	#0
@1:		sta	JIM,X
		inx
		bne	@1
		inc	fred_JIM_PAGE_LO
		bne	@2
		inc	fred_JIM_PAGE_HI
		ldx	fred_JIM_PAGE_HI
		cpx	#$80
		bne	@2
cmdSRNUKE_reboot:
		ldx	ZP_NUKE_PREVLANG
		stx	sysvar_CUR_LANG			; restore prev language

		sei
		jmp	($FFFC)				; reboot - if we're running from flash we'll crash anyway!
cmdSRNuke_RAM_end:
cmdSRNUKE_RAM_len := cmdSRNuke_RAM_end-cmdSRNuke_RAM

cmdSRNUKE_exit:
		rts




;------------------------------------------------------------------------------
; XMDUMP
;------------------------------------------------------------------------------


cmdXMdump:
	; Adapted from Source for *MDUMP by J.G.Harston

		tya
		pha

		jsr	jimSetDEV_either

		; save old jim dev
                lda     #OSBYTE_135_GET_MODE
		jsr	OSBYTE
		ldx	#$16
		tya	
                beq     @setcols
		cpy	#3
		beq	@setcols
		ldx	#8
@setcols:	pla
		tay
		stx	zp_trans_acc
                jsr     SkipSpacesPTR
		cmp	#'-'
		bne	@mdumpcols
		iny
                jsr     ParseHex
                bcs     @badcommand
@mdumpcols:	lda     zp_trans_acc
                pha                                     ; save for later as it clashes with end/acc
                jsr     SkipSpacesPTR
		cmp	#$D
		beq	@badcommand
		cmp	#'#'
		bne	@nodev
		iny	
                jsr     ParseHex                        ; get devo
		beq	@badcommand
		lda	zp_trans_acc
		sta	zp_mos_jimdevsave               ; don't worry about restoring here, CLAIMDEV has done it
		sta	fred_JIM_DEVNO
@nodev:         jsr     SkipSpacesPTR
		jsr	ParseHex
		bcc	@badcommandsk
@badcommand:	jmp	brkBadCommand
@badcommandsk:		
                ; move to start addr
                ldx     #3
@l:             lda     zp_trans_acc,X
                sta     zp_mdump_addr,X
                dex
                bpl     @l
                jsr     SkipSpacesPTR
		cmp	#'+'
		php			
                bne     @notplus1
                iny
		jsr	SkipSpacesPTR
@notplus1:	jsr	ParseHex
		plp
                bne     @mdump				; if we need to add end length is in acc/end
		clc	
		ldx	#$FC
@addlp:
		lda	zp_mdump_addr+4,X
		adc	zp_mdump_end+4,X
		sta	zp_mdump_end+4,X
		inx
		bne	@addlp
				
@mdump:		pla					; get columns back
		and	#$1F
		cmp	#$10
		bcc	@nobcd
		sbc	#6
@nobcd:		sta	zp_mdump_cols			; Columns in decimal
		
		
@loop:	
		ldx	#2
@praddr:	lda	zp_mdump_addr,X
		jsr	PrintHexA
		dex	
		bpl	@praddr
		
		ldx	#0
@loop1:		jsr	PrintSpc
		jsr	@getbyteX		
		jsr	PrintHexA
		inx	
		cpx	zp_mdump_cols
		bne	@loop1
		jsr	PrintSpc
		ldx	#0
@loop2:		jsr	@getbyteX		
		and	#127
		cmp	#32
		bcs	@pr_char
@pr_dot:	lda	#'.'
@pr_char:	cmp	#127
		beq	@pr_dot
		jsr	OSWRCH
		inx
		cpx	zp_mdump_cols
		bne	@loop2
		jsr	OSNEWL
		bit	$FF
		bmi	@escape
		
		
		ldx	#$FC
		clc	
		lda	zp_mdump_cols
@incaddr:	
		adc	zp_mdump_addr+4,X
		sta	zp_mdump_addr+4,X
		lda	#0
		inx	
		bne	@incaddr

		ldx	#$FC
@cmpaddr:
		lda	zp_mdump_addr+4,X
		eor	zp_mdump_end+4,X
		bne	@loop
		inx
		bne	@cmpaddr
		rts

@escape:	
		lda	#OSBYTE_126_ESCAPE_ACK
		jmp	OSBYTE          
		; Clear Escape and exit
		

@getbyteX:	pha
		txa
		pha
		clc
		adc	zp_mdump_addr
		tax
		lda	zp_mdump_addr+1
		adc	#0
		sta	fred_JIM_PAGE_LO
		lda	zp_mdump_addr+2
		adc	#0
		sta	fred_JIM_PAGE_HI
		lda	zp_mdump_addr+3
		adc	#0
		sta	fred_JIM_PAGE_HI2
		lda	JIM,X
		tsx
		sta	$102,X
		pla
		tax
		pla
		rts

PTRinc:
		inc	zp_mos_genPTR
		bne	@sk
		inc	zp_mos_genPTR+1
@sk:		rts


		; on entry A contains #OPENIN/#OPENOUT
		; zp_mos_txtptr,Y contains pointer to command line
		; zp_mos_txtptr,Y points at filename terminating char
		; X contains filename start

loadsavegetfn:	jsr	SkipSpacesPTR
		cmp	#' '
		bcc	badcmd

		tya
		tax				; start of filename
		
@lp:		iny
		lda	(zp_mos_txtptr),Y
		cmp	#' '+1
		bcs	@lp

		rts

badcmd:		jmp	brkBadCommand		


loadsavedev:	jsr	SkipSpacesPTR
		cmp	#'#'
		beq	@gotdev
		jmp	CheckBlitterPresentBrk
@gotdev:		iny
		jsr	ParseHex
		bcs	badcmd

		lda	zp_trans_acc		
		jmp	jimSetDEV_A

loadsavefnXY:	clc
		lda	zp_mos_txtptr
		adc	zp_trans_tmp+0
		tax
		lda	#0
		adc	zp_mos_txtptr+1
		tay
		rts



;------------------------------------------------------------------------------
; XMLOAD
;------------------------------------------------------------------------------

cmdXMLoad:	jsr	loadsavegetfn
		stx	zp_trans_tmp+0			; start of filename
		jsr	loadsavedev
		jsr	SkipSpacesPTR
		cmp	#' '
		bcc	@nostart				; end of line?
		jsr	ParseHex
		bcs	badcmd
		bcc	@start
@nostart:						; no start specified, read OSFILE info
		; make room on stack for OSFILE block
		tsx
		txa
		sec
		sbc	#16
		tax
		txs

		jsr	loadsavefnXY
		tya
		pha
		txa
		pha
		ldy	#1
		tsx
		inx					; point at block on stack
		lda	#OSFILE_CAT
		jsr	OSFILE
		cmp	#OSFILE_TYPE_FILE
		beq	@okf
		jmp	brkFileNotFound

@okf:		
		; ok, we got load address, copy to zp_trans_acc
		tsx
		ldy	#3
@lp0:		lda	$106,X
		sta	zp_trans_acc,Y
		dex
		dey
		bpl	@lp0

		; restore stack
		tsx
		txa
		clc
		adc	#18
		tax
		txs

@start:		; open the file for input
		jsr	loadsavefnXY
		lda	#OSFIND_OPENIN
		jsr	OSFIND
		cmp	#0
		bne	@ok2
		jmp	brkFileNotFound
@ok2:		
		; A contains file handle
		; zp_trans_acc contains ChipRAM address to load to
		; transfer file in 256 byte blocks using $0A00 transient buffer
		; using OSGBPB

		sta	zp_trans_tmp+0

		; allocate OSGBPB block on stack

		tsx
		txa
		sec
		sbc	#13
		tax
		txs

		jsr	ls_updjimptr			; get JIM page ready

		lda	#0
		sta	zp_trans_tmp+2			; EOF flag

@loadlp0:	lda	zp_trans_tmp+2
		bne	@load_done

		tsx

		; set up OSGBPB block
		lda	zp_trans_tmp+0
		
		; file handle
		sta	$101,X
		; load addr
		lda	#$FF
		sta	$105,X
		sta	$104,X
		lda	#$0A
		sta	$103,X
		lda	#0
		sta	$102,X				
		; count
		sta	$109,X
		sta	$108,X
		sta	$106,X
		lda	#1
		sta	$107,X

		; transfer
		lda	#OSGBPB_READ_NOPTR
		inx
		ldy	#1
		jsr	OSGBPB

		tsx
		lda	$107,X				; if this is still > 0 then nothing was transferred
		bne	@load_done

		lda	$106,X				; contains the inverse of the number of bytes to xfer
		sta	zp_trans_tmp+1
		sta	zp_trans_tmp+2			; flag whether we've had an EOF yet

		; read to end of file and poke to JIM
		ldx	zp_trans_acc			; low pointer into JIM
		ldy	#0
@loadlp:		lda	$0A00,Y
		iny
		sta	JIM,X
		inx	
		beq	@nextjimpg
@loadlp2:	inc	zp_trans_tmp+1
		bne	@loadlp
		beq	@loadlp0				; block finished

@nextjimpg:	jsr	ls_nextjim
		jmp	@loadlp2



@load_done:	lda	#OSFIND_CLOSE
		ldy	zp_trans_tmp+0			; file handle
		jsr	OSFIND				; close

		; remove OSGBPB block from stack
		tsx
		txa
		clc
		adc	#13
		tax
		txs

		rts


ls_nextjim:	inc	zp_trans_acc+1
		bne	@sk1
		inc	zp_trans_acc+2
@sk1:	

ls_updjimptr:	lda	zp_trans_acc+1
		sta	fred_JIM_PAGE_LO
		lda	zp_trans_acc+2
		sta	fred_JIM_PAGE_HI
		rts



badcmd2:		jmp	brkBadCommand		

;------------------------------------------------------------------------------
; XMSAVE
;------------------------------------------------------------------------------

cmdXMSave:	jsr	loadsavegetfn
		stx	zp_trans_tmp+0			; start of filename
		jsr	loadsavedev
		jsr	ParseHex
		bcs	badcmd2
		jsr	PushAcc				; stack the start address
		jsr	SkipSpacesPTR
		cmp	#'+'
		php					; stack + or not +
		bne	@notplus1
		iny
@notplus1:	jsr	ParseHex
		bcs	badcmd2
		plp
		beq	@isplus
		; acc contains end, turn into a length
		tsx
		sec
		lda	zp_trans_acc
		sbc	$101,X
		sta	zp_trans_acc
		lda	zp_trans_acc+1
		sbc	$102,X
		sta	zp_trans_acc+1
		lda	zp_trans_acc+2
		sbc	$103,X
		sta	zp_trans_acc+2		
@isplus:		ldx	#3
@lp1:		lda	zp_trans_acc-1,X			;Acc+0..2
		sta	zp_trans_tmp,X			;to tmp+1..3 for transfer length
		dex
		bne	@lp1

		jsr	PopAcc				; Phys address back in Accumulator
		jsr	PushAcc				; but keep it for later

@start:		; open the file for output
		jsr	loadsavefnXY
		tya
		pha
		txa
		pha					; save filename pointer for later		
		lda	#OSFIND_OPENOUT
		jsr	OSFIND
		cmp	#0
		bne	@ok2
		jmp	brkFileNotFound
@ok2:
		sta	zp_trans_tmp+0

		; allocate OSGBPB block on stack
		tsx
		txa
		sec
		sbc	#13
		tax
		txs

		jsr	ls_updjimptr			; get page registers ready


@savelp0:	ldy	#0				; number of bytes to transfer 0 means 256
		lda	zp_trans_tmp+2
		ora	zp_trans_tmp+3			; are there whole pages to do?
		bne	@wholep
		ldy	zp_trans_tmp+1
		beq	@savedone
		sta	zp_trans_tmp+1			; clear it
		sty	zp_trans_acc+3			; save number of bytes in this block
		bne	@notwholep

@wholep:		sec					; subtract 256 from length
		lda	zp_trans_tmp+2
		sbc	#1
		sta	zp_trans_tmp+2
		lda	zp_trans_tmp+3
		sbc	#0
		sta	zp_trans_tmp+3
		
@notwholep:
		; transfer ChipRAM to here
		ldy	#0
		ldx	zp_trans_acc+0
@lp0:		lda	JIM,X
		sta	$0A00,Y
		inx
		beq	@nextjimpg
@savelp2:	iny	
		cpy	zp_trans_acc+3
		bne	@lp0

		; set up OSGBPB block
		lda	zp_trans_tmp+0
		
		; file handle
		sta	$101,X
		; load addr
		lda	#$FF
		sta	$105,X
		sta	$104,X
		lda	#$0A
		sta	$103,X
		lda	#0
		sta	$102,X				
		; count
		sta	$109,X
		sta	$108,X
		sta	$107,X
		lda	zp_trans_acc+3			; count in this block		
		sta	$106,X
		bne	@nn
		inc	$107,X				; 256!
@nn:	
		lda	#OSGBPB_WRITE_NOPTR
		inx
		ldy	#1
		jsr	OSGBPB

		jmp	@savelp0



@nextjimpg:	jsr	ls_nextjim
		bne	@savelp2


@savedone:	lda	#OSFIND_CLOSE
		ldy	zp_trans_tmp+0			; file handle
		jsr	OSFIND				; close


		; copy filename and load address to OSFILE block
		ldy	#6
		tsx
@lp:		lda	$10E,X
		sta	$101,X
		inx
		dey
		bne	@lp

		ldy	#1
		tsx
		inx
		lda	#OSFILE_SET_LOAD
		jsr	OSFILE


		; remove OSGBPB, filename pointer and ack from stack
		tsx
		txa
		clc
		adc	#19
		tax
		txs


		rts

throttleInit:
		jsr	cfgGetAPISubLevel_1_2
		bcc	@nothardres

		lda	#OSBYTE_253_VAR_LAST_RESET
		ldx	#0
		ldy	#$FF
		jsr	OSBYTE
		cpx	#1
		bcc	@nothardres


		ldx	#BLTUTIL_CMOS_FW_ROM_THROT
		jsr	CMOS_ReadFirmX			; get from CMOS 11x0,Y
		eor	#$FF
		sta	sheila_ROM_THROTTLE_0
		ldx	#BLTUTIL_CMOS_FW_ROM_THROT+1
		jsr	CMOS_ReadFirmX			; get from CMOS 11x1,Y
		eor	#$FF
		sta	sheila_ROM_THROTTLE_1


		; load CPU throttle from CMOS
	.assert BLTUTIL_CMOS_FW_THROT_BIT_CPU = $7, error, "Code assumes bit 7"
	.assert BITS_MEM_TURBO2_THROTTLE = $80, error, "Code assumes bit 7"

		ldx	#BLTUTIL_CMOS_FW_THROT
		jsr	CMOS_ReadFirmX			; get from CMOS
		and	#$80 
		rol	A
		php
		lda	sheila_MEM_TURBO2
		rol	A
		plp
		ror	A
		sta	sheila_MEM_TURBO2

		; TODO: MOS Turbo/Throttle

@nothardres:	rts

;------------------------------------------------------------------------------
; Strings and tables
;------------------------------------------------------------------------------

PrintErase:	jsr	PrintImmedT
		TOPTERM "Erase "
		rts
PrintWhole:	jsr	PrintImmedT
		TOPTERM "whole "
		rts
PrintFlash:	jsr	PrintImmedT
		TOPTERM "Flash"
		rts
PrintSRAM:	jsr	PrintImmedT
		TOPTERM "SRAM"
		rts
PrintAt:	jsr	PrintImmedT
		TOPTERM " at "
		rts
PrintElip:	jsr	PrintImmedT
		.byte	"..."
		.byte	13|$80
		rts
PrintOK:	jsr	PrintImmedT
		.byte	13, "OK."
		.byte	13|$80
		rts


		.SEGMENT "RODATA"



;X;	strSRCOPY2RAM:		.byte	"Copying to SROM/SRAM at ",0
;X;	strSRCOPY2FLASH:	.byte	"Copying to Flash at ",0


;X;	str_Copying:		.byte	"Copying...", 0
	


