		.include "cop.inc"

		.include "oslib.inc"

		.import buf
		.import callmos

; ********************************************************************************
; * COP 07 - OPOSW - OSWORD                                                      *
; *                                                                              *
; * Action: Call the 8-bit MOS OSWORD. The operation depends on the reason       *
; * code in Y. The control block is copied to MOS memory, OSWORD is called       *
; * and the results are copied back. The block layouts are those of the          *
; * 8-bit MOS (no handle field).                                                 *
; *                                                                              *
; * On entry: X:A = pointer to the control block                                 *
; *           Y   = reason code (8 bits)                                         *
; * On exit:  block updated with the results                                     *
; *           For Y = 0 (read line): Y = line length (including CR),             *
; *           C = 1 if Escape ended the input                                    *
; *                                                                              *
; * Note (OSWORD 0): the buffer address inside the block is a 16-bit MOS         *
; * address (bank FF, or the shared 00 0000-00 0FFF area). A replacement         *
; * read-line call with a 32-bit buffer is planned (OPRDLN).                     *
; ********************************************************************************
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
		.proc COP_07:far
		; we swap to .i8 here but if we change that then mask
		; Y AND #$00FF to ensure 8-bit reason

		sep	#$30
		.a8
		.i8
		tya
		tax
		bpl	@low		
		lda	[DPCOP_XHA]		; get length from block+0
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
		lda	[DPCOP_XHA],Y
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
		lda	[DPCOP_XHA],Y		; get length from block+1
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
		sta	[DPCOP_XHA],Y
@cpyent2:		cpy	#0
		bne	@cpy2

		ply
		lda	DPCOP_Y
		bne	@not0
		sty	DPCOP_Y
		stz	DPCOP_Y+1

		; merge caller's P and MOS return P, keep X/M/I bits of caller
		lda	1,S		; P
		eor	DPCOP_P
		and	#$34
		eor	1,S	
		sta	DPCOP_P
@not0:		pla			; discard pushed P

		rtl			; return to cop dispatcher
		.endproc

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