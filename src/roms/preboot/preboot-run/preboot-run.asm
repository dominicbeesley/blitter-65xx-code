; MIT License
; 
; Copyright (c) 2025 Dossytronics
; https://github.com/dominicbeesley/blitter-vhdl-6502
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

		.include 	"c20k-hardware.inc"
		.include 	"hardware.inc"
		.include		"preboot.inc"
		.include		"oslib.inc"



	.segment "ZPEXT": zeropage

zp_txtptr:	.res	2

	.bss

	.rodata

	.code

		jsr	PrintI
		.asciiz	"...booting..."


		; force to map 0 mosram
		lda	sheila_MEM_TURBO2
		ora	#BITS_MEM_TURBO2_MAP0N1
		sta	sheila_MEM_TURBO2
		lda	sheila_MEM_CTL
		ora	#BITS_MEM_CTL_SWMOS
		sta	sheila_MEM_CTL

		lda	#$FF
		sta	JIM_DEVNO_BLITTER		; make sure JIM is deselected

		lda	sheila_MEM_TURBO2
		and	#<~BITS_MEM_TURBO2_PREBOOT
		sta	sheila_MEM_TURBO2
		jmp	($FFFC)

PrintI:		pha
		txa
		pha
		tya
		pha
		tsx

		lda	$104,X
		sta	zp_txtptr
		lda	$105,X
		sta	zp_txtptr+1
		lda	#0
@lp:		iny
		lda	(zp_txtptr),Y
		beq	@s
		jsr	OSASCI
		jmp	@lp
@s:		clc
		tya
		adc	zp_txtptr
		sta	$104,X
		lda	#0
		adc	zp_txtptr+1
		sta	$105,X

		pla
		tay
		pla
		tax
		pla

		rts

