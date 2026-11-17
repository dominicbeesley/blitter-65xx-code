		.include "cop.inc"

		.include "oslib.inc"

		.import buf
		.import callmos

; TODO: this has a different API - BHA is the pointer instead of 0YX, Y contains the reason code!
;	********************************************************************************
;	* COP 07 - OPOSW = OSWORD                                                      *
;	*                                                                              *
;	* Action: This call caries out various operations, the specific operation      *
;	* depending on the contents of A on entry. BHA points to a control block in    *
;	* memory, and this block contains data for the call, and will contain results  *
;	* from the call.                                                               *
;	* On entry:                                                                    *
;	* 	 BHA points to a control block in memory                              *
;	* Y contains the reason code. The reason code determines the function of the   *
;	* call.                                                                        *
;	* On exit: D preserved                                                         *
;	*                                                                              *
;	* For OPOSW with Y = 0 (read line from input)                                  *
;	* Y = line length (including CR if applicable).                                *
;	* If C = 0 then CR termimated input.                                           *
;	* If C = 1 then ESCAPE terminated input                                        *
;	********************************************************************************
;
;	OSWORD exceptions/notes
;
;	OSWORD 0
;	========
;	This will call the 8-bit OSWORD direct. The 16-bit pointer to the 
;	buffer will be in the 8-bit MOS-address space and so maps to bank FF
;	or if in the shared 00 0000 - 00 0FFF block it will still be useable
;
;	It is preferred to use the update OPRDLIN API to read a line of text
;	using 32 bit addressing

		.segment	"NATHANDLER"

OSWORDBUF := $FF0000 + buf

		.export	COP_07
COP_07:		
		sep	#$30
		.a8
		.i8
		tya
		tax
		bpl	@low		
		lda	[DPCOP_BHA]		; get length from block+0
		tay		
		bra	@go		
@low:		phk
		plb
		ldy	WordLengthsArgs,X
		cpx	#$15
		bcc	@go
		ldy	#16

@go:		; X is function code
		; Y is length of arguments in block
		; copy arguments to buf that is MOS-visible

		; force B to bank FF
		lda	#$FF
		pha
		plb
		bra	@cpyent

@cpy:		dey
		lda	[DPCOP_BHA],Y
		sta	OSWORDBUF,Y
@cpyent:		cpy	#0
		bne	@cpy

		pea	OSWORD
		txa
		ldx	#<buf
		ldy	#>buf
		jsl	callmos
		php
		phy	; we return Y/Cy for OSWORD 0

		;; assume registers small here!?
		.a8
		.i8
		
		; get back reson code
		ldx	DPCOP_Y
		bpl	@low2
		ldy	#1
		lda	[DPCOP_BHA],Y		; get length from block+1
		tay		
		bra	@go2		
@low2:		phk
		plb
		ldy	WordLengthsReturn,X
		cpx	#$15
		bcc	@go2
		ldy	#16
		
@go2:		; X is function code
		; Y is length of arguments in block
		; copy arguments to buf that is MOS-visible
		lda	#$FF
		pha
		plb
		bra	@cpyent2

@cpy2:		dey
		lda	OSWORDBUF,Y
		sta	[DPCOP_BHA],Y
@cpyent2:		cpy	#0
		bne	@cpy2

		; TODO: This returns Y/P for all OSWORDS not just OSWORD 0

		ply
		sty	DPCOP_Y
		stz	DPCOP_Y+1

		; merge caller's P and MOS return P, keep X/M/I bits of caller
		lda	1,S		; P
		eor	DPCOP_P
		and	#$34
		eor	1,S	
		sta	DPCOP_P
		pla			; discard

		rtl			; return to cop dispatcher


; OSWORD control block lengths

WordLengthsArgs:
		.byte	$05
		.byte	$00
		.byte	$05
		.byte	$00
		.byte	$05
		.byte	$04
		.byte	$05
		.byte	$08
		.byte	$0E
		.byte	$04
		.byte	$01
		.byte	$01
		.byte	$05
		.byte	$00
		.byte	$08
		.byte	$20
		.byte	$10
		.byte	$0D
		.byte	$00
		.byte	$04
		.byte	$80
WordLengthsReturn:
		.byte	$00
		.byte	$05
		.byte	$00
		.byte	$05
		.byte	$00
		.byte	$05
		.byte	$00
		.byte	$00
		.byte	$00
		.byte	$05
		.byte	$09
		.byte	$05
		.byte	$00
		.byte	$08
		.byte	$19
		.byte	$00
		.byte	$01
		.byte	$0D
		.byte	$80
		.byte	$04
		.byte	$80