	include "oslib.inc"
	include "mosrom.inc"
	include "hardware.inc"


	section zpage,"adrwz"

TRAMPOLINES 	ezp	0x80
TRAMPO_NAT2EMU	ezp	TRAMPOLINES
TRAMPO_EMU2NAT	ezp	TRAMPOLINES+3

	section text.startup

enter:		jmp	main

	section .text
main:


		a8
		x8

		lda	#0		
		inc	A
		beq	brkNo65816			; will branch on a NMOS

		xba					; H = 1
		dec					; A = something else
		xba					; A = 1, H = something else
		inc
		cmp	#2				; if XBA is a nop A=1 here
		beq	go816

brkNo65816:	brk	#0xFD
		asciiz	"I am not running on a 65816!"

go816:		lda	zp_mos_jimdevsave
		pha
		lda	#0xD1				; TODO: get from constant
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO
		eor	fred_JIM_DEVNO
		eor	#0xFF
		beq	.ok

		brk	#0xFE
		asciiz  "No Blitter"
.ok:

		lda	fred_JIM_PAGE_HI
		pha
		lda	fred_JIM_PAGE_LO
		pha

		; we assume a single filename here and that the
		; load and exec addresses are set

		; scan command line for module name
		lda	#OSARGS_cmdtail
		ldy	#0
		ldx	#zp_mos_txtptr
		jsr	OSARGS

		lda	zp_mos_txtptr+1
		sta	osfile_blk+1
		pha
		lda	zp_mos_txtptr
		sta	osfile_blk
		pha
			
		lda	#OSFILE_CAT
		ldx	#<osfile_blk
		ldy	#>osfile_blk
		jsr	OSFILE

		bne	fnd

brkFileNotFound:
		brk	#0xFF
		asciiz	"File not found"

fnd:		
		;; TODO - sanity check the addresses in osfile_blk
		; check against: low limit (10000?)
		; check against: heap bottom

		; open the file 

		pla
		tax
		pla
		tay
		lda	#OSFIND_OPENIN
		jsr	OSFIND
		sta	gbpb_blk+0
		beq	brkFileNotFound

		jsr	PrintHexA

		; use buffer and JIM to load program

		; setup JIM page
		lda	osfile_blk+3
		sta	fred_JIM_PAGE_LO
		lda	osfile_blk+4
		sta	fred_JIM_PAGE_HI

.tloop:		
		; transfer addr
		ldx	#<buf
		stx	gbpb_blk+1
		ldx	#>buf
		stx	gbpb_blk+2
		ldx	#0xFF
		stx	gbpb_blk+3
		stx	gbpb_blk+4

		; length
		ldx	#0
		stx	gbpb_blk+5
		stx	gbpb_blk+7
		stx	gbpb_blk+8
		inx
		stx	gbpb_blk+6

		; do read
		lda	#OSGBPB_READ_NOPTR
		ldx	#<gbpb_blk
		ldy	#>gbpb_blk
		jsr	OSGBPB
		php				; save Cy for EOF later
		
		ldx	gbpb_blk+6
		bne	.done

		; transfer up thru JIM
		lda	gbpb_blk+5		; number of bytes _not_ transferred by GBPB
		eor	#0xFF	
		sta	gbpb_blk+5		; count to transfer
		ldy	osfile_blk+2		; LSB of hi memory pointer
		ldx	#0
.ll1		lda	buf,X
		sta	JIM,Y
		inx
		iny
		bne	.s1
		inc	fred_JIM_PAGE_LO
		bne	.s1
		inc	fred_JIM_PAGE_HI
.s1:		cpx	gbpb_blk+5
		bne	.ll1
		sty	osfile_blk+2


.done:		plp
		bcc	.tloop

		; now set up the trampolines in ZP
		ldx	#TRAMPOLINES_LENGTH
.tlp:		lda	trampolines_data-1,X
		sta	TRAMPOLINES-1,X
		dex
		bne	.tlp

		

		; push the starting flags and run address to the stack
		lda	osfile_blk+8
		pha
		lda	osfile_blk+7
		pha
		lda	osfile_blk+6
		pha
		lda	#0b00000000		; interrupts enabled when program started TODO: what should it be?
		pha
		
		jmp	TRAMPO_EMU2NAT		; enter program



		pla	
		sta	fred_JIM_PAGE_LO
		pla
		sta	fred_JIM_PAGE_HI
		pla
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO

		rts

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
		bcc	.1
		adc	#'A'-'9'-2
.1:		adc	#'0'
		jmp	OSWRCH


	section .rodata
		; test instructions are copied top 008A..008F and used as "shared trampoline data"
trampolines_data:		
		; three byte drop back to emu mode with rti'd address and flags
		sec
		xce
		rti

		; three byteop to nat mode with rti'd address and flags
		clc
		xce
		rti
TRAMPOLINES_LENGTH equ *-trampolines_data


	section .data


	section .bss

	; an 8-bit OSFILE block
osfile_blk:	reserve	18
gbpb_blk:	reserve	13
buf:		reserve  256