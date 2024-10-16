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

		.include "hardware.inc"

NOICE_BRK_INST	:= 	$5C				; special BRK instruction for noice

ADDR_ERRBUF	:=	$100				; base of stack!
PG_EEPROM_BASE	:=	$9000				; base phys/jim address of EEPROM is $90 0000
							; note: this is a second copy of the EEPROM which
							; also appears based at $80 0000

OSWORD_BLTUTIL	:=	$99				; blutils #

OSWORD_OP_ALLOC :=	$10
OSWORD_OP_FREE  :=	$11
OSWORD_OP_I2C	:=	$13

JIM_SCRATCH	:=	$00FD				; page address of scratch space

;offsets in scrarch page
SCR_JIMDEVSAVE	:=	$00				; belt and braces used in cases of a BRK

OSWORD_BLTUTIL_FLAG_CURRENT	:= $80
OSWORD_BLTUTIL_FLAG_ALTERNATE	:= $40
OSWORD_BLTUTIL_FLAG_IGNOREMEMI	:= $20
OSWORD_BLTUTIL_FLAG_MAP1	:= $01

OSWORD_BLTUTIL_RET_FLASH	:= $80			; if memory is chip flash
OSWORD_BLTUTIL_RET_SYS		:= $40			; bank also base set to FF 80xx
OSWORD_BLTUTIL_RET_MEMI		:= $20
OSWORD_BLTUTIL_RET_ISCUR	:= $02
OSWORD_BLTUTIL_RET_MAP1		:= $01

.macro		VERSION_NAME
		.byte	"BLTUTIL"
.endmacro

		;TODO : move these to autogen'd files? Agree version # with JGH
.macro		VERSION_BYTE
		.byte	3
.endmacro

.macro		VERSION_STRING
		.byte	"0.07"
.endmacro

.macro		M_ERROR
		jsr	BounceErrorOffStack
.endmacro

.macro		TODO	error
		M_ERROR
		.byte	$FF
		.byte	error
		.byte	0
.endmacro

.macro		CLAIMDEV
		jsr	jimClaimDev
.endmacro

.macro		SJTE	serv, addr
		.byte	serv
		.byte	>(addr - 1)			; bytes here in order ready to be stacked then rts'd to
		.byte 	<(addr - 1)
.endmacro


		; place a string in memory with the last character's top bit set
.macro		TOPTERM s
	.if (.strlen(s) = 0)
		.byte	$80
	.elseif (.strlen(s) = 1)
		.byte	.strat(s, 0) | $80
	.else
		.repeat	.strlen(s)-1, I
		.byte	.strat(s, I)
		.endrepeat
		.byte	.strat(s, .strlen(s)-1) | $80
	.endif
.endmacro

.macro		HEAD16	s
		jsr	PrintImmedT16
		TOPTERM s
.endmacro


zp_trans_tmp	:=	$A8				; transient command buffer
zp_trans_acc	:=	$AC				; 4 byte accumulator used in hex parsers
zp_tmp_ptr	:=	$AC				; !! NOTE: overlaps acc

zp_SRCOPY_src	:=	zp_trans_tmp + 1
zp_SRCOPY_dest	:=	zp_trans_tmp + 0
zp_SRCOPY_flags	:=	zp_trans_tmp + 2		; when negative dest if a flash

zp_ROMS_ctr	:=	zp_trans_tmp + 0
zp_ROMS_copyptr	:=	zp_trans_tmp + 1
zp_ROMS_flags	:=	zp_trans_tmp + 3
zp_ROMS_OS99ret	:=	zp_trans_acc + 2
zp_ROMS_bank	:=	zp_trans_acc + 3

zp_ERASE_dest	:=	zp_trans_tmp + 0
zp_ERASE_flags	:=	zp_trans_tmp + 1
zp_ERASE_ctr	:=	zp_trans_tmp + 2
zp_ERASE_errct	:=	zp_trans_tmp + 3
zp_ERASE_bank	:=	zp_trans_tmp + 5

zp_SRLOAD_dest	:=	zp_trans_tmp + 0
zp_SRLOAD_flags	:=	zp_trans_tmp + 1
zp_SRLOAD_ptr	:=	zp_trans_tmp + 2
zp_SRLOAD_tmpA	:=	zp_trans_tmp + 4		; note overlaps acc
zp_SRLOAD_bank	:=	zp_trans_tmp + 5		; note overlaps acc

SRLOAD_buffer_page	:=	$30

zp_mdump_addr	:=	zp_trans_tmp + 0
zp_mdump_end	:=	zp_trans_tmp + 4		; not overlaps acc
zp_mdump_cols	:=	zp_mos_txtptr			; allows 32 bit addressing

; we can claim to be a language here...well sort of...
ZP_NUKE_LBAS	:=	$0
ZP_NUKE_ERRPTR	:=	ZP_NUKE_LBAS + 0
ZP_NUKE_S_TOP	:=	ZP_NUKE_LBAS + 2
ZP_NUKE_ROMSF	:=	ZP_NUKE_LBAS + 4
ZP_NUKE_PREVLANG:=	ZP_NUKE_LBAS + 5
STR_NUKE_CMD	:=	$700

zp_blturbo_old	:=	zp_trans_tmp + 0
zp_blturbo_new	:=	zp_trans_tmp + 1
zp_blturbo_ptr	:=	zp_trans_tmp + 2
zp_blturbo_fl	:=	zp_trans_tmp + 4




PAGE_ROMSCRATCH		:=	$0080
PAGE_SAMPLETBL		:=	$0081
PAGE_SOUNDWKSP		:=	$0083
PAGE_SOUNDBUFFERS	:=	$0084
PAGE_RAM_TOP_BLITTER	:=	$1C00			; note leave room for SWRAM!
PAGE_RAM_TOP_PAULA	:=	$0800


			; offsets within scratch space
SCRATCH_CHECKSUM	:=	$00			; not used currently (reset on break)
SCRATCH_HEAPTOP		:=	$04			; top of head / ram
SCRATCH_HEAPBOT		:=	$06			; bottom of heap / extent allocated to heap (may contain holes)
SCRATCH_HEAPLIM		:=	$08			; lower limit for heap, will not allocate below here

SAMTBL_SZ	:=	8			; size of a table entry
SAMTBLOFFS_BASE :=	0			; page number of start of sample
SAMTBLOFFS_LEN  :=	2			; length in samples
SAMTBLOFFS_REPL :=	4			; repeat offset
SAMTBLOFFS_FLAGS:=	7


			; offsets within the sound workspace page at 8300
; the following are all in the ROM workspace at JIM 00 8000
SNDWKSP_SOUNDFLAGS	:=	$00			
SCR_FLAG_SND_EN		:=	$80			; enabled flag

SND_BUFFER_NUMBER_0	:=	$14			; buffer numbers are $14..$1B for channels 0..7
SND_BUF_LEN		:=	21
SND_NUM_CHANS		:=	8

SNDWKSP_OLDINSV		:=	$02
SNDWKSP_OLDREMV		:=	$04
SNDWKSP_OLDCNPV		:=	$06
SNDWKSP_OLDBYTEV	:=	$08

SNDWKDP_SCRATCH8	:=	$10			; 8 bytes of scratch space

; note the following need to be >SND_BUFFER_NUMBER_0 to avoid LDA nnn-$14,X tickling FRED
SNDWKSP_BUF_BUSY_0	:=	$20			; 1 byte for each channel - shows if there is stuff in the buffer
SNDWKSP_BUF_OUT_0	:=	$28			; 1 byte for each channel - pointer into buffer
SNDWKSP_BUF_IN_0	:=	$30			; 1 byte for each channel - pointer into buffer
SNDWKSP_ACTIVE		:=	$38			; sound channel active flags 



SNDWKSP_VAR_START		:= $40
SNDWKSP_QUEUE_OCC		:= $40
SNDWKSP_AMP_CUR			:= $48
SNDWKSP_AMP_PHASE_CUR		:= $50			; current amplitude phase of envelope 0..3
SNDWKSP_AMP_BASE_PITCH		:= $58
SNDWKSP_PITCH_PHASE_CUR		:= $60
SNDWKSP_PITCH_PH_STEPS		:= $68
SNDWKSP_DURATION		:= $70			; duration from SOUND command
SNDWKSP_DURATION_SUB		:= $78			; counts down from 5..0 to give 50ms per duration above
SNDWKSP_ENVELOPE_OFFS		:= $80			; offset into envelope or -1 for no envelope
SNDWKSP_ENV_STEPREPEAT		:= $88			; step length, b7=repeat flag
SNDWKSP_SYNC_FLAG		:= $90
SNDWKSP_SYNC_HOLD_PARAM		:= $98
SNDWKSP_PITCH_SETTING		:= $A0
SNDWKSP_PITCH_DEV		:= $A8
SNDWKSP_SAMPLE_NO		:= $B0

SNDWKSP_SYNC_CHANS		:= $B8
SNDWKSP_AMP_STEP		:= $B9
SNDWKSP_AMP_TARGET		:= $BA
SNDWKSP_SYNC_HOLD_COUNT		:= $BB
SNDWKSP_WS_0			:= $BC
SNDWKSP_FREQ_LO			:= $BD
SNDWKSP_FREQ_HI			:= $BE
SNDWKSP_WS_3			:= $BF
SNDWKSP_DEF_SAM			:= $C0			; table of default sample numbers per channel 0..31|$80
SNDWKSP_VAR_END			:= $C8


SNDBUF_BUF_0		:=	$00			; sound buffers 21 bytes per channel


SCRATCH_TMP		:=	$80			; 128 bytes of scratch space for the current
							; command - do not use in service routines


; Blitter mk.2/3 CMOS chip locations

DEV_BLTUTIL_CMOS_EEPROM		= $A0	; device number for CMOS/EEPROM
	; the MOS and FIRMWARE PAGES are split into two halves, 0..7F for rom set 0, 80..FF for set 1
BLTUTIL_CMOS_PAGE_MOS	 	= $10	; page in CMOS / Flash EEPROM for Ersatz MOS config
BLTUTIL_CMOS_PAGE_FIRMWARE 	= $11	; page in CMOS / Flash EEPROM for BLTUTIL's config

BLTUTIL_CMOS_FW_ROM_THROT	= $00	; offset to per-rom-throttle arranged as map 0 0..7, map 0 8..15, map 1 0..7, map 1 8..15
BLTUTIL_CMOS_FW_CPU_THROT   	= $04   ; offset to two bytes for map 0,1
CMOSBITS_CPU_THROT		= $80	
