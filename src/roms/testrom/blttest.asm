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

		.include "version-date.inc"
		.include "blttest.inc"
		.SEGMENT "CODE_ROMHEADER"

		.autoimport

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
		SJTE	$04, svc4_COMMAND
		SJTE	$09, svc9_HELP
		SJTE	$02, svc_2_ClaimPrv
		SJTE	$24, svc_24_CountDyn_HAZEL
		SJTE	$21, svc_21_ClaimAbs_HAZEL
		SJTE	$22, svc_22_ClaimPrv_HAZEL
		SJTE	$23, svc_23_NotifyAbs_HAZEL
Serv_jump_table_Len	:= 	* - Serv_jump_table	

Service:
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
		dex
		dex
		lda	Serv_jump_table,X
		ldx	zp_mos_curROM			; get back X
		rts					; jump to service routine

ServiceOut:	ldx	zp_mos_curROM
		rts
ServiceOutA0:	ldx	zp_mos_curROM
		lda	#0				; Don't pass to other service routines
		rts

PrintServDbg:	php
		pha

		jsr	PrintHexAXY

		lda	#' '
		jsr	OSWRCH

		lda	swrom_wksp_tab,X
		jsr	PrintHexA

		jsr	PrintNL

		pla
		plp
		rts

svc_2_ClaimPrv:
		jsr	PrintServDbg
		; check to see if service 22 worked
		lda	swrom_wksp_tab,X
		beq	@s
		cmp	#$DC
		bcc	@ex

@s:		tya				; we didn't get any workspace, take a low page
		sta	swrom_wksp_tab,X
		iny

@ex:		lda	#2
		rts

svc_24_CountDyn_HAZEL:
		jsr	PrintServDbg
		dey		; one page please
		lda	#$24
		rts
svc_21_ClaimAbs_HAZEL:
		jsr	PrintServDbg
		cpy	#$C1	; one shared too please
		bcs	@ex
		ldy	#$C1
@ex:		rts
svc_22_ClaimPrv_HAZEL:
		jsr	PrintServDbg
		cpy	#$DC
		bcs	@ex
		tya
		sta	swrom_wksp_tab,X
		iny
@ex:		lda	#$21
		rts
svc_23_NotifyAbs_HAZEL:
		jsr	PrintServDbg
		rts


; -----------------
; SERVICE 9 - *Help
; -----------------
; help string is at (&F2),Y
svc9_HELP:
		tya
		pha

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
svc9_HELP_exit:	pla
		tay
		lda	#9
		jmp	ServiceOut


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
		ldx	#0

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

svc4_CMD_exec:	; push address of exit code to stack for return
		lda	#>(svc4_CMD_exit0-1)
		pha
		lda	#<(svc4_CMD_exit0-1)
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

svc4_CMD_exit0:	pla					; discard stacked Y
		tay
		lda	#0
		jmp	ServiceOut


svc4_CMD_exit:	pla					; discard stacked Y
		tay
		lda	#4
		jmp	ServiceOut


cmdBLTEST:	
		jsr	PrintImmed
		.byte   "BLTEST",13,10,0

		jsr	PrintImmed
		.byte	"AUTOHAZEL MAP : ",0
		lda	$fe39
		jsr	PrintHexA
		lda	$fe38
		jsr	PrintHexA
		jsr	PrintNL


		jsr	PrintImmed
		.byte	"WR ABS C0xx",0

		lda	$C080
		pha
		lda	$C081
		pha
		lda	#$A5
		sta	$C080
		lda	#$5A
		sta	$C081

		lda	$C080
		cmp	#$A5
		bne	@f1
		lda	$C081
		cmp	#$5A
		bne	@f1

		jsr	@ok
		jmp	@t2
@f1:		jsr	@fail
@t2:		pla
		sta	$C081
		pla
		sta	$C080

		ldx	zp_mos_curROM

		jsr	PrintImmed
		.byte	"WR PRV ",0
		lda	swrom_wksp_tab,X
		jsr	PrintHexA
		jsr	PrintImmed
		.byte	"xx",0

		lda	swrom_wksp_tab,X
		sta	zp_mos_genPTR+1
		lda	#0
		sta	zp_mos_genPTR

		ldy	#0
		lda	#$A5
		sta	(zp_mos_genPTR),Y
		iny
		lda	#$5A
		sta	(zp_mos_genPTR),Y

		dey
		lda	(zp_mos_genPTR),Y
		iny
		cmp	#$A5
		bne	@f2
		lda	(zp_mos_genPTR),Y
		cmp	#$5A
		bne	@f2

		jsr	@ok
		jmp	@t3
@f2:		jsr	@fail
@t3:		
		rts

@ok:		jsr	PrintImmed
		.byte	"OK",13,10,0
		rts
@fail:		pha
		jsr	PrintImmed
		.byte	"FAIL! ",0
		pla
		jsr	PrintHexA
		jsr	PrintNL		
		rts

		.SEGMENT "RODATA"


tbl_commands:		.word	strBLTEST, cmdBLTEST-1, helpBLTEST
			.word	0

str_HELP_KEY		:= 	utils_name
strBLTEST:		.byte	"BLTEST", 0
helpBLTEST:		.byte	"????", 0

