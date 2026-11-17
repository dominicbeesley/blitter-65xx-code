	include "oslib.inc"
	include "mosrom.inc"
	include "hardware.inc"
	include "defs.inc"

	global handle_nat_cop
	global handle_emu_cop
	global handle_nat_irq
	global callmos

	global zp_emu_sp
	global zp_nat_sp	



	section zpage,"adrwz"


		global   TRAMPO_NAT2EMU
		global   TRAMPO_EMU2NAT

TRAMPOLINES 	ezp	0x8A
TRAMPO_NAT2EMU	ezp	TRAMPOLINES
TRAMPO_EMU2NAT	ezp	TRAMPOLINES+3

zp_tmpLEN	reserve	2
zp_tmpPTR	reserve	2
zp_emu_sp	reserve  1
zp_nat_sp	reserve  2

	section text.startup

enter:		jmp	main

	section .text
main:


		a8
		x8

		; TODO: do this properly
		ldx	#<BLTURBOSTR
		ldy	#>BLTURBOSTR
		jsr	OSCLI

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
		tax
		inx
		stx	gbpb_blk+5		; count to transfer
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

		; close the file
		lda	#0
		ldy	gbpb_blk+0
		jsr	OSFIND

		; now set up the trampolines in ZP
		ldx	#TRAMPOLINES_LENGTH
.tlp:		lda	trampolines_data-1,X
		sta	TRAMPOLINES-1,X
		dex
		bne	.tlp

		; now set up hardware vectors in bank 0 - boot mode at 00 8F Ex..FF and again at 00 FFE0..FF
		; note: we can't use far addressing here as we're poking to bank 0 that gets remapped in emu mode
		ldx	#0x20			; length
		lda	#0
		sta	fred_JIM_PAGE_HI
.tlp2:		lda	hw_vectors_data-1,X
		ldy	#0x8F
		sty	fred_JIM_PAGE_LO
		ldy	#0xFF
		sty	fred_JIM_PAGE_LO
		sta	JIM+0xE0-1,X
		dex
		bne	.tlp2
		
		; now set up hardware handlers in bank 0
		lda	#0
		sta	fred_JIM_PAGE_HI
		lda	#0x8C
		sta	fred_JIM_PAGE_LO

		lda	#<_nat_wksp_start
		sta	zp_tmpPTR
		lda	#>_nat_wksp_start
		sta	zp_tmpPTR+1

		lda	#<_nat_wksp_len
		sta	zp_tmpLEN
		lda	#>_nat_wksp_len
		sta	zp_tmpLEN+1

		ldy	#0
.tlp3:		lda	(zp_tmpPTR),Y
		sta	JIM,Y
		iny
		bne	.np1
		inc	fred_JIM_PAGE_LO
		inc	zp_tmpPTR+1
.np1:		dec	zp_tmpLEN
		bne	.tlp3
		dec	zp_tmpLEN+1
		bpl	.tlp3

		; set correct boot mode
		lda	sheila_MEM_CTL
		and	#0xCF
		ora	#0x30
		sta	sheila_MEM_CTL

		; get to native mode and continue from native workspace

		sei				; disable interrupts over switch

		; RTI address of enter_cont1
		phk
		pea	enter_cont1
		php

		jmp	TRAMPO_EMU2NAT		; enter program

		section	.nat_wksp_text, "acrx"

enter_cont1:
		a8
		x8
		tsx
		stx	<zp_emu_sp

		rep	#$30
		a16
		x16

		; TODO figure a better stack to use or how to share with MOS
		lda	#NAT_STACK_TOP-1
		tcs

		phk				; program bank 0
		pea	enter_cont2-1		; return from program address
		
		; push the starting flags and run address to the stack
		lda	>$ff0000+osfile_blk+7
		pha
		lda	>$ff0000+osfile_blk+5
		and	#$FF00			; flag=0 interrupts enabled when program started TODO: what should it be?
		pha
				
		rti


enter_cont2:	; main program has exited - tidy up and return to 8-bit MOS
		
		;TODO preserve registers?

		phk
		phk
		phk
		plb
		pld

		; setup emu stack
		sep	#$30
		a8
		x8
		lda	#1
		xba
		lda	zp_emu_sp
		tcs
		pea	exit_ext
		php
		sei			; disable interrupts over switch

		jmp	TRAMPO_NAT2EMU

		section .text
		a8
		x8
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; exit_ext - this is where the program will return to


exit_ext:

		pla	
		sta	fred_JIM_PAGE_LO
		pla
		sta	fred_JIM_PAGE_HI
		pla
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO

		cli

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



hw_emu_cop:	jmp	handle_emu_cop
hw_emu_abort:	rti



	;;;;;;;;;;;;;;;;;;;;;;; This gets copied to 00 8Cxx on
		section	.nat_wksp_text, "acrx"
hw_nat_cop:	jml	handle_nat_cop
hw_nat_brk:	jmp 	*
hw_nat_abort:	jmp 	*
hw_nat_nmi:	jmp 	*
hw_nat_irq:	jml 	handle_nat_irq
		rti



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
	

		; the jump table copied into the native vectors area
		; this will be copied to 008FE0-FF - the FA..FF aren't used
hw_vectors_data:
		word	0		; resv
		word	0		; resv
		word	hw_nat_cop	
		word	hw_nat_brk
		word	hw_nat_abort
		word	hw_nat_nmi
		word	0		; resv
		word	hw_nat_irq

		word	0		; resv
		word	0		; resv
		word	hw_emu_cop	
		word	0		; resv
		word	hw_emu_abort
		word	0		; n/a
		word	0		; n/a
		word	0		; n/a


BLTURBOSTR:	byte	"BLTURBO L01", 0x0D



	section .data


	section .bss

	; an 8-bit OSFILE block
osfile_blk:	reserve	18
gbpb_blk:	reserve	13
		global buf
buf:		reserve  256