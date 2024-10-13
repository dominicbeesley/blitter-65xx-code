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

		.export	BounceErrorOffStack
		.export	Print2Spc
		.export PrintCommaSpace
		.export	PrintSpc
		.export	PrintA
		.export	PrintNL
		.export	PrintHexA
		.export	PrintHexNybA
		.export PrintDecA
		.export PrintDec
		.export	PrintHexXY
		.export	PrintMsgXYThenHexNyb
		.export	PrintXY
		.export	PrintXY16
		.export	PrintXYT
		.export	PrintXYT16
		.export	PrintPTR
		.export PrintAtPtrPtrY16
		.export PrintAtPtrPtrY
		.export	PrintPTRT
		.export PrintImmedT
		.export PrintImmedT16
		.export PrintXSpc
		.export	PromptYN
		.export	PromptNo
		.export	PromptYes
		.export	PromptRTS
		.export	WaitKey
		.export PrintBytesAndK
		.export PrintSizeK

		.export SkipSpacesPTR
		.export ToUpper
		.export parseONOFF
		.export parseONOFF_ck
		.export parseONOFF_ON
		.export ParseHex
		.export ParseHexLp
		.export ParseHexShAd
		.export ParseHexAlpha
		.export ParseHexErr
		.export ParseHexDone
		.export zeroAcc
		.export asl4Acc
		.export addAAcc
		.export div10Acc
		.export isAcc0
		.export	PushAcc
		.export PopAcc
		.export StackAllocX
		.export StackFree	
		.export crc16
		.export crc16_lp
		.export crc16_cl

		.export inkey_clear
		.export ackEscape
		.export CheckESC

		.export brkBadCommand
		.export brkInvalidArgument

		.export bitX
;
; -----------------------------
; Generate a sideways ROM error in ADDR_ERRBUF *stack or other space*
; -----------------------------
BounceErrorOffStack:
		lda	#0
		sta	fred_JIM_DEVNO			; deselect JIM in case caller does something horrible
		pla
		sta	zp_tmp_ptr
		pla
		sta	zp_tmp_ptr + 1
		ldy	#0				; store brk
		sty	ADDR_ERRBUF + 0
		; get byte _after_ jsr (jsr pushes ret-1)
@1:		iny
		lda	(zp_tmp_ptr),Y		
		sta	ADDR_ERRBUF, Y
		bne	@1
		jsr	jimReleaseDev_err		; restore device state
		jmp	ADDR_ERRBUF			; execute BRK from buffer



;------------------------------------------------------------------------------
; Printing
;------------------------------------------------------------------------------
PrintCommaSpace:lda	#','
		jsr	PrintA
		jmp	PrintSpc
Print2Spc:	jsr	PrintSpc
PrintSpc:	lda	#' '
PrintA:		jmp	OSASCI
PrintNL:	jmp	OSNEWL

PrintXSpc:	lda	#' '
		cpx	#0
		beq	@r
@l:		jsr	PrintA
		dex
		bne	@l
@r:		rts


PrintHexA:	pha
		lsr	a
		lsr	a
		lsr	a
		lsr	a
		jsr	PrintHexNybA
		pla
		pha
		jsr	PrintHexNybA
		pla
		rts
PrintHexNybA:	and	#$0F
		cmp	#10
		bcc	@1
		adc	#'A'-'9'-2
@1:		adc	#'0'
		jsr	PrintA
		rts

PrintHexXY:	pha
		tya
		jsr	PrintHexA
		txa
		jsr	PrintHexA
		pla
		rts

PrintDecA:	jsr	zeroAcc
		sta	zp_trans_acc

PrintDec:	; acc is number to print (destroyed)
		; zp_trans_tmp+0,+1 destroyed
		lda	#0
		sta	zp_trans_tmp+1		
@l1:		jsr	div10Acc
		lda	zp_trans_tmp
		pha
		inc	zp_trans_tmp+1
		jsr	isAcc0
		bne	@l1
@l2:		pla
		jsr	PrintHexNybA
		dec	zp_trans_tmp+1
		bne	@l2
		rts


PrintMsgXYThenHexNyb:
		pha
		jsr	PrintXY
		pla
		jsr	PrintHexNybA
		jmp	PrintNL


PrintImmedT16:
		pha
		txa
		pha
		tya
		pha

		jsr	PrintNL

		lda	zp_tmp_ptr
		pha
		lda	zp_tmp_ptr+1
		pha

		tsx
		lda	$106, X
		sta	zp_tmp_ptr
		lda	$107, X
		sta	zp_tmp_ptr + 1
		ldy	#1
		jsr	PrintPTRT
		tya
		pha
@l:		cpy	#17
		bcs	@s
		jsr	PrintSpc
		iny
		bne	@l
@s:		pla
		tay
		jmp	exImmedT




PrintImmedT:
		pha
		txa
		pha
		tya
		pha
		lda	zp_tmp_ptr
		pha
		lda	zp_tmp_ptr+1
		pha

		tsx
		lda	$106, X
		sta	zp_tmp_ptr
		lda	$107, X
		sta	zp_tmp_ptr + 1
		ldy	#1
		jsr	PrintPTRT

exImmedT:	clc
		dey			; we started with Y=1!
		tya
		adc	zp_tmp_ptr
		sta	$106,X
		bcc	@s1
		inc	$107,X
@s1:		pla
		sta	zp_tmp_ptr + 1
		pla
		sta	zp_tmp_ptr
		pla
		tay
		pla
		tax
		pla
		rts

; print the string pointed to by (zp_tmp_ptr),Y
; preserves all regs and flags, saves string length in zp_tmp_ptr+3

PrintAtPtrPtrY16:
		php
		clc
		bcc	PrintAtPtrPtrY_int

PrintAtPtrPtrY:
		php
		sec				; indicate normal (not 16 col)
PrintAtPtrPtrY_int:		

		pha
		tya
		pha
		txa
		pha
		lda	(zp_tmp_ptr),Y
		tax
		stx	zp_tmp_ptr+3		; save start of string
		iny
		lda	(zp_tmp_ptr),Y
		tay
		beq	@nos			; invalid pointer, skip
		jsr	PrintXY_int
@nos:		txa
		sec
		sbc	zp_tmp_ptr+3		; length of string
		sta	zp_tmp_ptr+3
		pla
		tax
		pla
		tay
		pla
		plp
		rts



PrintXY16:
		clc
		bcc	PrintXY_int	

		; zero terminated string at XY
PrintXY:	sec

PrintXY_int:
		lda	zp_tmp_ptr
		pha
		lda	zp_tmp_ptr+1
		pha

		stx	zp_tmp_ptr
		sty	zp_tmp_ptr + 1
		ldy	#0

		php
		jsr	PrintPTR
		tya
		plp
		bcs	@no16
		pha
@l:		cpy	#16
		bcs	@s
		jsr	PrintSpc
		iny
		bne	@l
@s:		pla		
@no16:		clc
		adc	zp_tmp_ptr
		tax
		lda	#0
		adc	zp_tmp_ptr+1
		tay

		pla
		sta	zp_tmp_ptr+1
		pla
		sta	zp_tmp_ptr
		rts

	; returns length of string in Y 
PrintPTRT:
@lp:		lda	(zp_tmp_ptr),Y
		php
		iny
		and	#$7F
		jsr	OSASCI
		plp
		bpl	@lp		
@out:		rts


	; returns length of string + 1 in Y (i.e. counts zero terminator)
PrintPTR:
@lp:		lda	(zp_tmp_ptr),Y
		iny
		cmp	#0
		beq	@out
		jsr	OSASCI
		cpy	#0
		bne	@lp
@out:		rts

bitSEV:		.byte 	$FF

PrintXYT16:	bit	bitSEV
		bvs	PrintXYT_int
		; to-bit terminated string at XY
PrintXYT:	clv
PrintXYT_int:	lda	zp_tmp_ptr
		pha
		lda	zp_tmp_ptr+1
		pha

		stx	zp_tmp_ptr
		sty	zp_tmp_ptr + 1
		ldy	#0
		php
		jsr	PrintPTRT
		plp
		bvc	@s

		; pad to 16
		tya
		pha
@l:		cpy	#16
		bcs	@s2
		jsr	PrintSpc
		iny
		bne	@l
@s2:		pla
		tay
@s:		clc
		tya
		adc	zp_tmp_ptr
		tax
		lda	#0
		adc	zp_tmp_ptr+1
		tay

		pla
		sta	zp_tmp_ptr+1
		pla
		sta	zp_tmp_ptr
		rts

PrintBytesAndK:
		jsr	PushAcc

		jsr	PrintDec

		jsr	PrintSpc

		jsr	PopAcc

		jsr	PrintSizeK

		jmp	OSNEWL


PrintSizeK:
		; print free space in Kbytes
		; divide by 256
		lda	zp_trans_acc+1
		sta	zp_trans_acc+0
		lda	zp_trans_acc+2
		sta	zp_trans_acc+1
		lsr	zp_trans_acc+1
		ror	zp_trans_acc
		lsr	zp_trans_acc+1
		ror	zp_trans_acc
		lda	#0			; assume max of 16384k
		sta	zp_trans_acc+2
		sta	zp_trans_acc+3

		jsr	PrintDec

		lda	#'k'
		jmp	OSWRCH



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


;------------------------------------------------------------------------------
; Parsing
;------------------------------------------------------------------------------
SkipSpacesPTR:	lda	(zp_mos_txtptr),Y
		iny
		beq	@s
		cmp	#' '
		beq	SkipSpacesPTR
@s:		dey
		rts

ToUpper:	cmp	#'a'
		bcc	@1
		cmp	#'z'+1
		bcs	@1
		and	#$DF
@1:		rts

parseONOFF:	jsr	SkipSpacesPTR
		lda	(zp_mos_txtptr),Y
		jsr	ToUpper
		cmp	#'O'
		bne	ParseHexErr
		iny
		lda	(zp_mos_txtptr),Y
		jsr	ToUpper
		cmp	#'N'
		beq	parseONOFF_ON
		cmp	#'F'
		bne	ParseHexErr
		iny
		lda	(zp_mos_txtptr),Y
		jsr	ToUpper
		cmp	#'F'
		bne	ParseHexErr
		lda	#0
parseONOFF_ck:						; check for space or &D
		pha
		iny
		lda	(zp_mos_txtptr),Y
		cmp	#' '+1
		bcs	ParseHexErr		
		clc
		pla
		rts
parseONOFF_ON:	lda	#$FF
		bne	parseONOFF_ck


ParseHex:
		pha
		txa
		pha
		ldx	#$FF				; indicates first char
		jsr	zeroAcc
		jsr	SkipSpacesPTR
		cmp	#$D
		beq	ParseHexErr
ParseHexLp:	lda	(zp_mos_txtptr),Y
		iny
		jsr	ToUpper
		cmp	#'0'
		bcc	ParseHexErr
		cmp	#'9'+1
		bcs	ParseHexAlpha
		sec
		sbc	#'0'
ParseHexShAd:	inx
		jsr	asl4Acc				; multiply existing number by 16
		jsr	addAAcc				; add current digit
		jmp	ParseHexLp
ParseHexAlpha:	cmp	#'A'
		bcc	ParseHexErr
		cmp	#'F'+1
		bcs	ParseHexErr
		sbc	#'A'-11				; note carry clear 'A'-'F' => 10-15
		jmp	ParseHexShAd
ParseHexErr:	inx
		bne	ParseHexDone
		sec
		pla
		tax
		pla
		rts
ParseHexDone:	dey
		pla
		tax
		pla
		clc
		rts

;------------------------------------------------------------------------------
; Stackery
;------------------------------------------------------------------------------

		; reserves X bytes on the stack and returns pointer in XY
		; no bounds checking
StackAllocX:	pha
		txa					; number of bytes to allocate
		eor	#$FF				; -(N+1)
		pha

		; stack
		;	+ 4	RETH
		;	+ 3	RETL
		;	+ 2	A
		;	+ 1	-(N+1)

		tsx
		sec
		txa
		tay					; Y points at base of current stack
		adc	$101,X				; A should now be S-N (Cy set)
		tax
		txs					; move stack down

		; stack
		;	N + 4	RETH
		;	N + 3	RETL
		;	N + 2	A
		;	N + 1	-(N+1)
		; Y=>	N + 0	N bytes spare
		;		...
		; X,SP=>  + 1

		lda	$102, Y
		sta	$101, X				; saved A
		lda	$103, Y				
		sta	$102, X				; RETL
		lda	$104, Y				
		sta	$103, X				; RETH
		lda	$101, Y
		sta	$104, X				; -(N+1)
		txa
		clc
		adc	#5
		tax
		ldy	#$01				; XY points now at allocated block (hopefully)

		; stack 
		;	 N	rest of stack...
		; 	+ 4	-(N+1)
		; 	+ 3	RETH
		;	+ 2	RETL
		; SP=>	+ 1	A

		pla


		; stack on exit
		;	 N	rest of stack...
		; 	+ 3	-(N+1)
		; 	+ 2	RETH
		; SP=>	+ 1	RETL

		rts

		; free a block alloc'd with StackAllocX, stack should contain return address
		; followed by the -(N+1) number placed there by StackAllocX
StackFree:	pha
		txa
		pha
		tya
		pha


		; stack contents
		;	+7	N bytes of stuff
		;	+6	-(N+1)
		;	+5	RETH
		;	+4	RETL
		;	+3	A
		;	+2	X
		;	+1	Y

		tsx
		txa
		tay			; A=X=Y=S

		; copy current stack up N+1 bytes and reset

		sec
		eor	#$FF		; -(S+1)
		adc	$106, X		; -(S+1) + -(N+1) + 1 = -S + -N - 1
		eor	#$FF		; -(-S + -N - 1 + 1) = S+N
		
		tax
		inx			; one more for good luck (we actually reserved an extra byte for length)
		lda	$105,Y
		sta	$105,X
		lda	$104,Y
		sta	$104,X
		lda	$103,Y
		sta	$103,X
		lda	$102,Y
		sta	$102,X
		lda	$101,Y
		sta	$101,X

		txs
		pla
		tay
		pla
		tax
		pla
		rts




;------------------------------------------------------------------------------
; Arith
;------------------------------------------------------------------------------
zeroAcc:	pha
		lda	#0
		sta	zp_trans_acc
		sta	zp_trans_acc + 1
		sta	zp_trans_acc + 2
		sta	zp_trans_acc + 3
		pla
		rts

asl4Acc:
		pha
		txa
		pha
		ldx	#4
@1:		asl	zp_trans_acc + 0
		rol	zp_trans_acc + 1
		rol	zp_trans_acc + 2
		rol	zp_trans_acc + 3
		dex
		bne	@1
		pla
		tax
		pla
		rts

addAAcc:
		pha
		clc
		adc	zp_trans_acc + 0
		sta	zp_trans_acc + 0
		bcc	@1
		inc	zp_trans_acc + 1
		bne	@1
		inc	zp_trans_acc + 2
		bne	@1
		inc	zp_trans_acc + 3
@1:		pla
		rts


		; found at http://nparker.llx.com/a2/mult.html

div10Acc:
		lda	#0      	;Initialize REM to 0
        	sta	zp_trans_tmp
        	ldx	#32     	;There are 32 bits in NUM1
@l1:      	asl	zp_trans_acc   	;Shift hi bit of NUM1 into REM
        	rol	zp_trans_acc+1 	;(vacating the lo bit, which will be used for the quotient)
        	rol	zp_trans_acc+2
        	rol	zp_trans_acc+3
        	rol	zp_trans_tmp
        	lda	zp_trans_tmp
        	sec		        ;Trial subtraction
        	sbc	#10
        	bcc	@l2      	;Did subtraction succeed?
        	sta	zp_trans_tmp
        	inc	zp_trans_acc   	;and record a 1 in the quotient
@l2:      	dex	        	
		bne	@l1
        	rts

isAcc0:		lda	zp_trans_acc
		ora	zp_trans_acc+1
		ora	zp_trans_acc+2
		ora	zp_trans_acc+3
@s1:		rts

PushAcc:	pha
		pha
		pha
		pha
		pha
		txa
		pha
		; stack contains
		;	+8	RETH
		;	+7	RETL
		;	+6	spare
		;	+5	spare
		;	+4	spare
		;	+3	spare
		;	+2	A
		;	+1	X
		tsx
		lda	$107,X
		sta	$103,X
		lda	$108,X
		sta	$104,X
		; stack contains
		;	+8	RETH
		;	+7	RETL
		;	+6	spare
		;	+5	spare
		;	+4	RETH
		;	+3	RETL
		;	+2	A
		;	+1	X

		lda	zp_trans_acc+0
		sta	$105,X
		lda	zp_trans_acc+1
		sta	$106,X
		lda	zp_trans_acc+2
		sta	$107,X
		lda	zp_trans_acc+3
		sta	$108,X

		; stack contains
		;	+8	zp_trans_acc+3	
		;	+7	zp_trans_acc+2	
		;	+6	zp_trans_acc+1	
		;	+5	zp_trans_acc+0	
		;	+4	RETH
		;	+3	RETL
		;	+2	A
		;	+1	X
		pla
		tax
		pla
		rts

PopAcc:		pha
		tax
		pha

		; stack contains
		;	+8	zp_trans_acc+3	
		;	+7	zp_trans_acc+2	
		;	+6	zp_trans_acc+1
		;	+5	zp_trans_acc+0	
		;	+4	RETH
		;	+3	RETL
		;	+2	A
		;	+1	X

		tsx
		lda	$105,X
		sta	zp_trans_acc+0
		lda	$106,X
		sta	zp_trans_acc+1
		lda	$107,X
		sta	zp_trans_acc+2
		lda	$108,X
		sta	zp_trans_acc+3

		lda	$102,X
		sta	$106,X
		lda	$103,X
		sta	$107,X
		lda	$104,X
		sta	$108,X

		; stack contains
		;	+8	RETH
		;	+7	RETL
		;	+6	A
		;	+5	zp_trans_acc+0	
		;	+4	?
		;	+3	?
		;	+2	?
		;	+1	X

		pla
		tax
		pla
		pla
		pla
		pla
		pla
		rts


;X;addAtXAcc	pshs	D
;X;		ldd	2,X
;X;		addd	zp_trans_acc + 2
;X;		std	zp_trans_acc + 2
;X;		ldd	0,x
;X;		adcb	zp_trans_acc + 1
;X;		adca	zp_trans_acc + 0
;X;		std	zp_trans_acc + 0
;X;		puls	D,PC
;X;
;X;subAtXAcc	pshs	D
;X;		ldd	zp_trans_acc + 2
;X;		subd	2,X
;X;		std	zp_trans_acc + 2
;X;		ldd	zp_trans_acc + 0
;X;		sbcb	1,X
;X;		sbca	0,x
;X;		std	zp_trans_acc + 0
;X;		puls	D,PC


POLYH    	:= $10
POLYL   	:= $21

		; update CRC at zp_trans_acc with byte in A
crc16:		pha
		txa
		pha
		tsx
		lda	$102,X
		eor	zp_trans_acc+1
		ldx	#8          
crc16_lp:	asl	zp_trans_acc
		rol	A
		bcc	crc16_cl
		tay
		lda	zp_trans_acc
		eor	#POLYL
		sta	zp_trans_acc
		tya
		eor	#POLYH
crc16_cl:	dex
		bne 	crc16_lp
		sta	zp_trans_acc+1
		pla
		tax
		pla
		rts



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
		cpy	#27
		bne	@s
		jmp	ackEscape
@s:		pla
		tay
		pla
		rts

CheckESC:	bit	zp_mos_ESC_flag			; TODO - system call for this?
		bpl	ceRTS
ackEscape:	ldx	#$FF
		lda	#OSBYTE_126_ESCAPE_ACK
		jsr	OSBYTE
brkEscape:	M_ERROR
		.byte	17, "Escape",0
ceRTS:		rts


brkBadCommand:	M_ERROR
		.byte	$FE, "Bad Command", 0
brkInvalidArgument:
		M_ERROR
		.byte	$7F, "Invalid Argument", 0


bitX:		; bit A of A is set to 1, return X=0
		tax
		inx
		lda	#0
		sec
@lp:		rol	A
		dex
		bne	@lp
		rts


		.SEGMENT "RODATA"
str_YN:			.byte	" (Y/N)?",0
strNo:			.byte	"No", $D, 0
strYes:			.byte	"Yes", $D, 0
