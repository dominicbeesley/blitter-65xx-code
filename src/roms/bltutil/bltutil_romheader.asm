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

		.include "version-date.inc"

		.export	Copyright
		.export strCmdBLTurbo
		.export ServiceOut
		.export ServiceOutA0
		.export ServiceOutA0retY
		.export str_Dossy

		.SEGMENT "CODE_ROMHEADER"


; this contains the rom header and service routines and help/strings

MY_ROM_TYPE	= $82

code_base:		

;		ORG	$8000

		.byte	0,0,0				; language entry
		jmp	Service				; service entry
		.byte	MY_ROM_TYPE			; not a language, 6502 code
		.byte	Copyright-code_base
		VERSION_BYTE	
utils_name:
		VERSION_NAME
	.ifdef MACH_ELK
		.byte " ELK"
	.endif 
		.byte	0
		VERSION_STRING
		.byte	" ("
		VERSION_DATE
		.byte	")"
Copyright:
		.byte	0
		.byte	"(C)2024 "
str_Dossy:	.byte   "Dossytronics"
		.byte	0

		.CODE

;* ---------------- 
;* SERVICE ROUTINES
;* ----------------
	;TODO make this relative!
Serv_jump_table:
		SJTE	SERVICE_1_ABSWKSP_REQ, 	svc1_ClaimAbs
		SJTE	SERVICE_4_UKCMD, 	svc4_COMMAND
		SJTE	SERVICE_5_UKINT,	svc5_UKIRQ
		SJTE	SERVICE_7_UKOSBYTE,	svc7_OSBYTE
		SJTE	SERVICE_8_UKOSWORD,	svc8_OSWORD
		SJTE	SERVICE_9_HELP,		svc9_HELP
		SJTE	SERVICE_28_CONFIGURE, 	svc28_CONFIG
		SJTE	SERVICE_29_STATUS, 	svc29_STATUS
		SJTE	SERVICE_FE_TUBEINIT, 	svcFE_TubeInit
Serv_jump_table_Len	:= 	* - Serv_jump_table	

svcFE_TubeInit:
		pha
		jsr	CheckBlitterPresent
		bcs	@s
		jsr      cfgGetAPISubLevel_1_3
		bcc	@s
		jsr	cfgMasterMOS
		bcs	@s
		jsr	autohazel_boot_second
@s:		jmp	plaServiceOut


Service:
		CLAIMDEV
		; preserve Y,A (X can be determined from &F4)		
		pha
		tax
		tya
		pha
		txa

		; skip disabled check for svc=1
		cmp	#1
		beq	srv_ok2

		; check to see if this rom is disabled
		pha
		ldx	zp_mos_curROM
		lda	swrom_wksp_tab,X
		bpl	srv_ok
		bvc	plaServiceOut			; top bit set and not second - exit
srv_ok:		pla
srv_ok2:

		ldx	#0
@1:		cmp	Serv_jump_table,X
		beq	ServMatch
		inx
		inx
		inx		
		cpx	#Serv_jump_table_Len
		bcc	@1
		bcs	ServiceOut
ServMatch:	inx
		lda	Serv_jump_table,X
		pha
		inx
		lda	Serv_jump_table,X
		pha
		rts					; jump to service routine

plaServiceOut:	pla
ServiceOut:	ldx	zp_mos_curROM
		pla
		tay
		pla					; pass to other service routines
		rts
ServiceOutA0:	ldx	zp_mos_curROM
		pla
		tay
		pla
		lda	#0				; Don't pass to other service routines
		rts
ServiceOutA0retY:
		ldx	zp_mos_curROM
		pla
		; don't restore Y!
		pla
		lda	#0				; Don't pass to other service routines
		rts
; -------------------------------
; SERVICE 1 - Claim Abs Workspace
; -------------------------------
; - We don't need abs workspace but we do want to check for £ key to enter
;   SRNUKE and do other setup of auto hazel etc

svc1_ClaimAbs: 
		; check to see if we are current language and put back 
		; original
		lda	sysvar_CUR_LANG
		cmp	zp_mos_curROM
		bne	@s
		lda	ZP_NUKE_PREVLANG
		sta	sysvar_CUR_LANG
@s:

		; check for another BLTUTIL rom in higher slot and self-disable if there is one
		; mainly to stop annoying messages

		lda	#0
		ldy	zp_mos_curROM
		sta	swrom_wksp_tab,Y		; set ourselves to enabled (in case of just unplugged / erased BLTUTIL in higher slot)
		cpy	#15
		bcs	@rok
		iny
@rlp:		lda	oswksp_ROMTYPE_TAB,Y
		cmp	#MY_ROM_TYPE
		bne	@rnxt
		tya
		pha				; preserve other ROM #

		; get pointer to ROM title
		lda	#$09
		sta	zp_mos_genPTR
		lda	#$80
		sta	zp_mos_genPTR+1

@cmplp:		pla
		pha
		tay				; ROM number of other ROM
		jsr	OSRDRM

		ldy	#0
		cmp	(zp_mos_genPTR),Y
		bne	@rnxt2
		cmp	#0
		beq	@mat

		inc	zp_mos_genPTR
		bne	@cmplp
		beq	@rnxt2

@mat:		; we have a match disable ourself
		pla				
		ora	#$80			; save number of other rom ore'd with $80 to self-disable
		ldy	zp_mos_curROM
		sta	swrom_wksp_tab,Y
		jmp	ServiceOut
		
		
@rnxt2:		pla
		tay
@rnxt:		iny
		cpy	#16
		bne	@rlp


@rok:
		jsr	CheckBlitterPresent
		bcs	@s2

		jsr      cfgGetAPISubLevel_1_3
		bcc	@sh
		; do autohazel for lower priority roms
		jsr	cfgMasterMOS
		bcs	@sh
		jsr	autohazel_boot_first
		@sh:


		; belt and braces write $f0 to flash to clear soft id mode
		jsr	FlashReset_Q

		; detect NoICE and check we're in ROM#F
		lda	zp_mos_curROM
		cmp	#$0F
		bne	@notromf
		; this assumes if bit 3 of FE32 is set we want NoIce
		lda	#BITS_MEM_CTL_SWMOS_DEBUG_EN
		bit	sheila_MEM_CTL
		beq	@notromf

		jsr	noice_init
@notromf:

		lda	#$79
		ldy	#0
		ldx	#$A8
		jsr	OSBYTE				; check if _/£ key down
		txa
		bpl	@s2
		jsr	cmdSRNUKE_lang
		jmp	cmdSRNUKE_reboot
@s2:		
		jsr	throttleInit
		jsr	cfgPrintVersionBoot
		bcs	@nope

		; work out memory size (depends on board type)
		; get BB RAM size (assume starts at bank 60 and is at most 20 banks long)		
		jsr	zeroAcc				; zero the maths accumulator
		ldx	#$60
		ldy	#$00
		jsr	cfgMemCheckAlias
		bcc	@noBB				;skip forwards if no writeable at 60
		beq	@noBB				;if eq then 60 is aliased at 0
@BBRAM_test:	
		ldy	#$80				; limit
		jsr	cfgMemSize
		sta	zp_trans_acc+2
@noBB:
@BBChipram:	ldx	#0
		ldy	#$60
		jsr	cfgMemSize
		pha					; save # of banks for heap_init
		clc
		adc	zp_trans_acc+2
		sta	zp_trans_acc+2

		jsr	PrintSpc
		jsr	PrintSizeK

		; if this is Mk.2 board knock off room for ROM (4 banks)
		jsr	cfgGetAPILevel
		bcs	@s1			; no blitter continue
		beq	@ismk2			; API 0 - assume mk.2 (old board) TODO: deprecated, remove?
		lda	JIM+jim_offs_VERSION_Board_level
		cmp	#2
		bne	@s1			; not mk.2
@ismk2:		pla
		sec
		sbc	#4			; mk.2 clear way for BB roms
		pha
@s1:		pla
		jsr	heap_init
		jsr	sound_boot
		jsr	PrintNL

@nope:		jmp	ServiceOut

; on entry (zp_mos_txtptr),Y is start of keys to match
; zp_mos_genPTR is 0 terminated string to match
; returns Cy=1 if any key matches
; Y preserved
; X, A corrupted

keyMatch:	tya
		pha
		sty	zp_trans_tmp
@nextcmd:	ldx	#$FF			; pointer into candidate key		
		stx	zp_trans_tmp+1
@l1:		inc	zp_trans_tmp+1		
		ldy	zp_trans_tmp
		lda	(zp_mos_txtptr), Y	; get char
		inc	zp_trans_tmp
		ldy	zp_trans_tmp+1
		cmp	(zp_mos_genPTR),Y		
		beq	@l1
		cmp	#'.'
		beq	@match
		cmp	#' '+1
		bcc	@keyend2		; ' ' or lower but was that the end of the key
		ldy	zp_trans_tmp
@3:		lda	(zp_mos_txtptr),Y		; not at end skip forwards to next space or lower
		iny
		cmp	#' '+1
		bcs	@3
		dey					; move back one to point at space or lower
		jsr	SkipSpacesPTR
		sty	zp_trans_tmp
		cmp	#$D				
		bne	@keyend
@nomatch:	pla
		tay
		clc
		rts

@keyend2:	dec	zp_trans_tmp		; decrement back on command tail
@keyend:	ldy	zp_trans_tmp+1
		lda	(zp_mos_genPTR),Y
		beq	@match			; end of key so it's a match!
		ldy	zp_trans_tmp
		jsr	SkipSpacesPTR
		cmp	#' '
		bcc	@nomatch
		bcs	@nextcmd

@match:		pla
		tay
		sec
		rts

svc9_helptable:	
		txa
		pha
		ldx	zp_tmp_ptr
		ldy	zp_tmp_ptr+1
		jsr	PrintXY
		jsr	PrintNL
		pla
		tax
@lp:
		ldy	tbl_commands+1,X		; get hi byte of string
		beq	@rts				; if zero at end of table
		jsr	PrintSpc
		jsr	PrintSpc
		txa
		pha
		lda	tbl_commands,X			; lo byte
		tax
		jsr	PrintXY
		jsr	PrintSpc
		pla
		clc
		adc	#4
		tax
		ldy	tbl_commands+1,X		; hi byte of args string
		beq	@sk3
		pha
		lda	tbl_commands,X
		tax
		jsr	PrintXY
		pla
		tax
@sk3:		jsr	PrintNL
		inx
		inx
		bne	@lp
@rts:		rts

; -----------------
; SERVICE 9 - *Help
; -----------------
; help string is at (&F2),Y
svc9_HELP:
		jsr	SkipSpacesPTR
		cmp	#$D
		beq	svc9_HELP_nokey

		lda	#<strHELPKEY_BLTUTIL
		sta	zp_mos_genPTR
		lda	#>strHELPKEY_BLTUTIL
		sta	zp_mos_genPTR+1
		jsr	keyMatch
		bcc	@s		
		; got a match, dump out our commands help
		ldx	#0
		lda	zp_mos_jimdevsave
		cmp	#JIM_DEVNO_HOG1MPAULA
		bne	@1
		ldx	#tbl_commands_PAULA-tbl_commands
@1:		cmp	#JIM_DEVNO_BLITTER
		beq	@2
		ldx	#tbl_commands_General-tbl_commands
@2:
		jsr	svc9_helptable
@s:
		; if not a Master show our MOS replacement commands
		jsr	cfgMasterMOS
		bcs	@s2
		jsr	CheckBlitterPresent
		bcs	@s2

		lda	#<strHELPKEY_MOS
		sta	zp_mos_genPTR
		lda	#>strHELPKEY_MOS
		sta	zp_mos_genPTR+1
		jsr	keyMatch
		bcc	@s2
		ldx	#tbl_commands_MOS-tbl_commands
		jsr	svc9_helptable		
@s2:

		jmp	svc9_HELP_exit

svc9_HELP_nokey:
		jsr	svc9_HELP_showbanner
		jsr	svc9_HELP_showkeys
svc9_HELP_exit:	jmp	ServiceOut

Print129:	lda	#129
		bne	PP
Print130:	lda	#130
PP:		jsr	PrintA
		lda	#'('
		jmp	PrintA
Print130Blitter:jsr	Print130
PrintBlitter:	jsr	PrintImmedT
		TOPTERM "Blitter"
		rts
PrintPaula:	jsr	PrintImmedT
		TOPTERM "1M Paula"
		rts

svc9_HELP_showbanner:
		jsr	PrintNL
		ldx	#<utils_name
		ldy	#>utils_name			; point at name, version, copyright strings
		lda	#2
		sta	zp_trans_tmp
@1:		jsr	PrintXY
		jsr	PrintSpc
		dec	zp_trans_tmp
		bne	@1
		jsr	PrintNL

		jsr	CheckBlitterPresent
		bcc	@skp
		jsr	CheckPaulaPresent
		bcs	@skp_notp

		jsr	Print130
		jsr	PrintPaula
		jmp	@skp2

@skp_notp:	jsr	Print129
		jsr	PrintBlitter
		lda	#'/'
		jsr	PrintA
		jsr	PrintPaula
		jsr	PrintImmedT
		TOPTERM " not"
		jmp	@skp2

@skp:
		jsr	Print130Blitter
@skp2:		jsr	PrintImmedT
		TOPTERM	" present)"
		rts

svc9_HELP_showkeys:
		jsr	PrintNL
		jsr	Print2Spc
		ldx	#<strHELPKEY_BLTUTIL
		ldy	#>strHELPKEY_BLTUTIL
		jsr	PrintXY
		jsr	cfgMasterMOS
		bcs	@s
		jsr	CheckBlitterPresent
		bcs	@s
		jsr	PrintImmedT
		.byte	13
		TOPTERM	"  MOS"
@s:		jmp	PrintNL


; --------------------
; SERVICE 4 - *COMMAND
; --------------------

svc4_COMMAND:	; scan command table for commands


		lda	#<tbl_commands
		sta	zp_mos_genPTR
		lda	#>tbl_commands
		sta	zp_mos_genPTR + 1
		lda	zp_mos_jimdevsave
		cmp	#JIM_DEVNO_HOG1MPAULA
		bne	@s1
		lda	#<tbl_commands_PAULA
		sta	zp_mos_genPTR
		lda	#>tbl_commands_PAULA
		sta	zp_mos_genPTR + 1

@s1:		jsr	searchCMDTabExec

		jsr	cfgMasterMOS
		bcs	svc4_CMD_exit
		jsr	CheckBlitterPresent
		bcs	svc4_CMD_exit

		lda	#<tbl_commands_MOS
		sta	zp_mos_genPTR
		lda	#>tbl_commands_MOS
		sta	zp_mos_genPTR+1
		jsr	searchCMDTabExec


svc4_CMD_exit:	jmp	ServiceOut



searchCMDTabExec:
		jsr	searchCMDTab
		bvc	anRTS

cmdTabExecPlaPla:
		; discard return address -- we're not going to return
		pla
		pla

cmdTabExec:	php
		pla
		tax					; preserve flags
		; push address of ServiceOutA0 to stack for return
		lda	#>(ServiceOutA0-1)
		pha
		lda	#<(ServiceOutA0-1)
		pha
		sty	zp_trans_tmp			; command tail save
		; push address of Command Routine to stack for rts
		ldy	#3
		lda	(zp_mos_genPTR),Y
		pha
		dey
		lda	(zp_mos_genPTR),Y
		pha
		ldy	zp_trans_tmp
		txa
		pha
		plp					; flags as passed in
		rts					; execute command

anRTS:		rts


; search the command table at zp_mos_genPTR for match to string at (zp_mos_genPTR)
; return Cy=1 for match:
;	 zp_mos_genPTR points at entry
;	 Y points at tail
;   else Cy=0
;	 Y points at command start


searchCMDTab:
		php					; save flags on entry (config/status pass through Cy)		
		tya
		pha					; save begining of command pointer

@cmd_loop:	pla
		pha
		tay					; restore zp_mos_txtptr and Y from stack
		jsr	SkipSpacesPTR
		sty	zp_trans_tmp + 1		; we have to subtract the start Y from the string pointer!
		ldy	#0
		sec
		lda	(zp_mos_genPTR),Y
		sbc	zp_trans_tmp + 1
		sta	zp_trans_tmp
		iny
		lda	(zp_mos_genPTR),Y		
		beq	@r				; no more commands
		sbc	#0
		ldy	zp_trans_tmp+1			; get back Y
		sta	zp_trans_tmp+1			; point to command name - Y
		dey
@cmd_match_lp:	iny
		lda	(zp_mos_txtptr),Y
		jsr	ToUpper
		sta	zp_trans_tmp+2
		lda	(zp_trans_tmp),Y
		jsr	ToUpper
		eor	zp_trans_tmp+2
		beq	@cmd_match_lp
		lda	(zp_mos_txtptr),Y
		cmp	#'.'
		beq	@cmd_match2_sk
		lda	(zp_trans_tmp),Y		; command name finished
		beq	@cmd_match_sk
@cmd_match_nxt:	lda	zp_mos_genPTR
		clc
		adc	#6
		sta	zp_mos_genPTR
		bcc	@cmd_loop			; try next table entry
		inc	zp_mos_genPTR+1
		bne	@cmd_loop

@cmd_match_sk:	lda	(zp_mos_txtptr),Y
		cmp	#' '+1
		bcs	@cmd_match_nxt		
		dey
@cmd_match2_sk:	iny
		pla					; discard stacked Y
		plp
		bit	bitSEV				; indicate pass
		rts
@r:		pla					
		tay
		plp
		clv					; indicate fail
		rts


; --------------------
; SERVICE 5 - UkIRQ
; --------------------
		; svc5_UKIRQ is used to intercept unrecognised interrupts

svc5_UKIRQ:
		; check to see if this is a sound tick
		lda	sheila_USRVIA_ifr
		and	#VIA_IFR_BIT_T1
		beq	@exit
		jmp	sound_irq		

@exit:		jmp	ServiceOut


; --------------------
; SERVICE 7 - OSBYTE
; --------------------

svc7_OSBYTE:
		jsr	CheckBlitterPresent
		bcs	noCMOShere
		lda	zp_mos_OSBW_A
		cmp	#OSBYTE_161_READ_CMOS
		beq	dMOS_OSBYTE_161_READ_CMOS
		cmp	#OSBYTE_162_WRITE_CMOS
		beq	dMOS_OSBYTE_162_WRITE_CMOS
		

noCMOShere:
		jmp	ServiceOut

dMOS_OSBYTE_161_READ_CMOS:
		; TODO: this assumes all Blitters have CMOS RAM/i2c - TODO: checks throughout? (safe for all Mk.2/3 built so far)
		ldy	zp_mos_OSBW_Y
		ldx	zp_mos_OSBW_X
		cpx	#$FF
		beq	@size

		cpx	#$80
		txa
		pha
		bcs	noCMOShere		; >= $80 - pass on
		jsr	CMOS_ReadMosX
		tay
		pla
		tax
@out:		
		; we need to restore all these as OSWORD may have goosed them
		stx	zp_mos_OSBW_X
		sty	zp_mos_OSBW_Y
		lda	#OSBYTE_161_READ_CMOS
		sta	zp_mos_OSBW_A
		jmp	ServiceOutA0retY


@size:		ldy	#$7F		
		bne	@out

dMOS_OSBYTE_162_WRITE_CMOS:
		ldx	zp_mos_OSBW_X
		cpx	#$80
		txa
		pha
		bcs	noCMOShere		; >= $80 - pass on
		lda	zp_mos_OSBW_Y
		jsr	CMOS_WriteMosX
		pla
		tax
		stx	zp_mos_OSBW_X
		jmp	ServiceOutA0


; --------------------
; SERVICE 8 - OSWORD
; --------------------

svc8_OSWORD:
		lda	zp_mos_OSBW_A
		cmp	#OSWORD_BLTUTIL		
		beq     oswordHandle
		cmp	#OSWORD_SOUND
		bne	@out
		jmp	sound_OSWORD_SOUND
@out:		jmp	ServiceOut
oswordHandle:	jmp	heap_OSWORD_bltutil



		.SEGMENT "RODATA"


tbl_commands:		.word	strCmdRoms, cmdRoms-1, helpRoms
			.word	strCmdSRCOPY, cmdSRCOPY-1, strHelpSRCOPY
			.word	strCmdSRERASE, cmdSRERASE-1, strHelpSRERASE
			.word	strCmdSRNUKE, cmdSRNUKE-1, 0
			.word	strCmdSRLOAD, cmdSRLOAD-1, strHelpSRLOAD
			.word	strCmdBLTurbo, cmdBLTurbo-1, strHelpBLTurbo
			.word	strCmdNOICE, cmdNoIce-1, strHelpNoIce
			.word	strCmdNOICE_BRK, cmdNoIce_BRK-1, strHelpNoIce_BRK
tbl_commands_PAULA:
			.word	strCmdSound, cmdSound-1, strHelpSound	
			.word	strCmdSoundSamLoad, cmdSoundSamLoad-1, strHelpSoundSamLoad
			.word	strCmdSoundSamClear, cmdSoundSamClear-1, strHelpSoundSamClear	
			.word	strCmdHeapInfo, cmdHeapInfo-1, strHelpHeapInfo	
			.word	strCmdSoundSamMap, cmdSoundSamMap-1, strHelpSoundSamMap
			.word	strCmdBLInfo, cmdInfo-1, 0
tbl_commands_General:
			.word	strCmdXMLOAD, cmdXMLoad-1, strHelpXMLoad
			.word	strCmdXMSAVE, cmdXMSave-1, strHelpXMSave
			.word	strCmdXMDUMP, cmdXMdump-1, strHelpXMdump
			.word	0

	; Master/MOS substitute commands
tbl_commands_MOS:	.word	strCmdCONFIG, cmdCONFIG-1, strHelpCONFIG
			.word	strCmdSTATUS, cmdSTATUS-1, strHelpSTATUS
			.word	0

strHELPKEY_BLTUTIL:	.byte	"BLTUTIL",0
strHELPKEY_MOS:		.byte	"MOS",0

strCmdRoms:		.byte	"ROMS", 0
helpRoms:		.byte	"[V][A][C][I][X|0|1]", 0
strCmdSRCOPY:		.byte	"SRCOPY",0
strHelpSRCOPY:		.byte	"<dest id> <src id>",0
strCmdSRNUKE:		.byte	"SRNUKE",0
strCmdSRERASE:		.byte	"SRERASE",0
strHelpSRERASE:		.byte	"<dest id> [F][I][X|0|1]",0
strCmdSRLOAD:		.byte	"SRLOAD", 0
strHelpSRLOAD:		.byte	"<filename> <id> [I][X|0|1]",0
strCmdXMDUMP:		.byte	"XMDUMP",0
strHelpXMdump:		.byte	"[-8|16] [#<dev>] <start> <end>|+<len>",0
strCmdNOICE:		.byte	"NOICE",0
strHelpNoIce:		.byte	"[ON|OFF]",0
strCmdNOICE_BRK:	.byte	"NOICEBRK",0
strHelpNoIce_BRK:	.byte	0
strCmdBLTurbo:		.byte	"BLTURBO",0
strHelpBLTurbo:		.byte	"[M[-]] [L<pagemask>] [R<n>[-]] [T[-]] [?]",0
strCmdSound:		.byte	"BLSOUND", 0
strHelpSound:		.byte	"[ON|OFF|DETUNE]", 0
strCmdHeapInfo:		.byte	"BLHINF",0
strHelpHeapInfo:		.byte	"[V]",0
strCmdSoundSamLoad:	.byte	"BLSAMLD",0
strHelpSoundSamLoad:	.byte	"<filename> <SN> [reploffs]",0
strCmdSoundSamMap:	.byte	"BLSAMMAP",0
strHelpSoundSamMap:	.byte	"<CH> <SN>",0
strCmdSoundSamClear:	.byte	"BLSAMCLR",0
strHelpSoundSamClear:	.byte	"[SN|*]",0
strCmdBLInfo:		.byte	"BLINFO",0
strCmdXMLOAD:		.byte	"XMLOAD",0
strHelpXMLoad:		.byte	"<file> [#dev] [<start>]",0
strCmdXMSAVE:		.byte	"XMSAVE",0
strHelpXMSave:		.byte	"<file> [#dev] <start> <end>|+<len>",0

strCmdCONFIG:		.byte	"CONFIGURE", 0
strHelpCONFIG:		.byte	0
strCmdSTATUS:		.byte	"STATUS", 0
strHelpSTATUS:		.byte	0

	.macro ConfYN Name, Func, Flip, Bit, Offs
		.word	Name
		.word	Func-1
		.word	$4000 + ($0800*(Flip && 1)) + ($0100*(Bit & 7)) + (Offs & $7F)
	.endmacro

	.macro Conf	Name, Func, Help
		.word	Name
		.word	Func-1
		.word	Help
	.endmacro



; these are scanned if we're replacing non-master MOS
tbl_configs_MOS:	Conf	strDot,			confHelp, 		0		
			ConfYN	strTube,		confYN,			0,	0,	$F
			Conf	strTV,			confTV,			confHelpDD
			.word	0
; these are always scanned
tbl_configs_BLTUTIL:	Conf	strDot,			confBLHelp, 		0		
			ConfYN	strBLThrottle,		confYN,			1,	BLTUTIL_CMOS_FW_THROT_BIT_CPU, BLTUTIL_CMOS_FW_THROT
			ConfYN	strBLThrottleMOS,	confYN,			1,	BLTUTIL_CMOS_FW_THROT_BIT_MOS, BLTUTIL_CMOS_FW_THROT
			Conf	strBLThrottleROMS,	confBLThrottleROMS,	confHelpBLThrottleROMS
			.word	0


strDot:			.byte	".",0
strTV:			.byte	"TV",0
strTube:		.byte	"Tube",0
strBLThrottle:		.byte	"BLThrottle",0
strBLThrottleMOS:	.byte	"BLThrottleMOS",0
strBLThrottleROMS:	.byte	"BLThrottleROMS",0

confHelpBLThrottleROMS:	.byte	"[+|-<D>[,...]]",0

confHelpDD:		.byte	"[<D>[,<D>]]",0

		.code
		; TODO: move to another files (move commands table parse too?)



confBLHelp:	lda	#<(tbl_configs_BLTUTIL+6)
		sta	zp_mos_genPTR
		lda	#>(tbl_configs_BLTUTIL+6)
		sta	zp_mos_genPTR+1
		bcc	@s
		jmp	statBLHelp
@s:		jsr	ShowConfsHelpTable
		; we need to pass on to other roms, we were entered with ServiceOutA0 pushed.
		; pop it and jump to serviceOut
		pla
		jmp	plaServiceOut

statBLHelp:	jsr	ShowStatsHelpTableBLT
		; we need to pass on to other roms, we were entered with ServiceOutA0 pushed.
		; pop it and jump to serviceOut
		pla
		jmp	plaServiceOut


confHelp:	bcc	@s
		jmp	statHelp
@s:		jsr	PrintImmedT
		.byte 	"Config. options:"
		.byte	13|$80
		; scan through table and print options, skipping first option which is "."
		lda	#<(tbl_configs_MOS+6)
		sta	zp_mos_genPTR
		lda	#>(tbl_configs_MOS+6)
		sta	zp_mos_genPTR+1
	
		tya				; preserve text pointer (for later pass on to ROMs)
		pha
		jsr	ShowConfsHelpTable	; show the help table
		pla
		tay
		lda	#OSBYTE_143_SERVICE_CALL
		ldx	#SERVICE_28_CONFIGURE
		jsr	OSBYTE			; pass on to ROMS

		jsr	PrintImmedT
                .byte 	"Where:",13
                .byte 	"D is a decimal number, or",13
                .byte 	"a hexadecimal number preceded by &",13
                .byte	"Items within [ ] are optional"
		.byte	13|$80              
		rts


ShowConfsHelpTable:
@lp:
		ldy	#0
		lda	(zp_mos_genPTR),Y
		beq	@done
		
		ldy	#5
		lda	(zp_mos_genPTR),Y
		and	#$40
		beq	@nono

		ldy	#0
		jsr	PrintAtPtrgenPtrY
		jsr	PrintNL
		jsr	PrintNo
		ldy	#0
		jsr	PrintAtPtrgenPtrY
		jmp	@nextNL
@nono:		ldy	#0
		jsr	PrintAtPtrgenPtrY16
		ldy	#4
		jsr	PrintAtPtrgenPtrY		; print help

@nextNL:	jsr	PrintNL
@next:
		clc
		lda	zp_mos_genPTR
		adc	#6
		sta	zp_mos_genPTR
		bcc	@lp
		inc	zp_mos_genPTR+1
		bne	@lp
@done:		rts

ShowStatsHelpTableBLT:
		bit	bitSEV
		jmp	ShowStatsHelpTableInt
ShowStatsHelpTableMOS:
		clv
ShowStatsHelpTableInt:
		php
@lp:
		ldy	#0
		lda	(zp_mos_genPTR),Y
		beq	@done

		ldy	#5
		lda	(zp_mos_genPTR),Y
		and	#$40
		bne	@nolbl			; skip if a YN statYN will print this if set
		ldy	#0
		jsr	PrintAtPtrgenPtrY16	

@nolbl:
		plp
		php				; get back V flag passed in
		lda	#>(@next-1)
		pha
		lda	#<(@next-1)
		pha				; return to @nextNL
		ldy	#3
		lda	(zp_mos_genPTR),Y
		pha
		dey
		lda	(zp_mos_genPTR),Y	; push routine address
		pha
		sec				; indicate status
		rts				; call pushed routine

@next:
		ldy	#5
		lda	(zp_mos_genPTR),Y
		and	#$40
		bne	@nonl			; skip if a YN statYN will print this if set
		jsr	PrintNL
@nonl:

		clc
		lda	zp_mos_genPTR
		adc	#6
		sta	zp_mos_genPTR
		bcc	@lp
		inc	zp_mos_genPTR+1
		bne	@lp
@done:		plp
		rts

statHelp:	jsr	PrintImmedT
		.byte	"Configuration Status:"
		.byte	13|$80

		lda	#<(tbl_configs_MOS+6)
		sta	zp_mos_genPTR
		lda	#>(tbl_configs_MOS+6)
		sta	zp_mos_genPTR+1
	
		tya				; preserve text pointer (for later pass on to ROMs)
		pha

		jsr	ShowStatsHelpTableMOS

		pla
		tay
		lda	#OSBYTE_143_SERVICE_CALL
		ldx	#SERVICE_29_STATUS
		jsr	OSBYTE			; pass on to ROMS
		rts

confTV:		bcs	statTV
		jsr	PrintImmedT
		TOPTERM	"CONF TV"
		rts
statTV:		jsr	PushAcc			; we're about to use acc which crashes pointers

		ldx	#10
		jsr	CMOS_ReadMosX
		ror	A
		ror	A
		ror	A
		ror	A
		pha
		ror	A
		and	#3
		jsr	PrintDecA
		jsr	PrintComma
		pla
		and	#1
		jsr	PrintDecA
		jsr	PopAcc
		rts

confYN:		bcs	statYN

		
		jsr PrintImmedT
		TOPTERM "CONFYN"

		rts

statYN:		php
		ldy	#5
		lda	(zp_mos_genPTR),Y
		ldx	#0
		and	#$8
		beq	@nonono
		dex				; bit 7=1 causes X=0, bit 7=0 causes X=$FF
@nonono:	stx	zp_trans_tmp		; store flip mask, used to swap senses of bit
		lda	(zp_mos_genPTR),Y
		and	#$7			; the bit position used to store the config
		
		jsr	MaskBitA

		sta	zp_trans_tmp+1		; store mask
		
		ldy	#4
		lda	(zp_mos_genPTR),Y		; get index in CMOS
		tax
		plp
		php
		bvs	@blt
		jsr	CMOS_ReadMosX
		jmp	@nob
@blt:		jsr	CMOS_ReadFirmX
@nob:		eor	zp_trans_tmp
		and	zp_trans_tmp+1
		bne	@nono
		jsr	PrintNo
@nono:		ldy	#0
		jsr	PrintAtPtrgenPtrY
		jsr	PrintNL

		plp
		rts

confBLThrottleROMS:
		bcs	statBLThrottleROMS
		jsr	PrintImmedT
		TOPTERM	"CONF BL ROMS"
		rts
statBLThrottleROMS:
		jsr	PrintImmedT
		TOPTERM	"STAT BL ROMS"
		rts


	; We enter here if the *STATUS command is executed and we are a MOS substitute
cmdSTATUS:	sec
		bcs	doConfStat
cmdCONFIG:	clc					; this will come through in findCMOS result
doConfStat:	jsr	findConfigMOS			; look for the item in the MOS table
		bvs	clvjcmdexecpp			; matched skip forward
		lda	#SERVICE_28_CONFIGURE>>1
		rol	A
		tax					; set to 28/29 depending on carry
		lda	#OSBYTE_143_SERVICE_CALL
		jsr	OSBYTE				; if not found pass round ROMs (including our own)
		cpx	#0
		beq	@ok
		jmp	brkBadCommand
@ok:		rts
		
		; found in table, execute from table
clvjcmdexecpp:
		clv					; clear V - indicate to handlers that we are
							; doing MOS stuff (as opposed to blitter area of CMOS)
jcmdexecpp:	jmp	cmdTabExecPlaPla
jcmdexec:	jmp	cmdTabExec

svc28_CONFIG:	clc
		bcc	svc28x
svc29_STATUS:	sec
svc28x:		jsr	findConfigBL
		bvs	jcmdexec
		jmp	ServiceOut			; pass on to other handlers


.scope
::findConfigBL:
		php
		lda	#<tbl_configs_BLTUTIL
		sta	zp_mos_genPTR
		lda	#>tbl_configs_BLTUTIL
		sta	zp_mos_genPTR+1	
		bne	e2
dotagain:
		iny
		plp
::findConfigMOS:	
		php
		lda	#<tbl_configs_MOS
		sta	zp_mos_genPTR
		lda	#>tbl_configs_MOS
		sta	zp_mos_genPTR+1

e2:		jsr	SkipSpacesPTR
		cmp	#'.'
		beq	dotagain
		cmp	#$D
		beq	empty

		jsr	ToUpper
		cmp	#'N'
		bne	@nono
		iny
		lda	(zp_mos_txtptr),Y
		jsr	ToUpper
		cmp	#'O'
		bne	@nono
		iny
		plp
		lda	#$FF				; set Z=0, S=1
		bne	@noyes
@nono:		plp
@noyes:		jmp	searchCMDTab
		;
empty:		plp
		lda	#0				; set Z=1, S=0
		bit	bitSEV				; indicate found (first entry!)
::bitSEV:	rts
.endscope
		



