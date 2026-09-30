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

; This file adapted from Tom Seddon's Master MOS disassembly 
; see https://github.com/tom-seddon/acorn_mos_disassembly/blob/master/src/rtc.s65

		.include "mosrom.inc"	
		.include "oslib.inc"
		.include "hazel.inc"

		.include "bltutil.inc"


		.export rtc_OSWORD_READ
		.export rtc_OSWORD_WRITE
		.export cmdTIME

		; The RTC on the blitter / C20k has a different order to that on the master

		; indeces of RTC i2c registers

OS99_RDATA_OFFS =	6
OS99_WDATA_OFFS =	7

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


;-------------------------------------------------------------------------
;
; OSWORD 14 (&0E) Read CMOS clock [MasRef D.3-22]
; 
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
		sta	osfile_ctlblk+OS99_RDATA_OFFS,X
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
		lda	osfile_ctlblk+OS99_RDATA_OFFS,X
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
		lda	osfile_ctlblk + OS99_RDATA_OFFS + RTCIX_DOW - RTCIX_BASE;
		asl	A           
		asl	A           
		ldy	#$00        
		tax             
@l1:		lda	dayOfWeekStrings-4,x     ;-4 as 0=Sunday
		sta	(zp_mos_OSBW_X),y
		inx
		iny
		cpy	#$03
		bcc	@l1
		lda	#','
		sta	(zp_mos_OSBW_X),y
		lda	osfile_ctlblk + OS99_RDATA_OFFS + RTCIX_MONTH - RTCIX_BASE
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
		lda	osfile_ctlblk + OS99_RDATA_OFFS,X
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

		inc	osfile_ctlblk + OS99_RDATA_OFFS + RTCIX_DOW - RTCIX_BASE	; increment day of week RV-8263 is 0..6 not 1..7

		jmp	maybeConvertToString

	

;-------------------------------------------------------------------------

dayOfWeekStrings: 			;NOTE: this is zero-based not 1-based like the Master
                .byte "Sun",$00
                .byte "Mon",$01
                .byte "Tue",$02
                .byte "Wed",$03
                .byte "Thu",$04
                .byte "Fri",$05
                .byte "Sat",$06
sz_dayOfWeekStrings := * - dayOfWeekStrings
                
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
sz_monthStrings := * - dayOfWeekStrings


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

tbli2c_osword_wrclock:
		.byte	15			; + 0 bytes in (for tube?)
		.byte	15			; + 1 bytes out (for tube?)
		.byte	OSWORD_OP_I2C		; + 2 BLTUTIL operation
		.byte	8			; + 3 # bytes to write to i2c (address+ssmmhhdwddmmyy)
		.byte	0			; + 4 # bytes to read
		.byte	$A3			; + 5 RTC slave read address
		.byte	RTCIX_BASE		; + 6 RTC internal address base of data



; Day string not matched
; ----------------------
nextDayString:
                pla                          	; Drop number of characters matched
                pla                          	; Get offset to string table
                sta	zp_mos_OSBW_A		
                pla
                tay                          	; Get start of supplied string
                lda	zp_mos_OSBW_A
                clc                          	; Step to next string table entry
                adc	#$04
                cmp	#sz_dayOfWeekStrings	; If not checked 28/4=7 entries, keep looking
                bcc	checkDayString
                bcs	exitOSWORDF		; Otherwise exit silently

; Month string not matched
; ------------------------
nextMonthString:
                pla				; Drop number of characters matched
                pla				; Get offset to string table
                sta	zp_mos_OSBW_A		
                pla
                tay                          	; Get start of supplied string
                lda	zp_mos_OSBW_A
                clc                          	; Step to next string table entry
                adc	#$04
                cmp	#sz_monthStrings	; If not checked 48/4=12 entries, keep looking
                bcc	checkMonthString
		bcs	exitOSWORDF		; Otherwise exit silently

FLAGTDPRES	:= zp_mos_INT_A	; use INT_A as a temporary - assume interrupts off
SAVERLEN	:= zp_mos_OS_wksp2 

;-------------------------------------------------------------------------
;
; OSWORD 15 (&0F) Write CMOS clock [MasRef D.3-24]
; 
rtc_OSWORD_WRITE:
		lda	#0
                sta	FLAGTDPRES     		;got no time, got no date
                ldy	#0
                lda	(zp_mos_OSBW_X),Y	; get operation (not length)
                sta	SAVERLEN		; store for later - assume this is safe place [TODO:check OSWORD 99 doesn't blam it]
                eor	#15                     ; len=15, set date
                beq	setDate
                eor	#15^8
                bne	@s
                jmp	setTime
@s:             eor	#(15^8)^23
                beq	setDate
exitOSWORDF:	lda	#OSWORD_RTC_WRITE
		sta	zp_mos_OSBW_A
		jmp	ServiceOutA0		; exit silently

; Set date and set date+time
; --------------------------
; (&F0),1=>"Day,00 Mon 0000"
; (&F0),1=>"Day,00 Mon 0000.00:00:00"
; A=0, Y=0
setDate:
                iny                          	; Point to supplied data
; Translate day string into day number
checkDayString:
		sta	zp_mos_OSBW_A
		tya
                pha                          	; Push pointer to data string                
                lda	zp_mos_OSBW_A
                pha                          	; Push offset to match strings
                tax                          	; X=>match strings
                lda 	#$03                 	; A=3 characters to match
checkDayStringLoop:
                pha				; Save number of characters to match
                lda 	(zp_mos_OSBW_X),Y      	; Get character from string
                eor 	dayOfWeekStrings,X	; Compare with day string table
                and 	#$DF			; Force to upper case
                bne	nextDayString		; No match step to check next entry
                inx				; Step to next character to match
                iny				; Step to next data character
                pla				; Get character count back
                sec
                sbc	#1                     	; Decrement and loop until 3 characters matched
                bne	checkDayStringLoop
                lda	dayOfWeekStrings,X	; Get translation byte from string table
                sta	osfile_ctlblk + OS99_WDATA_OFFS + RTCIX_DOW - RTCIX_BASE
                				; Store it in workspace
; Translates Sun,Mon,Tue,etc to &01,&02,&03,etc
                pla				; Drop char count and table offset
                pla
                lda	(zp_mos_OSBW_X),Y	; Get next character
                cmp	#','                   	; Not followed by a comma, so exit silently
                bne	exitOSWORDF
                ldx	#OS99_WDATA_OFFS + RTCIX_DATE - RTCIX_BASE ; Get day of month
                jsr	readDecimalBCDByte
                bcc	exitOSWORDF             ; Bad number, exit silently
                iny                          	; Get next character
                lda	(zp_mos_OSBW_X),Y
                eor	#' '                    ; Not space, exit silently
                bne	exitOSWORDF
                iny     			; Step to first character of month
; Translate month string into month number
; This could use the same code as the Day translation
checkMonthString:
		sta	zp_mos_OSBW_A
                tya
                pha                          	; Push pointer to data string
		lda	zp_mos_OSBW_A
                pha                          	; Push offset to match strings
                tax                          	; X=>match strings
                lda	#$03			; A=3 characters to match
checkMonthStringLoop:
                pha
                lda	(zp_mos_OSBW_X),Y
                eor	monthStrings,X
                and	#$DF
                bne	nextMonthString
                inx
                iny
                pla
                sec
                sbc	#1
                bne	checkMonthStringLoop
                lda	monthStrings,X
                sta	osfile_ctlblk + OS99_WDATA_OFFS + RTCIX_MONTH - RTCIX_BASE
; Translates Jan,Feb,Mar,etc to &01,&02,&03,etc..&09,&10,&11,&12
                pla                          		; Drop char count and table offset
                pla
                lda	(zp_mos_OSBW_X),Y		; Get next character
                cmp	#' '				; Not followed by space, exit silently
                bne	exitOSWORDF
                ldx	#OS99_WDATA_OFFS + RTCIX_YEAR - RTCIX_BASE
                jsr	readDecimalBCDByte
                bcc	exitOSWORDF                    	; Bad number, exit silently - century is read but ignored!
                jsr	readDecimalBCDByte              ; Get year number
                bcc	exitOSWORDF                     ; Bad number, exit silently
                ror 	FLAGTDPRES     		; got date
                lda	SAVERLEN        		; Get data length
                cmp	#$0F                     	; len=15, jump to just set date
                beq	setRTCDateAndOrTime
; Must be len=24 to set date+time
                iny                          		; Get next character
                lda	(zp_mos_OSBW_X),Y
                cmp	#'.'                     	; If not full stop, exit silently
                bne	exitOSWORDF2

setTime:
                ldx	#OS99_WDATA_OFFS + RTCIX_HOUR - RTCIX_BASE
                jsr	readDecimalBCDByte
                bcc	exitOSWORDF2
                iny        
                lda	(zp_mos_OSBW_X),Y
                cmp	#':'
                bne	exitOSWORDF2
                ldx	#OS99_WDATA_OFFS + RTCIX_MIN - RTCIX_BASE
                jsr	readDecimalBCDByte
                bcc	exitOSWORDF2           
                iny                   
                lda	(zp_mos_OSBW_X),Y
                cmp	#':'
                bne	exitOSWORDF2
                ldx	#OS99_WDATA_OFFS + RTCIX_SEC - RTCIX_BASE
                jsr	readDecimalBCDByte
                bcc	exitOSWORDF2
                lda	#$40
                ora	FLAGTDPRES
                sta	FLAGTDPRES   		;got time
setRTCDateAndOrTime:	

		; copy template
		ldx	#OS99_WDATA_OFFS-1	
@clp:		lda	tbli2c_osword_wrclock, X
		sta	osfile_ctlblk,X
		dex
		bpl	@clp

		lda	#$C0
		bit	FLAGTDPRES
		beq	exitOSWORDF2			; now to do
		lda	#8				; default length
		bvs	@skTimePresent			; got time
		; copy data down in block to align date stuff at from
		ldx	#0
@lp:		lda	osfile_ctlblk + OS99_WDATA_OFFS + RTCIX_DATE - RTCIX_BASE,X
		sta	osfile_ctlblk + OS99_WDATA_OFFS,X
		inx
		cpx	#4				; copy DDDWMMYY down
		bne	@lp
		lda	#RTCIX_DATE
		sta	osfile_ctlblk+OS99_WDATA_OFFS-1	; address to write at
		lda	#5				; bytes to write to RTC (addr+DWDDMMYY)
@skTimePresent:	bit	FLAGTDPRES
		bmi	@skDatePresent
		lda	#4				; bytes to write to RTC (addr+SSMMHH)
@skDatePresent:	sta	osfile_ctlblk + 3		; new send length
		lda	zp_mos_OSBW_X
		pha
		lda	zp_mos_OSBW_Y
		pha

		ldx	#<osfile_ctlblk
		ldy	#>osfile_ctlblk
		lda	#OSWORD_BLTUTIL
		jsr	OSWORD

		pla	
		sta	zp_mos_OSBW_Y
		pla
		sta	zp_mos_OSBW_X
		lda	#OSWORD_RTC_WRITE
		sta	zp_mos_OSBW_A
exitOSWORDF2:	jmp	exitOSWORDF


readDecimalBCDByte:
                jsr	readDecimalDigit
                eor	#$20         			;check for ' '
                beq	@s1        			;taken if leading space - that's fine
                eor	#$20         			;reinstate old value
                bcc	anrts		      		;taken if non-space non-digits
@s1:            sta 	osfile_ctlblk,x
                jsr 	readDecimalDigit
                bcc 	anrts		            	;taken if invalid digit

                ; rotate new digit into place
                asl	osfile_ctlblk,X
                asl	osfile_ctlblk,X
                asl	osfile_ctlblk,X
                asl	osfile_ctlblk,X
                ora	osfile_ctlblk,X
                sta	osfile_ctlblk,X
                sec
anrts:          rts

readDecimalDigit:
                iny
                lda (zp_mos_OSBW_X),Y
                cmp #'9'+1
                bcs notDecimalDigit
                cmp #'0'
                bcc notDecimalDigit
                and #$0F
                rts     

notDecimalDigit:
                clc
                rts
                
