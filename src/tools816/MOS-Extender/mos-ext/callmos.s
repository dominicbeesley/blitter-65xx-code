		global callmos

		zpage	zp_emu_sp
		zpage	zp_nat_sp

		section	.nat_wksp_text, "acrx"


;		********************************************************************************
;		* callmos - Call down to MOS from native mode                                  *
;		*                                                                              *
;		* Action: The 16-bit address of a MOS API entry point has been pushed pn the   *
;		*         stack - we call "down" to the MOS to this address after entering     *
;		*         emulation mode. The stack is adjusted and we return long to the      *
;		*         The stack is also switched to the emulation mode stack before        *
;		*         and the native mode stack is trimmed ready for a return              *
;		*                                                                              *
;		* On entry: AXYP = parameters to MOS routine                                   *
;		* On exit:  D=preserved, B=0, AXYP as MOS routine exit                         *
;		********************************************************************************
	
callmos:
		php			; push flags _before_ forcing other regs
					; to 16-bits
		phd			; preserve caller D

		sep	#$30
		a8
		x8

		pha			; push 8-bits - irrespective of caller mode
		phx			

		sei			; disable interrupts whilst we swap

		; NAT mode stack is now
		;	+9..10	16-bit MOS routine address
		;	+6..8	RTL from here
		;	+5	caller P
		;	+3..4	caller DP
		;	+2	caller A
		;	+1	caller X

		phk			; direct page to 0 - caller needs to worry about their DP
		phk
		pld

		phk			; bank 0
		plb

		; calculate native mode stack
		lda	#1
		xba
		lda	zp_emu_sp

		rep	#$30
		a16
		x16

		; save native mode stack to restore later
		tsx
		stx	zp_nat_sp	; X is now native stack pointer	
		
		; switch to emu-mode stack
		tcs

		; set continue address on emu stack
		lda	#.callmos_continue-1
		pha
		; copy 16-bit MOS routine addr to emu stack
		lda 	9,X
		pha
		sep	#$20
		a8
		; copy P,A to emu stack
		lda 	5,X
		pha
		lda 	2,X
		pha
		rep	#$20
		a16
		; copy X,rubbish to emu stack
		lda	0,X
		pha

		; lose a byte from stack then restore B=0
		plb
		phk
		plb

		; EMU stack should now contain
		;	+6..7	RTS address of our exit
		;	+4..5	RTI address of MOS routine
		;	+3	RTI flags
		;	+2	caller A
		;	+1	caller X

		; NAT mode stack is now
		;	+9..10	16-bit MOS routine address
		;	+6..8	RTL from here
		;	+5	caller P
		;	+3..4	caller DP
		;	+2	caller A
		;	+1	caller X
	
		; move RTL,P,DP address up on native mode stack
		lda	7,X
		sta	9,X
		lda	5,X
		sta	7,X
		lda	3,X
		sta	5,X

		; NAT mode stack is now
		;	+8..10	RTL from here
		;	+7	caller P
		;	+5..6	caller DP
		;	+1..4	spare


		; back to 8 bits
		sep	#$30
		a8
		x8

		plx
		pla
		jmp	TRAMPO_NAT2EMU

		section	.text


.callmos_continue
		; we've returned from a MOS call, still in emu mode
		sei

		php
		pha
		phx		

		; push an RTI
		phk
		pea	.callmos_continue2
		php
		jmp	TRAMPO_EMU2NAT

		section	.nat_wksp_text, "acrx"

		;we're now back in native mode jump back to caller
.callmos_continue2
		
		;we're still a8, x8 
		a8
		x8
		
		tsx
		stx	zp_emu_sp

		; switch to NAT caller's stack
		lda	zp_nat_sp+1
		xba
		lda	zp_nat_sp
		tcs

		; native stack is
		;	+8..10	RTL from here
		;	+7	caller P
		;	+5..6	caller DP
		;	+1..4	spare

		; merge caller's P and MOS return P, keep X/M/I bits of caller
		lda	$103,X		; mos P
		eor	7,S
		and	#$34
		eor	$103,X
		sta	7,S

		lda	$101,X
		sta	3,S
		lda	$102,X
		sta	4,S

		; reset emu mode stack
		inc	zp_emu_sp
		inc	zp_emu_sp
		inc	zp_emu_sp
		
		; native stack is
		;	+8..10	RTL from here
		;	+7	caller P
		;	+5..6	caller DP
		;	4	A
		;	3	X
		;	1..2	spare

		; return to original callmos caller
		plx
		plx
		plx
		pla
		pld
		plp
		rtl
		