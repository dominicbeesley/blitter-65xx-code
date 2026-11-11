; COP.S - this file contains the handler to translate the
; native mode COP API into the emu mode MOS API

	include cop.inc
	include "oslib.inc"

	global handle_nat_cop
	global handle_emu_cop
	global callmos

;==================================================================
; EMU mode code
;==================================================================

		section .text
handle_emu_cop:	rti


		section	.nat_handler_text, "acrx"
handle_nat_cop:	plp
		php                   ;reestablish interrupts
		rep   #$38
		a16
		x16
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
		inc	A
		inc	A
		tcd				; point DP at Stacked registers

		dec	DPCOP_PC        	;decrement 16 bit return pointer to point at the signature byte
		lda	[DPCOP_PC]      	;get signature byte
		asl	A               	;multiply by 2 to get index
		clc
		adc	[DPCOP_PC]
		and	#$00ff          	;mask off whatever we fetched in high byte
		cmp	#tblCopDispatchLen	;compare to end of cop table
		bcs	.ret_unimplemented	;jump forward for high COPs
		tax				;transfer index to X
		phk
		pea	.ret-1
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
		and	#$FF00
		pha
		plb
		php
		lda	DPCOP_AH		;restore A from stack
		rti
		
.ret:		rep   #$30
		a16
		x16
		tsc
		inc	A
		inc	A
		tcd				; point DP at Stacked registers
	; internal API Change cop handlers must set DPCOP_P explicitly
	; TODO: use V as error flag here !?
;;		php
;;		ror	DPCOP_P
;;		plp
;;		rol	DPCOP_P			; get returned Cy into flags
		rts

		a16
		x16
.ret_unimplemented:
		stz	DPCOP_X			;clear saved X
		lda	#$41
		tsb	DPCOP_P			;return error/V/Cy
		bra	.ret

tblCOPDispatch:	addr	COP_00		;OPWRC 	00 = OSWRCH
tblCopDispatchLen equ *-tblCOPDispatch


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