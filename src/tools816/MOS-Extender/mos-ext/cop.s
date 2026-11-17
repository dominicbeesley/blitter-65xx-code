; COP.S - this file contains the handler to translate the
; native mode COP API into the emu mode MOS API

	.include "oslib.inc"
	.include "oslib-nat.inc"

	.export handle_nat_cop
	.export handle_emu_cop
	.import callmos
	.import COP_07
	.import COP_06
	.import buf


	.exportzp DPCOP_Y
	.exportzp DPCOP_X
	.exportzp DPCOP_AH
	.exportzp DPCOP_B
	.exportzp DPCOP_DP
	.exportzp DPCOP_P
	.exportzp DPCOP_PC
	.exportzp DPCOP_K
	.exportzp DPCOP_BHA

DPCOP_Y		:=  1 	; offset of Y in COP entry/exit frame
DPCOP_X		:=  3	; offset of X in COP entry/exit frame
DPCOP_AH	:=  5	; offset of AH in COP entry/exit frame
DPCOP_B		:=  7	; offset of B(ank) in COP entry/exit frame
DPCOP_DP	:=  8	; offset of DP in COP entry/exit frame
DPCOP_P		:= 10	; offset of P in COP entry/exit frame
DPCOP_PC	:= 11	; offset of PC in COP entry/exit frame
DPCOP_K		:= 13	; offset of K (program bank) in COP entry/exit frame
DPCOP_BHA	:=	DPCOP_AH


;==================================================================
; EMU mode code
;==================================================================

		.code
handle_emu_cop:	rti


		.segment	"NATHANDLER"
handle_nat_cop:	plp
		php                   ;reestablish interrupts
		rep   #$38
		.a16
		.i16
		phd                   ;8
		phb                   ;7
		pha                   ;5
		phx                   ;3
		phy                   ;1
	; Stack
	; 	+13	PBR
	;	+11..12	PC
	;	+10	P
	;	+8..9	DP
	;	+7	B
	;	+5..6	A
	;	+3..4	X
	;	+1..2	Y
		jsr	cop_dispatch_int
	; Stack
	; 	+13	PBR
	;	+11..12	PC-1	(dispatch code makes PC ready for an RTL instead of RTI!)
	;	+10	P
	;	+8..9	DP
	;	+7	B
	;	+5..6	A
	;	+3..4	X
	;	+1..2	Y


		ply
		plx
		pla
		plb
		pld
		plp
		rtl

cop_dispatch_int:
		tsc
		inc	a
		inc	a
		tcd				; point DP at Stacked registers

		dec	DPCOP_PC        	;decrement 16 bit return pointer to point at the signature byte
		lda	[DPCOP_PC]      	;get signature byte
		asl	a               	;multiply by 2 to get index
		clc
		adc	[DPCOP_PC]
		and	#$00ff          	;mask off whatever we fetched in high byte
		cmp	#tblCopDispatchLen	;compare to end of cop table
		bcs	@ret_unimplemented	;jump forward for high COPs
		tax				;transfer index to X
		phk
		pea	@ret-1
; The callee stack will now look like this:
; 
; +16   PBR
; +14   PC
; +13   P
; +11   DP
; +10   B
; +8    A
; +6    X
; +4    Y
; +1    FE/B673 - return address of COP dispatcher
; 
; The DP register will point at byte below Y
; 
; +13   PBR
; +11   PC
; +10   P
; +8    DP
; +7    B
; +5    A
; +3    X
; +1    Y
		phk
		plb
		lda	tblCOPDispatch+1,X
		pha
		lda	tblCOPDispatch-1,X

		; restore B
		eor	DPCOP_B
		and	#$00FF
		eor	tblCOPDispatch-1,X
		pha
		plb

		php
		ldx	DPCOP_X			;restore X from stack
		lda	DPCOP_AH		;restore A from stack
		rti

;;;;;;;;;;;;;;;;;;;;;;;;;;;; enter COP_HANDLER ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; The cop_handler will be entered when the RTI is executed
; A cop handler should expect the following register values
;	Reg	Size	Value
;	A 	16	Caller's	
;	X 	16	Caller's	
;	Y 	16	Caller's	
;	DP	16	points at registers on stack - see cop.inc for offsets
;	P	8	The I flag will be as caller, D,M,X clear, CZV unspecified
;	S	16	ready for an RTL 
;
;	DP = S + 5 on entry, this may be used to restore DP if stacking is inconvenient
;
; 	The cop handler may return with DP, register sizes changes and A,X,Y undefined
;
;	B,A,X,Y,DP,P are loaded back from the frame on the stack so to return values
;	to the caller the handler should update these.
		
@ret:		rep   #$30
		.a16
		.i16
		tsc
		inc	a
		inc	a
		tcd				; point DP at Stacked registers
	; internal API Change cop handlers must set DPCOP_P explicitly
	; TODO: use V as error flag here !?
;;		php
;;		ror	DPCOP_P
;;		plp
;;		rol	DPCOP_P			; get returned Cy into flags
		rts

		.a16
		.i16
@ret_unimplemented:
		stz	DPCOP_X			;clear saved X
		lda	#$41
		tsb	DPCOP_P			;return error/V/Cy
		bra	@ret

tblCOPDispatch:	.faraddr	COP_00		;OPWRC 	00 = OSWRCH
		.faraddr	COP_01		;OPWRS 	01 = Write String Immediate
		.faraddr	COP_02		;OPWRA 	02 = Write string at BHA
		.faraddr	COP_03		;OPNLI 	03 = OSNEWL - write CR/LF
		.faraddr	COP_NotImpl	;OPRDC 	04 = OSRDCH - read a char
		.faraddr	COP_NotImpl	;OPCLI 	05 = OPCLI - execute command at BYX [deprecated]
		.faraddr	COP_06		;OPOSB 	06 = OSBYTE
		.faraddr	COP_07		;OPOSW 	07 = OSWORD
		.faraddr	COP_NotImpl	;OPCAV 	08 = Call A Vector **NEW**
		.faraddr	COP_NotImpl	;OPCAV 	08 = Add to Vector **NEW**
		.faraddr	COP_0A		;A	BGET
		.faraddr	COP_0B		;B	BPUT
		.faraddr	COP_NotImpl	;OPFILE 	0C = OSFILE **NEW**
		.faraddr	COP_NotImpl	;D
		.faraddr	COP_NotImpl	;OPCOM 	0E = OPCOM - execute command at BHA
		.faraddr	COP_NotImpl	;F

		.faraddr	COP_NotImpl	;10
		.faraddr	COP_NotImpl	;11
		.faraddr	COP_NotImpl	;12
		.faraddr	COP_NotImpl	;13
		.faraddr	COP_NotImpl	;14
		.faraddr	COP_15		;OPASC = OSASCI - write and expand <CR> to <LF><CR>
		.faraddr	COP_NotImpl	;16
		.faraddr	COP_NotImpl	;17
		.faraddr	COP_NotImpl	;18
		.faraddr	COP_NotImpl	;19
		.faraddr	COP_NotImpl	;1A
		.faraddr	COP_NotImpl	;1B
		.faraddr	COP_NotImpl	;1C
		.faraddr	COP_NotImpl	;1D
		.faraddr	COP_NotImpl	;1E
		.faraddr	COP_NotImpl	;1F

		.faraddr	COP_NotImpl	;20
		.faraddr	COP_NotImpl	;21
		.faraddr	COP_NotImpl	;22
		.faraddr	COP_NotImpl	;23
		.faraddr	COP_NotImpl	;24
		.faraddr	COP_NotImpl	;24
		.faraddr	COP_26		;OPBHA - return address of immediate string in BHA
		.faraddr	COP_27		;OPBHI - return immediate far address in BHA ** NEW
		.faraddr	COP_NotImpl	;28
		.faraddr	COP_NotImpl	;29
		.faraddr	COP_NotImpl	;2A
		.faraddr	COP_NotImpl	;2B
		.faraddr	COP_NotImpl	;2C
		.faraddr	COP_NotImpl	;2D
		.faraddr	COP_NotImpl	;2E
		.faraddr	COP_NotImpl	;OPIIQ - insert interrupt handler

		.faraddr	COP_NotImpl	;OPRIQ - remove interrupt handler
		.faraddr	COP_NotImpl	;OPMIQ - modify interrupt handler
		.faraddr	COP_NotImpl	;OPSUM - do carry-round checksum of memory area
		.faraddr	COP_NotImpl	;33
		.faraddr	COP_NotImpl	;OPMOD - module management functions
		.faraddr	COP_NotImpl	;34
		.faraddr	COP_NotImpl	;36
		.faraddr	COP_NotImpl	;37
		.faraddr	COP_NotImpl	;38
		.faraddr	COP_NotImpl	;39
		.faraddr	COP_NotImpl	;3A
		.faraddr	COP_NotImpl	;3B
		.faraddr	COP_NotImpl	;3C
		.faraddr	COP_NotImpl	;3D
		.faraddr	COP_NotImpl	;3E
		.faraddr	COP_NotImpl	;OPBWV - OS Byte/Word Vector

		.faraddr	COP_NotImpl	;40
		.faraddr	COP_NotImpl	;41
		.faraddr	COP_NotImpl	;42
		.faraddr	COP_NotImpl	;43
		.faraddr	COP_44		;44	OPOPN - OSFIND - open a file
		.faraddr	COP_45		;45	OPCLS - OSFINE - close a file
		.faraddr	COP_NotImpl	;46
		.faraddr	COP_NotImpl	;47
		.faraddr	COP_NotImpl	;48
		.faraddr	COP_NotImpl	;49
		.faraddr	COP_NotImpl	;4A
		.faraddr	COP_NotImpl	;4B
		.faraddr	COP_NotImpl	;4C	OPBGB - OSGBPB get/put block
		.faraddr	COP_NotImpl	;4D
		.faraddr	COP_NotImpl	;4E
		.faraddr	COP_NotImpl	;4F

tblCopDispatchLen = *-tblCOPDispatch


;		********************************************************************************
;		* COP 15 - OPASC - BBC OPASCI                                                  *
;		*                                                                              *
;		* Action: Send the byte in A to the VDU drivers. If the byte is &0D (carriage  *
;		* return) then send &0A, &0D to the VDU drivers (line feed+ carriage return).  *
;		*                                                                              *
;		* On entry: A = character code.                                                *
;		* On exit:  DBAXY preserved                                                    *
;		********************************************************************************
COP_15:		and   #$00ff
		cmp   #$000d
		bne   COP_00
;		********************************************************************************
;		* COP 03 - OSNLI - BBC OSNEWL                                                  *
;		*                                                                              *
;		* Action: Send LF CR to the VDU drivers. Line feed is ASCII 10 (decimal),      *
;		* carriage return is ASCII 13 (decimal).                                       *
;		*                                                                              *
;		* On entry: No requirement                                                     *
;		* On exit:  DBAXY preserved                                                    *
;		********************************************************************************
COP_03:		lda   #$000a
		jsl   COP_00
		lda   #$000d

;		********************************************************************************
;		* COP 00 - OPWRC - Write Char in A                                             *
;		*                                                                              *
;		* Action: Send the byte in A to the VDU drivers.                               *
;		*                                                                              *
;		* On entry: A = character code                                                 *
;		* On exit:  DBAXY preserved                                                    *
;		*                                                                              *
;		********************************************************************************

COP_00:		pea	OSWRCH
		jsl	callmos
		rtl

;		********************************************************************************
;		* COP 01 - OPWRS - write string immediate                                      *
;		*                                                                              *
;		* read characters from bytes following cop, check for 0 and pass on to write   *
;		* character routine                                                            *
;		********************************************************************************
COP_01:		inc	DPCOP_PC
		sep	#$20
		.a8
                lda	[DPCOP_PC]
                sta	DPCOP_AH
                rep	#$20
                .a16
                beq	@ret
                phd
                jsl	COP_00
                pld
                bra	COP_01

@ret:		rtl

;		********************************************************************************
;		* COP 02 - OPWRA - write string at BHA                                         *
;		*                                                                              *
;		* TODO: DOCO: NOTE: This seems to imply that X is set to 0,1 for 0 terminated  *
;		* 2,3 for control terminated string - not in systems manual                    *
;		*                                                                              *
;		********************************************************************************
COP_02:		lda	DPCOP_X         ;get passed X and check is < 2 and use to determine type of terminator
		lsr	a
		cmp	#$0002
		bcc	@skok
		brk	$00

		.byte "COP `OPWRA: invalid termination option",0

@skok:		tax
                ldy	#$0000
@lp:		lda	[DPCOP_AH],y    ;use BHA at 05 as pointer
                and	#$00ff
                beq	@ret            ;check for 0 terminator
                cpx	#$0001
                bne	@sknocc         ;if X<>1 skip forwards
                cmp	#$0020
                bcc	@ret            ;else exit on control character
@sknocc:	cop	COP_00_OPWRC
                iny
                bra   @lp

@ret:		rtl


COP_NotImpl:	sec
		stz	DPCOP_X
		rtl

; ********************************************************************************
; * COP 26 - OPBHA                                                               *
; *                                                                              *
; * returns the immediate string following the COP call as BHA                   *
; ********************************************************************************
                .a16
                .i16
COP_26:	        lda   DPCOP_PC+1
                sta   DPCOP_AH+1
                lda   DPCOP_PC
                inc   A
                sta   DPCOP_AH
; This skips over any string following the cop call
@copExitImmedStr:
		inc  DPCOP_PC
                lda   [DPCOP_PC]
                and   #$00ff
                bne   @copExitImmedStr
                rtl

; ********************************************************************************
; * COP 27 - OPBHI                                                               *
; *                                                                              *
; * returns the immediate far address following the cop call as BHA              *
; ********************************************************************************
                .a16
                .i16
COP_27:	        inc	DPCOP_PC
		lda	[DPCOP_PC]
		sta	DPCOP_AH
		inc	DPCOP_PC
		lda	[DPCOP_PC]
		sta	DPCOP_AH+1
		inc	DPCOP_PC
                rtl

	; this address to be used from native mode
EMUBUF 		:= $FF0000 + buf


; ********************************************************************************
; * COP 44 - OPOPN - open file (or device driver)                                *
; * Action: This call opens a device driver.                                     *
; * On entry: BHA points to the name (with colon). terminated by CR(&0D).        *
; *           Y = &40 for input                                                  *
; *           Y = &80 for output                                                 *
; *           Y = &C0 for update                                                 *
; * On exit:  C = 0 means that the device driver is open and Y = handle.         *
; *           If C= I then the device failed to open, the error code is in X     *
; *           and BHA points to a zeroterminated error message.                  *
; *           D preserved                                                        *
; *                                                                              *
; * This translates to OSFIND                                                    *
; *                                                                              *
; *                                                                              *
; ********************************************************************************

		.a16
		.i16
		.proc	COP_44:far
		; copy filename at BHA to safe emu-mode buffer
		sep	#$30
		.a8
		.i8
		ldy	#0
		ldx	#0
@lp:		lda	[DPCOP_BHA], Y
		sta	f:EMUBUF,X
		cmp	#13
		beq	@s
		iny
		inx
		bne	@lp

@s:		lda	DPCOP_Y
		beq	@ign			;ignore Y=0
		ldx	#<buf
		ldy	#>buf
		pea	OSFIND
		jsl	callmos

		cmp	#0
		bne	@clcretA

		cop	COP_26_OPBHA
		.byte	"File not opened", 0
		phb
		plx
		stx	DPCOP_B
		rep	#$30
		.a16
		.i16
		sta	DPCOP_AH
		; return error
		lda	#1
		sta	DPCOP_X
		ror	DPCOP_P
		sec
		rol	DPCOP_P
		rtl


@clcretA:	.a8
		.i8
		sta	DPCOP_Y
		stz	DPCOP_Y+1
		lda	DPCOP_P
		and	#$FE
		sta	DPCOP_P
@ign:		rtl

	.endproc



; ********************************************************************************
; * COP 45 - OPCLS - close device driver                                         *
; * Action: This call closes a device driver which has been opened using OPOPN.  *
; *                                                                              *
; * On entry: Y = handle allocated by OPOPN.                                     *
; * On exit:  If C = 0 then driver is closed.                                    *
; *           If C = 1 then the driver close failed, X = error code and BHA      *
; *           points to a zero-terminated error message.                         *
; *           D preserved                                                        *
; ********************************************************************************

		.a16
		.i16
		.proc COP_45:far

		lda	#0
		pea	OSFIND
		jsl	callmos

		; I don't think it can fail?

		lda	DPCOP_P
		and	#$FFFE
		sta	DPCOP_P
		
		rtl

		.endproc

; ********************************************************************************
; * COP 0A - OPBGT - BGET                                                        *
; *                                                                              *
; * Action: Read one byte from an open device or file. The channel must          *
; * previously have been opened using OPOPN.                                     *
; *                                                                              *
; * On entry: Y contains the handle from OPOPN.                                  *
; * On exit:  A contains the byte read from the file.                            *
; *           if C = I then an error (EOF) has occurred, and A is invalid.       *
; *           No registers preserved                                             *
; ********************************************************************************

		.a16
		.i16
		.proc COP_0A:far

		pea	OSBGET
		jsl	callmos
		sep	#$20
		.a8
		sta	DPCOP_AH
		php
		ror	DPCOP_P
		plp
		rol	DPCOP_P
		
		rtl

		.endproc

; ********************************************************************************
; * COP 0B - OPBPT - BPUT                                                        *
; *                                                                              *
; * Action: Write one byte to an open file or device. The channel must           *
; * previously have been opened using OPOPN.                                     *
; *                                                                              *
; * On entry: Y contains the file handle from OPOPN.                             *
; *           A contains the byte to be written.                                 *
; * On exit:  No registers preserved                                             *
; ********************************************************************************

		.a16
		.i16
		.proc COP_0B:far

		pea	OSBPUT
		jsl	callmos
		
		; assume success?

		rtl

		.endproc
