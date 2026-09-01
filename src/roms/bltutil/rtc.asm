; MIT License
; 
; Copyright (c) 2026 Dossytronics
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
		.include "hazel.inc"

		.include "bltutil.inc"


		.export rtc_OSWORD_READ
		.export cmdTIME

		; The RTC on the blitter / C20k has a different order to that on the master

		; indeces of RTC i2c registers

OS99_DATA_OFFS  =	6

RTCIX_BASE	=	4
RTCIX_SEC	= 	4
RTCIX_MIN	=	5
RTCIX_HOUR	=	6
RTCIX_DATE	=	7
RTCIX_DOW	=	8
RTCIX_MONTH	=	9
RTCIX_YEAR	=	10

		; indeces of OSWORD block offsets

OSWIX_SEC	= 	13
OSWIX_MIN	=	12
OSWIX_HOUR	=	11
OSWIX_DATE	=	9	; not swap order
OSWIX_DOW	=	10	; not swap
OSWIX_MONTH	=	8
OSWIX_YEAR	=	7


tbloffs:	.byte	OSWIX_SEC
		.byte	OSWIX_MIN
		.byte	OSWIX_HOUR
		.byte	OSWIX_DOW
		.byte	OSWIX_DATE
		.byte	OSWIX_MONTH
		.byte   OSWIX_YEAR


	.struct ClockStringFormat
		ddd	.res 3
			.res 1                      ;','
		nn      .res 2
			.res 1                      ;' '
		mmm     .res 3
			.res 1                      ;' '
		yyyy    .res 4
			.res 1                      ;'.'
		hh	.res 2
			.res 1                      ;':'
		mm      .res 2
			.res 1                      ;':'
		ss	.res 2
		cr      .res 1                      ;'\n'
	.endstruct



rtc_OSWORD_READ:
		ldy	#0
		lda	(zp_mos_OSBW_X),Y
		pha
		eor	#2
		beq	@s
		jmp	readclock
@s:

		; Convert given time to string. Fill out the RTC temp
		; data with the info from the parameter block, then
		; pass on to the common code.
		ldx	#$06
@o2rlp:		lda	tbloffs,X
		tay
		lda	(zp_mos_OSBW_X),Y
		sta	osfile_ctlblk+OS99_DATA_OFFS,X
		dex
		bpl	@o2rlp

		jmp	maybeConvertToString

maybeConvertToString:
		pla                          			;get reason code
		cmp	#1                        
		beq	@s
		jsr 	convertTimeToString                    	;taken if 0 or 2
		jmp	ServiceOutA0

@s:		; copy back from rtc block to osword
		ldx	#06
@r2olp:		lda	tbloffs,X
		tay
		lda	osfile_ctlblk+OS99_DATA_OFFS,X
		sta	(zp_mos_OSBW_X),Y
		dex
		bpl	@r2olp
		jmp	ServiceOutA0                          

convertTimeToString:
		; Store terminating CR.
		ldy	#ClockStringFormat::cr
		lda	#13
		sta	(zp_mos_OSBW_X),y
		ldx	#RTCIX_SEC - RTCIX_BASE
		dey
		jsr	storeRTCDataByteString
		lda	#':'
		sta	(zp_mos_OSBW_X),y
		ldy	#ClockStringFormat::hh+2
		sta	(zp_mos_OSBW_X),y
		ldx	#RTCIX_MIN - RTCIX_BASE
		ldy	#ClockStringFormat::mm+1
		jsr	storeRTCDataByteString
		ldx	#RTCIX_HOUR - RTCIX_BASE
		ldy	#ClockStringFormat::hh+1
		jsr	storeRTCDataByteString
		lda	#'.'
		sta	(zp_mos_OSBW_X),y
		lda	osfile_ctlblk + OS99_DATA_OFFS + RTCIX_DOW - RTCIX_BASE;
		asl	A           
		asl	A           
		ldy	#$00        
		tax             
@l1:		lda	dayOfWeekStrings-4,x     ;-4 as 1=Sunday
		sta	(zp_mos_OSBW_X),y
		inx
		iny
		cpy	#$03
		bcc	@l1
		lda	#','
		sta	(zp_mos_OSBW_X),y
		lda	osfile_ctlblk + OS99_DATA_OFFS + RTCIX_MONTH - RTCIX_BASE
		cmp	#$10
		bcc	@s1
		sbc	#$06    		        ;convert $10, $11 and $12 from BCD
@s1:            sec
		sbc	#1	                       ;make month 0-based
		asl	A
		asl	A
		tax
		ldy	#ClockStringFormat::mmm
@l2:		lda	monthStrings,x
		sta	(zp_mos_OSBW_X),y
		inx
		iny
		cpy	#ClockStringFormat::mmm+3
		bcc	@l2
		ldx	#RTCIX_YEAR - RTCIX_BASE
		ldy	#ClockStringFormat::yyyy+3
		jsr	storeRTCDataByteString
		lda	#$20
		jsr	storeBCDByteString
		lda	#' '
		sta	(zp_mos_OSBW_X),Y
		ldy	#ClockStringFormat::nn+2
		sta	(zp_mos_OSBW_X),Y
		dey
		ldx	#RTCIX_DATE - RTCIX_BASE
storeRTCDataByteString:
		lda	osfile_ctlblk + OS99_DATA_OFFS,X
storeBCDByteString:
		pha
		jsr	storeNybbleString
		pla
		lsr	A
		lsr	A
		lsr	A
		lsr	A
storeNybbleString:
		and	#$0F
		ora	#'0'
		cmp	#'9'+1
		bcc	@s
		adc	#('A'-'9'-1)-1           ;(-1 because C set)
@s:	        sta	(zp_mos_OSBW_X),Y
		dey
		rts

tbli2c_osword_rdclock:
		.byte	7			; + 0 bytes in (for tube?)
		.byte	14			; + 1 bytes out (for tube?)
		.byte	OSWORD_OP_I2C		; + 2 BLTUTIL operation
		.byte	1			; + 3 # bytes to write to i2c (address)
		.byte	7			; + 4 # bytes to read
		.byte	$A3			; + 5 RTC slave read address
		.byte	RTCIX_BASE		; + 6 RTC internal address base of data


		; read clock using OSWORD 99/13
readclock:	ldx	#6
@lp:		lda	tbli2c_osword_rdclock, X
		sta	osfile_ctlblk,X
		dex
		bpl	@lp

		lda	zp_mos_OSBW_X
		pha
		lda	zp_mos_OSBW_Y
		pha

		lda	#OSWORD_BLTUTIL
		ldx	#<osfile_ctlblk
		ldy	#>osfile_ctlblk
		jsr	OSWORD

		pla	
		sta	zp_mos_OSBW_Y
		pla
		sta	zp_mos_OSBW_X
		lda	#OSWORD_RTC_READ
		sta	zp_mos_OSBW_A
		jmp	maybeConvertToString

	

;-------------------------------------------------------------------------

dayOfWeekStrings: 
                .byte "Sun",$01
                .byte "Mon",$02
                .byte "Tue",$03
                .byte "Wed",$04
                .byte "Thu",$05
                .byte "Fri",$06
                .byte "Sat",$07
                
;-------------------------------------------------------------------------

monthStrings:   .byte "Jan",$01
                .byte "Feb",$02
                .byte "Mar",$03
                .byte "Apr",$04
                .byte "May",$05
                .byte "Jun",$06
                .byte "Jul",$07
                .byte "Aug",$08
                .byte "Sep",$09
                .byte "Oct",$10
                .byte "Nov",$11
                .byte "Dec",$12


;-------------------------------------------------------------------------
;
; *TIME [MasRef C.5-12]
; 
cmdTIME:
                lda	#0
                sta	HZ_CMDLINE
                ldx	#<HZ_CMDLINE
                ldy	#>HZ_CMDLINE
                lda	#$0E                     
                jsr	OSWORD                   
                ldx	#256-.sizeof(ClockStringFormat)
L8752:
                lda	HZ_CMDLINE-(256-.sizeof(ClockStringFormat)),x
                jsr	OSASCI                   
                inx                          
                bne	L8752                    
                rts                          
