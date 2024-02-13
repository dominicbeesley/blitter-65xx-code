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
		.include "bltutil_utils.inc"
		.include "bltutil_jimstuff.inc"
		.include "bltutil_noice.inc"
		.include "bltutil_flashutils.inc"
		.include "bltutil_sound.inc"
		.include "bltutil_heap.inc"
		.include "bltutil_cfg.inc"

		.include "version-date.inc"

		.import oswordGetRomBase
		.import cmdBLTurbo
		.import cmdXMdump
		.import cmdSRLOAD
		.import cmdSRNUKE
		.import cmdSRNUKE_reboot
		.import cmdSRNUKE_lang
		.import cmdSRERASE
		.import cmdSRCOPY
		.import cmdRoms
		.import cmdXMLoad
		.import cmdXMSave
		.import romThrottleInit

		.import autohazel_boot_first
		.import autohazel_boot_second


		.export	Copyright
		.export strCmdBLTurbo
		.export ServiceOut
		.export ServiceOutA0
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
		SJTE	$01, svc1_ClaimAbs
		SJTE	$04, svc4_COMMAND
		SJTE	$05, svc5_UKIRQ
		SJTE	$08, svc8_OSWORD
		SJTE	$09, svc9_HELP
		SJTE	$FE, svcFE_TubeInit
Serv_jump_table_Len	:= 	* - Serv_jump_table	

svcFE_TubeInit:
		pha
		jsr	CheckBlitterPresent
		bcs	@s
		jsr      cfgGetAPISubLevel_1_3
		bcc	@s
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
		jsr	romThrottleInit
@s2:		


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
		jsr	OSNEWL

@nope:		jmp	ServiceOut


; -----------------
; SERVICE 9 - *Help
; -----------------
; help string is at (&F2),Y
svc9_HELP:
		lda	zp_mos_txtptr
		sta	zp_tmp_ptr
		lda	zp_mos_txtptr + 1
		sta	zp_tmp_ptr + 1

		jsr	SkipSpacesPTR
		cmp	#$D
		beq	svc9_HELP_nokey

svc9_keyloop:
		; keywords were included scan for our key
		ldx	#0
@1:		inx
		lda	(zp_tmp_ptr),Y
		iny
		jsr	ToUpper				; to upper
		cmp	str_HELP_KEY-1,X	
		beq	@1
		cmp	#'.'
		beq	svc9_helptable
		cmp	#' '+1
		bcc	@keyend2			; <' ' - at end of keywords (on command line)
@3:		lda	(zp_tmp_ptr),Y			; not at end skip forwards to next space or lower
		iny
		cmp	#' '+1
		bcs	@3
		dey					; move back one to point at space or lower
		jsr	SkipSpacesPTR
		cmp	#$D				
		bne	@keyend
		jmp	svc9_HELP_exit			; end of command line, done
@keyend2:	dey
@keyend:	lda	str_HELP_KEY-1,X
		beq	svc9_helptable			; at end of keyword show table
		jsr	SkipSpacesPTR			; try another
		cmp	#$D
		beq	svc9_HELP_exit
		bne	svc9_keyloop

svc9_helptable:	
		jsr	svc9_HELP_showbanner
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
@lp:
		ldy	tbl_commands+1,X		; get hi byte of string
		beq	svc9_HELP_exit			; if zero at end of table
		jsr	PrintSpc
		jsr	PrintSpc
		txa
		pha
		lda	tbl_commands,X			; lo byte
		tax
		jsr	PrintXY
		jsr	PrintSpc
		pla
		tax
		inx
		inx
		inx
		inx					; point at help args string
		ldy	tbl_commands+1,X		; hi byte of args string
		beq	@sk3
		txa
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


svc9_HELP_nokey:
		jsr	svc9_HELP_showbanner
svc9_HELP_exit:	jmp	ServiceOut


svc9_HELP_showbanner:
		jsr	PrintNL
		lda	#<utils_name
		sta	zp_tmp_ptr
		lda	#>utils_name			; point at name, version, copyright strings
		sta	zp_tmp_ptr+1
		lda	#2
		sta	zp_trans_tmp
		ldy	#0
@1:		jsr	PrintPTR
		jsr	PrintSpc
		dec	zp_trans_tmp
		bne	@1
		jsr	OSNEWL

		jsr	CheckBlitterPresent
		bcc	@skp
		jsr	CheckPaulaPresent
		bcs	@skp_notp

		ldx	#<cmdHelpPaulaPresent
		ldy	#>cmdHelpPaulaPresent
		jsr	PrintXY
		jmp	@skp2

@skp_notp:
		ldx	#<cmdHelpNotPresent
		ldy	#>cmdHelpNotPresent
		jsr	PrintXY
		jmp	@skp2

@skp:

		ldx	#<cmdHelpPresent
		ldy	#>cmdHelpPresent
		jsr	PrintXY
		jmp	@skp2
@skp2:

		jmp	PrintNL


; --------------------
; SERVICE 4 - *COMMAND
; --------------------

svc4_COMMAND:	; scan command table for commands

		; save begining of command pointer
		tya
		pha

		lda	#<tbl_commands
		sta	zp_mos_genPTR
		lda	#>tbl_commands
		sta	zp_mos_genPTR + 1

		lda	zp_mos_jimdevsave
		cmp	#JIM_DEVNO_HOG1MPAULA
		bne	cmd_loop
		ldx	tbl_commands_PAULA-tbl_commands

		lda	#<tbl_commands_PAULA
		sta	zp_mos_genPTR
		lda	#>tbl_commands_PAULA
		sta	zp_mos_genPTR + 1



cmd_loop:	pla
		pha
		tay					; restore zp_mos_txtptr and Y from stack
		jsr	SkipSpacesPTR
		sty	zp_mos_error_ptr + 1		; we have to subtract the start Y from the string pointer!
		ldy	#0
		sec
		lda	(zp_mos_genPTR),Y
		sbc	zp_mos_error_ptr + 1
		sta	zp_mos_error_ptr
		iny
		lda	(zp_mos_genPTR),Y		
		beq	svc4_CMD_exit			; no more commands
		sbc	#0
		ldy	zp_mos_error_ptr+1		; get back Y
		sta	zp_mos_error_ptr+1		; point to command name - Y
		dey
@cmd_match_lp:	iny
		lda	(zp_mos_txtptr),Y
		jsr	ToUpper
		cmp	(zp_mos_error_ptr),Y
		beq	@cmd_match_lp
		lda	(zp_mos_error_ptr),Y		; command name finished
		beq	@cmd_match_sk
@cmd_match_nxt:	lda	zp_mos_genPTR
		clc
		adc	#6
		sta	zp_mos_genPTR
		bcc	cmd_loop			; try next table entry
		inc	zp_mos_genPTR+1
		bne	cmd_loop

@cmd_match_sk:	lda	(zp_mos_txtptr),Y
		cmp	#' '+1
		bcs	@cmd_match_nxt		

svc4_CMD_exec:	pla					; discard stacked y
		; push address of ServiceOutA0 to stack for return
		lda	#>(ServiceOutA0-1)
		pha
		lda	#<(ServiceOutA0-1)
		pha
		sty	zp_mos_error_ptr
		; push address of Command Routine to stack for rts
		ldy	#3
		lda	(zp_mos_genPTR),Y
		pha
		dey
		lda	(zp_mos_genPTR),Y
		pha
		ldy	zp_mos_error_ptr
		rts					; execute command


svc4_CMD_exit:	pla					; discard stacked Y
		jmp	ServiceOut


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
; SERVICE 8 - OSWORD
; --------------------

;		A = $99
;	XY?0 <16 - Get SWROM base address
;	---------------------------------
;	On Entry:
;		XY?0 	= Rom #
;		XY?1	= flags: (combination of)
;			$80	= current set
;			$C0	= alternate set
;			$20	= ignore memi (ignore inhibit)
;			$01	= map 1 (map 0 if unset)
;		XY?2	?
;	On Exit:
;		XY?0	= return flags
;			$80	= set if On board Flash
;			$40	= set if SYS
;			$20	= memi (swrom/ram inhibited)
;			$01	= map 1 (map 0 if not set)
;		XY?1	= rom base page lo ($80 if SYS)
;		XY?2	= rom base page hi ($FF if SYS)


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

str_HELP_KEY	:= 	utils_name
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
strHelpBLTurbo:		.byte	"[M[-]] [L<pagemask>] [R<n>[-][X][!]] [?]",0
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

cmdHelpPresent:		.byte	130,"(Blitter present)",0
cmdHelpPaulaPresent:		.byte	130," (1M Paula present)",0
cmdHelpNotPresent:	.byte	129,"(Blitter/1M Paula not present)",0

