; COP.S - this file contains the handler to translate the
; native mode COP API into the emu mode MOS API

	.include "oslib.inc"
	.include "oslib-nat.inc"

	.export handle_nat_cop
	.export handle_emu_cop
	.import callmos
	.import COP_07
	.import COP_06


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
		.faraddr	COP_NotImpl	;A	BGET
		.faraddr	COP_NotImpl	;B	BPUT
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
