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


		
		.include	"mosrom.inc"
		.include 	"oslib.inc"
		.include	"common.inc"
		.include	"hardware.inc"
		.include	"bltutil.inc"

		.include	"bltutil_jimstuff.inc"
		.include	"bltutil_utils.inc"


		.export	printCPU
		.export printHardCPU
		.export cfgPrintVersionBoot
		.export cfgGetAPILevel
		.export cfgGetRomMap
		.export cfgGetStringY
		.export cfgPrintStringY
		.export cmdInfo


; NOTE: sheila BLT_MK2_CFG0/1 registers are deprecated - now in JIM page FC 008x
sheila_BLT_API0_CFG0			:= $FE3E
sheila_BLT_API0_CFG1			:= $FE3F



		.CODE


;=============================================================================
; Version / Configuration access functions
;=============================================================================
; Currently supports API level 0 and 1. 0 is deprecated and may be removed
; at any time
; all the cfgXXX routines expect:
; - device is setup and zp_mos_jimdevsave contains the correct device number
; - we can freely change FCFD/E (jim page)

;-----------------------------------------------------------------------------
; cfgGetRomMap
;-----------------------------------------------------------------------------
; Returns current ROM map number in A or Cy=1 if no ROMS (i.e. Paula) [always 0 or 1]
; Also returns Ov=1, Cy=1 id MEMI inhibit jumper fitted
; A is 0 if CS set
cfgGetRomMap:
		jsr	cfgGetAPILevel
		clv
		bcs	@retCs
		beq	@API0

		lda	JIM+jim_offs_VERSION_Board_level
		cmp	#3		; check for >= Mk.3 assume Mk.1 and Mk.2 same config
		bcc	@mk2

		; mk.3 switches
		; assume future boards have same config options as mk.3
		lda	JIM+jim_offs_VERSION_cfg_bits+0
		and	#BLT_MK3_CFG0_MEMI
		beq	@retOvCs				; if 0 (jumper fitted) return Cs,Ov
		lda	JIM+jim_offs_VERSION_cfg_bits+0
		and	#BLT_MK3_CFG0_T65			; isolate T65 jumper setting
		pha						; save
		lda	JIM+jim_offs_VERSION_cfg_bits+0
		and	#BLT_MK3_CFG0_SWROMX			; get SWROMX bit
		bne	@skswromx				; if SWROMX not fitted jump
		pla
		eor	#BLT_MK3_CFG0_T65			; toggle T65 bit
		jmp	@sk3


@mk2:		; Mk.2 detect
		lda	JIM+jim_offs_VERSION_cfg_bits+1
		and	#BLT_MK2_CFG1_MEMI
		beq	@retOvCs				; if 0 (jumper fitted) return Cs,Ov
		lda	JIM+jim_offs_VERSION_cfg_bits+0
		and	#BLT_MK2_CFG0_T65				; isolate T65 jumper setting
		pha						; save
		lda	JIM+jim_offs_VERSION_cfg_bits+0	
		and	#BLT_MK2_CFG0_SWROMX				; get SWROMX bit
		bne	@skswromx				; if SWROMX not fitted jump
		pla
		jmp	@sk2					; toggle T65 bit



@API0:		lda	sheila_BLT_API0_CFG0
		and	#BLT_MK2_CFG0_T65
		pha
		lda	sheila_BLT_API0_CFG0
		and	#BLT_MK2_CFG0_SWROMX
		beq	@skswromx
		pla
@sk2:		eor	#BLT_MK2_CFG0_T65
		pha
@skswromx:	pla
@sk3:		beq	@ok
		lda	#1
@ok:		clc
@ret:		rts
@retOvCs:	bit	@ovset
@retCs:		lda	#0
		sec
		rts
@ovset:		.byte 	$40


		.import str_Dossy		; from header

cfgPrintVersionBoot:
		jsr	cfgGetAPILevel
		bcs	@ret
		pha				; save API level

		ldx	#<str_Dossy
		ldy	#>str_Dossy
		jsr	PrintXY
		lda	#' '
		ldx	vduvar_MODE
		cpx	#7
		bne	@nm71
		lda	#130		
@nm71:		jsr	OSWRCH

		lda	zp_mos_jimdevsave
		cmp	#JIM_DEVNO_HOG1MPAULA
		bne	@skP

		pla				; Discard API
		ldx	#<str_Paula
		ldy	#>str_Paula
		jsr	PrintXY			; Print banner and Exit
		clc
		rts

@skP:		ldx	#<str_Blitter
		ldy	#>str_Blitter
		jsr	PrintXY

		pla
		pha
		beq	@skAPI0_1
		jsr	PrintSpc
		ldy	#2			; Board
		jsr	cfgPrintStringY				

@skAPI0_1:	jsr	OSNEWL

		jsr	printCPU

		; show ROM Map
		jsr	cfgGetRomMap
		bcs	@nomap			; Error, skip
		pha
		ldx	#<str_map
		ldy	#>str_map
		jsr	PrintXY	
		pla
		clc
		adc	#'0'
		jsr	OSWRCH
		
@nomap:
		jsr	OSNEWL

		ldy	#0			; either full string for API 0 or 
		jsr	cfgPrintStringY
		pla				; Get back API level
		beq	@API0
		jsr	PrintSpc
		ldy	#1
		jsr     cfgPrintStringY		; build time
@API0:		clc
@ret:		rts

;-----------------------------------------------------------------------------
; cfgGetAPILevel
;-----------------------------------------------------------------------------
; Returns API level in A
; on exit the current JIM page will be pointing to the VERSION info page
; returns CS if Blitter not present/selected (by testing zp_mos_jimdevsave)
; Z flag is set if API=0
cfgGetAPILevel:
		jsr	jimSetDEV_either
		bcs	@ret
		jsr	jimPageVersion
		lda	JIM+jim_offs_VERSION_API_level
@ret:		rts

;;; ;-----------------------------------------------------------------------------
;;; ; cfgGetAPILevelExt
;;; ;-----------------------------------------------------------------------------
;;; ; Returns current board type, API level and sub level in A,X,Y
;;; ; on exit the current JIM page will be pointing to the VERSION info page
;;; ; returns CS if Blitter not present/selected (by testing zp_mos_jimdevsave)
;;; ; Z flag is set if API=0
;;; cfgGetAPILevelExt:
;;; 		jsr	jimCheckEitherSelected
;;; 		bcs	@ret
;;; 		jsr	jimPageVersion
;;; 		lda	JIM+jim_offs_VERSION_API_level
;;; 		beq	@API0
;;; 		ldx	JIM+jim_offs_VERSION_Board_level
;;; 		ldy	JIM+jim_offs_VERSION_API_sublevel
;;; 		ora	#0
;;; 		clc
;;; 		rts
;;; 
;;; @API0:		lda	#0
;;; 		tax
;;; 		tay
;;; 		; API 0 doesn't specify board type/level so always return Mk.2 as board level
;;; 		lda	zp_mos_jimdevsave
;;; 		cmp	#JIM_DEVNO_HOG1MPAULA
;;; 		bne	@notp
;;; 		inx
;;; 		inx
;;; @notp:		tya		; return A=0
;;; 		clc
;;; @ret:		rts
		
;-----------------------------------------------------------------------------
; cfgGetStringY
;-----------------------------------------------------------------------------
; Returns version string component in XY, on entry Y contains the index of the string
; on XY contains a pointer to the string, A contains the first character of the string
; Z flag is set if string is empty
; if Cy=1 then there is an error and there is no string
; The string may be empty if the index is past the end of all strings

cfgGetStringY:	ldx	#0
		tya
		beq	@ok1
		jsr	cfgGetAPILevel
		bcs	@ret
		beq	@ok1
@lp:		
@lp2:		lda	JIM,X
		beq	@sk1
		inx
		bpl	@lp2
		; past end of strings, point at 0
		ldx	#<@a_zero
		ldy	#>@a_zero
		clc
		rts
@a_zero:	.byte	0
@sk1:		inx
		dey
		bne	@lp
@ok1:		ldy	#>JIM
		lda	JIM,X
		clc
@ret:		rts

;-----------------------------------------------------------------------------
; cfgPrintStringY
;-----------------------------------------------------------------------------
; Prints the version string component in XY, on entry Y contains the index of the string
cfgPrintStringY:
		jsr	cfgGetStringY
		jmp	PrintXY


printHardCPU:	sec
		bcs	printCPU2

printCPU:	clc
printCPU2:	php
		jsr	cfgGetAPILevel
		beq	@API0
		lda	JIM+jim_offs_VERSION_Board_level
		cmp	#3		; check for >= Mk.3 assume Mk.1 and Mk.2 same config
		bcc	@mk2

		;mk3 look up
		;first check T65
		plp
		bcs	@mk3hard
		lda	JIM+jim_offs_VERSION_cfg_bits+0
		and	#BLT_MK3_CFG0_T65
		beq	@T65
@mk3hard:	lda	JIM+jim_offs_VERSION_cfg_bits+1
		and	#$FE
		ldx	#cputbl_mk3_len-2
@lp3:		cmp	cputbl_mk3,X
		beq	@skmk3_fnd
		dex
		dex
		bpl	@lp3
		lda	#'?'
		jmp	OSWRCH
@skmk3_fnd:	lda	cputbl_mk3+1,X
		jmp	@printCPUA

		; get config bits as TTTT0SSS from 


@mk2:		lda	JIM+jim_offs_VERSION_cfg_bits
		eor	#$FF				;invert
		jmp	@printCPU2_mk2

@API0:		lda	sheila_BLT_API0_CFG0	; get inverted cpu and T65 bits

@printCPU2_mk2:	plp
		bcs	@printHardCPU_mk2
		bit	b_mask_T65
		beq	@printHardCPU_mk2
@T65:		lda	#cpu_tbl_T65 - cputbl_mk2
		bne	@printCPUA
@printHardCPU_mk2:
		and	#$0E			; get cpu type
		asl	A
		
@printCPUA:	tax
		pha
		ldy	cputbl_mk2+1,X
		lda	cputbl_mk2,X
		tax
		jsr	PrintXY
		jsr	PrintSpc
		pla
		tax
		lda	cputbl_mk2+3,X
		pha
		lsr	A
		lsr	A
		lsr	A
		lsr	A
		beq	@sk1
		jsr	PrintHexNybA
@sk1:		pla
		jsr	PrintHexNybA
		lda	cputbl_mk2+2,X
		beq	@sk2
		pha
		lda	#'.'
		jsr	PrintA
		pla
		pha
		lsr	A
		lsr	A
		lsr	A
		lsr	A
		jsr	PrintHexNybA	
		pla
		and	#$0F
		beq	@sk2
		jsr	PrintHexNybA	
@sk2:		ldx	#<str_cpu_MHz
		ldy	#>str_cpu_MHz
		jmp	PrintXY
b_mask_T65:	.byte	BLT_MK2_CFG0_T65


brk_NoBlitter:
		M_ERROR
		.byte	$FF, "No Blitter", 0

;------------------------------------------------------------------------------
; *BLINFO : cmdInfo
;------------------------------------------------------------------------------

cmdInfo_API0:	jsr	PrintImmed
		.byte   13,"Build info   : ",0
		ldy	#0
		jsr	cfgPrintStringY
		jsr	PrintImmed
		.byte	13,"mk.2 bootbits: ",0
		lda	sheila_BLT_API0_CFG1
		jsr	PrintHexA
		lda	sheila_BLT_API0_CFG0
		jsr	PrintHexA
		jmp	cmdInfo_API0_mem

cmdInfo:	jsr	cfgGetAPILevel
		bcs	brk_NoBlitter

@ok1:
		pha
		lda	zp_mos_jimdevsave
		cmp	#JIM_DEVNO_HOG1MPAULA
		bne	@Blit
		pla
		jsr	PrintImmed
		.byte	"Paula",0
		jmp	_justChipRAM


@Blit:		jsr	PrintImmed
		.byte	   "Hard CPU     : ",0
		jsr	printHardCPU
		jsr	PrintImmed
		.byte	13,"Active CPU   : ",0
		jsr	printCPU

		pla				;API level
		bne	@cmdInfo_API1
		jmp	cmdInfo_API0

@cmdInfo_API1:		; print ver strings
		ldx	#0
@verlp:		txa
		pha				; save counter on stack		
		lda	tbl_bld+1,X		; get index
		tay
		jsr	cfgGetStringY
		beq	@sknov
		txa
		pha
		tya
		pha
		jsr	PrintNL
		tsx
		lda	$103,X			; get back counter
		tax
		jsr	cfgBldTblPrintX
		pla
		tay
		pla
		tax
		jsr	PrintXY
@sknov:		pla
		tax
		inx
		inx
		cpx	#8
		bcc	@verlp

		jsr	PrintImmed
		.byte	13,"Boot config #: ",0
		ldx	#3
@bblp:		lda	JIM+jim_offs_VERSION_cfg_bits,X
		jsr	PrintHexA
		dex
		bpl	@bblp

		jsr	PrintImmed
		.byte	13,"Boot jumpers : ",0

		ldx	#tbl_boot_cfg_mk2-tbl_bld
		lda	JIM+jim_offs_VERSION_Board_level
		cmp	#3
		bcc	@mk2
		ldx	#tbl_boot_cfg_mk3-tbl_bld
@mk2:		ldy	#0				; used to mark first pass
@flaglp:	lda	tbl_bld,X			; check for 0
		beq	@flags_done
		lda	tbl_bld+1,X
		and	JIM+jim_offs_VERSION_cfg_bits
		bne	@flags_next
		lda	tbl_bld+2,X
		and	JIM+jim_offs_VERSION_cfg_bits+1
		bne	@flags_next

		jsr	commaSpcIfFirst 

		tya
		pha
		txa
		pha
		jsr	cfgBldTblPrintX2
		pla
		tax
		pla
		tay		

@flags_next:	inx
		inx
		inx
		bpl	@flaglp
@flags_done:	

		jsr	PrintImmed
		.byte	13,"Host System  : ",0

		lda	JIM+jim_offs_VERSION_cfg_bits		; get MK.3 host in bit 2..0 inverted
		ldx	JIM+jim_offs_VERSION_Board_level
		cpx	#3
		bcs	@mk2_2
		lda	JIM+jim_offs_VERSION_cfg_bits+1		; get MK.2 host in bit 13..11 inverted
		lsr	A
		lsr	A
		lsr	A
@mk2_2:		and	#7
		eor	#7
		cmp	#5
		bcc	@sk_uk
		lda	#4					; unknown string
@sk_uk:		clc
		adc	#tbl_hosts-tbl_bld
		tax
		jsr	cfgBldTblPrintX2

		; capabilities

		jsr	PrintImmed
		.byte	13,"Capabilities : ",0

		ldx	#tbl_capbits - tbl_bld
		ldy	#0
		lda	JIM + jim_offs_VERSION_cap_bits+0
@caplp:		cpx	#tbl_capbits - tbl_bld + 16
		bne	@skcap00
		lda	JIM + jim_offs_VERSION_cap_bits+2
		jmp	@skcap0
@skcap00:	cpx	#tbl_capbits - tbl_bld + 8
		bne	@skcap0		
		lda	JIM + jim_offs_VERSION_cap_bits+1
@skcap0:	ror	A
		bcc	@capnext
		pha

		jsr	commaSpcIfFirst 

		tya
		pha
		txa
		pha

		jsr	cfgBldTblPrintX2

		pla
		tax
		pha

		; check for DMA/SOUND, if so show # of channels
		ldy	#<jim_DMAC_SND_SEL
		cpx	#tbl_capbits - tbl_bld + CAP_IX_SND
		beq	@chans
		cpx	#tbl_capbits - tbl_bld + CAP_IX_DMA
		bne 	@nochans
		ldy 	#<jim_DMAC_DMA_SEL
@chans:		lda	#'('
		jsr	OSWRCH
		jsr	zeroAcc
		jsr	jimPageChipset
		lda	#$FF
		sta	JIM,Y
		lda	JIM,Y		
		clc
		adc	#1
		sta	zp_trans_acc
		jsr	PrintDec
		lda	#')'
		jsr	OSWRCH
		jsr	jimPageVersion

@nochans:
		pla
		tax
		pla
		tay
		pla

@capnext:	inx
		cpx	#tbl_capbits - tbl_bld + CAP_IX_MAX + 1
		bne	@caplp

		; capabilities

		jsr	PrintImmed
		.byte	13,"Cap. bits    : ",0
		lda	JIM + jim_offs_VERSION_cap_bits+2
		jsr	PrintHexA
		lda	JIM + jim_offs_VERSION_cap_bits+1
		jsr	PrintHexA
		lda	JIM + jim_offs_VERSION_cap_bits+0
		jsr	PrintHexA

cmdInfo_API0_mem:
		; get BB RAM size (assume starts at bank 60 and is at most 20 banks long)		
		ldx	#$60
		ldy	#$00
		jsr	cfgMemCheckAlias
		bcc	@justChipRAM
		bne	@BBRAM_test

		; print combined
		jsr	PrintImmed
		.byte	13, "Chip/BB RAM  : ",0
		jmp	@noBB


@BBRAM_test:	
		ldy	#$80
		jsr	cfgMemSize
		jsr	zeroAcc
		sta	zp_trans_acc+2

		jsr	PrintImmed
		.byte	13, "BB RAM       : ",0

		jsr	PrintSizeK

@justChipRAM:
		jsr	PrintImmed
		.byte	13, "Chip RAM     : ",0


@noBB:
@BBChipram:	ldx	#0
		ldy	#$60
		jsr	cfgMemSize
		jsr	zeroAcc
		sta	zp_trans_acc+2
		jsr	PrintSizeK

		jmp	PrintNL

_justChipRAM = @justChipRAM

;======================= end of *BLINFO

;-----------------------------------------------------------------------------
; cfgMemSize
;-----------------------------------------------------------------------------
; on Entry X is base bank, Y is limit
; A contains # of banks at exit
		; TODO: when move this to boot use other zp variables?
cfgMemSize:	php
		sei
		stx	zp_trans_tmp
		sty	zp_trans_tmp+1
		txa
		tay
		inx
@ms_lp:		jsr	cfgMemCheckAlias
		bcc	@ms_sk0
		beq	@ms_sk0
		inx
		cpx	zp_trans_tmp+1
		bne	@ms_lp		
@ms_sk0:	sec
		txa
		sbc	zp_trans_tmp
		plp
		rts

;-----------------------------------------------------------------------------
; cfgMemCheckAlias
;-----------------------------------------------------------------------------
; checks if the memory at bank in X is aliased at bank in Y
; performs a write to bank X
; corrupts Y
; returns CS and Z flags set memory is aliased
;         CS and Z flags clear if not aliased
;         CC if no writeable memory
; corrupts A 
cfgMemCheckAlias:
		pha				; this will get destroyed later
		lda	fred_JIM_PAGE_HI
		pha
		stx	fred_JIM_PAGE_HI
		lda	JIM
		pha

		lda	#$55
		sta	JIM			; X = 55
		sty	fred_JIM_PAGE_HI
		pha
		lda	JIM+1			; force databus to something else
		pla
		cmp	JIM
		bne	@notsame
		stx	fred_JIM_PAGE_HI
		lda	#$AA
		sta	JIM
		sty	fred_JIM_PAGE_HI
		pha
		lda	JIM+1			; force databus to something else
		pla
		cmp	JIM
		beq	@ex

@notsame:	stx	fred_JIM_PAGE_HI
		cmp	JIM
		beq	@ok_noalias
		clc
		bcc	@ex			; no writeable

@ok_noalias:	sec
		lda	#1			; cause Z flag off
@ex:		php
		stx	fred_JIM_PAGE_HI
		txa
		pha
		tsx
		; move flags up stack for later PLP at exit
		lda	$102,X
		sta	$105,X
		pla
		tax
		pla				; flags not needed
		pla				; orig mem value
		sta	JIM
		pla	
		sta	fred_JIM_PAGE_HI	; reset JIM pointer
		plp
		rts



cfgBldTblPrintX2:
		ldy	#>str_bld_base
		lda	tbl_bld,X
		clc
		adc	#<str_bld_base
		tax
		bcc	@sk2
		iny
@sk2:		jmp	PrintXY

cfgBldTblPrintX:
		jsr	cfgBldTblPrintX2
		jsr	PrintImmed
		.byte	" : ",0		
		rts


commaSpcIfFirst:
		cpy	#0
		beq	@first_cap
		jsr	PrintCommaSpace		
@first_cap:	iny
		rts

		.SEGMENT "RODATA"

tbl_bld:	.byte	str_bld_bran - str_bld_base, 3
		.byte	str_bld_ver - str_bld_base, 0
		.byte	str_bld_date - str_bld_base, 1
		.byte	str_bld_name - str_bld_base, 2
tbl_boot_cfg_mk2:
		.byte	str_bld_T65-str_bld_base
		.word	$0001
		.byte	str_bld_swromx-str_bld_base
		.word	$0010
		.byte	str_bld_mosram-str_bld_base
		.word	$0020
		.byte	str_bld_memi-str_bld_base
		.word	$0100
		.byte	0
tbl_boot_cfg_mk3:
		.byte	str_bld_T65-str_bld_base
		.word	$0008
		.byte	str_bld_swromx-str_bld_base
		.word	$0010
		.byte	str_bld_mosram-str_bld_base
		.word	$0020
		.byte	str_bld_memi-str_bld_base
		.word	$0040
		.byte	0
tbl_hosts:	.byte	str_sys_B-str_bld_base
		.byte	str_sys_Elk-str_bld_base
		.byte	str_sys_BPlus-str_bld_base
		.byte	str_sys_M128-str_bld_base
		.byte	str_sys_UK-str_bld_base
tbl_capbits:	.byte	str_cap_CS - str_bld_base
		.byte	str_cap_DMA - str_bld_base
		.byte	str_Blitter - str_bld_base
		.byte	str_cap_AERIS - str_bld_base
		.byte	str_cap_I2C - str_bld_base
		.byte	str_cap_SND - str_bld_base
		.byte	str_cap_HDMI - str_bld_base
		.byte	str_bld_T65 - str_bld_base
		.byte	str_cpu_65c02 - str_bld_base
		.byte	str_cpu_6800 - str_bld_base
		.byte	str_cpu_80188 - str_bld_base
		.byte	str_cpu_65816 - str_bld_base
		.byte	str_cpu_6x09 - str_bld_base
		.byte	str_cpu_z80 - str_bld_base
		.byte	str_cpu_68008 - str_bld_base
		.byte	str_cpu_68000 - str_bld_base
		.byte	str_cpu_ARM2 - str_bld_base
		.byte	str_cpu_Z180 - str_bld_base
		.byte	str_cpu_SuperShadow - str_bld_base
		.byte	str_10ns_ChipRAM - str_bld_base
		.byte	str_45ns_BBRAM - str_bld_base

CAP_IX_CS	= 0
CAP_IX_DMA	= 1
CAP_IX_BLITTER	= 2
CAP_IX_AERIS	= 3
CAP_IX_I2C	= 4
CAP_IX_SND	= 5
CAP_IX_HDMI	= 6
CAP_IX_T65	= 7
CAP_IX_65C02	= 8
CAP_IX_6800	= 9
CAP_IX_80188	= 10
CAP_IX_65816	= 11
CAP_IX_6X09	= 12
CAP_IX_Z80	= 13
CAP_IX_68008	= 14
CAP_IX_68000	= 15
CAP_IX_ARM2	= 16
CAP_IX_Z180	= 17
CAP_IX_SuperShadow	= 18
CAP_IX_10ns_ChipRAM	= 19
CAP_IX_45ns_BBRAM	= 20
CAP_IX_MAX=20


str_bld_base:
str_bld_bran:	.byte	"Repository  ",0
str_bld_ver:	.byte	"Repo. ver   ",0
str_bld_date:	.byte	"Build date  ",0
str_bld_name:	.byte	"Board name  ",0
str_bld_swromx:	.byte	"Swap Roms",0
str_bld_mosram:	.byte	"MOSRAM",0
str_bld_memi:	.byte	"ROM inhibit",0
str_sys_B:	.byte	"Model B",0
str_sys_Elk:	.byte	"Electron",0
str_sys_BPlus:	.byte	"Model B+",0
str_sys_M128:	.byte	"Master 128",0
str_sys_UK:	.byte	"Unknown",0
str_cap_CS:	.byte   "Chipset",0
str_cap_DMA:	.byte   "DMA",0
str_Blitter:	.byte  	"Blitter", 0 
str_cap_AERIS:	.byte   "Aeris",0
str_cap_I2C:	.byte   "i2c",0
str_cap_SND:	.byte   "Paula",0
str_cap_HDMI:	.byte   "HDMI",0
str_bld_T65:	.byte	"T65",0
str_cpu_65c02:	.byte	"65C02",0
str_cpu_6800:	.byte	"6800",0
str_cpu_80188:	.byte	"80188",0
str_cpu_65816:	.byte	"65816",0
str_cpu_6x09:	.byte	"6x09",0
str_cpu_z80:	.byte	"z80",0
str_cpu_68008:	.byte	"68008",0
str_cpu_68000:	.byte	"68000",0
str_cpu_ARM2:	.byte	"ARM2",0
str_cpu_Z180:	.byte	"Z180",0
str_cpu_SuperShadow:	.byte	"SuperShadow",0
str_10ns_ChipRAM:	.byte	"10ns ChipRAM",0
str_45ns_BBRAM:	.byte	"45ns BB RAM",0


		; these are in the order of bits 3..1 of the config byte for the 1st 8 then followed by the mk.3 specifics
cputbl_mk2:		;	name		speed
cpu_tbl_6502A_2:	.word	str_cpu_6502A,	$0200
cpu_tbl_6x09_2:		.word	str_cpu_6x09,	$0200
cpu_tbl_65c02_8:	.word	str_cpu_65c02,	$0800
cpu_tbl_z80_8:		.word	str_cpu_z80,	$0800
			
cpu_tbl_65c02_4:	.word	str_cpu_65c02,	$0400
cpu_tbl_6x09_35:	.word	str_cpu_6x09,	$0350
cpu_tbl_6581_8:		.word	str_cpu_65816,	$0800
cpu_tbl_68008_10:	.word	str_cpu_68008,	$1000

cpu_tbl_T65:		.word	str_cpu_T65,	$1600

cpu_tbl_6800_2:		.word	str_cpu_6800, 	$0200
cpu_tbl_80188_20:	.word	str_cpu_80188,	$2000
cpu_tbl_68000_20:	.word	str_cpu_68000,	$2000
cpu_tbl_ARM2_8:		.word	str_cpu_ARM2,	$0800
cpu_tbl_Z180_20:	.word	str_cpu_Z180,	$2000


cputbl_mk3:		;	bits, tbl offs
			; where bits is high nybl=type bits, low=speed bits
			; i.e. PORTF[3..0] & PORTG[11 downto 9] & '0'
			.byte	$EA, cpu_tbl_65c02_8 - cputbl_mk2
			.byte	$DC, cpu_tbl_65c02_4 - cputbl_mk2
			.byte	$CA, cpu_tbl_6581_8 - cputbl_mk2
			.byte	$7E, cpu_tbl_6x09_2 - cputbl_mk2
			.byte	$74, cpu_tbl_6x09_35 - cputbl_mk2
			.byte	$70, cpu_tbl_6800_2 - cputbl_mk2
			.byte	$40, cpu_tbl_80188_20 - cputbl_mk2
			.byte	$30, cpu_tbl_68000_20 - cputbl_mk2
			.byte	$6E, cpu_tbl_ARM2_8 - cputbl_mk2
			.byte	$52, cpu_tbl_Z180_20 - cputbl_mk2
cputbl_mk3_len = * - cputbl_mk3


str_cpu_6502A:		.byte	"6502A",0
str_cpu_MHz:		.byte	"Mhz",0

str_cpu_T65:		.byte	"T65",0

str_Paula:		.byte  	"1M Paula", 0 
str_map:		.byte	" ROM Map ",0
