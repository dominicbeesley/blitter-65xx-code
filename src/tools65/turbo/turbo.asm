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


; (c) Dossytronics 2017
; test harness ROM for VHDL testbench for MEMC mk2
; makes a 4k ROM

		.include 	"oslib.inc"
		.include	"common.inc"
		.include	"hardware.inc"
		.include	"mosrom.inc"


		.ZEROPAGE
zp_ptr:		.res	2
		.BSS
orgstack:	.res	1	; original stack pointer
		.CODE
		
;==============================================================================
; M A I N
;==============================================================================

		; save original stack pointer for exit
		tsx
		stx	orgstack

		sei

		; enable JIM
		lda	#JIM_DEVNO_BLITTER
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO

		; set pages 00 to 5F as fast and copy current contents to JIM

		ldx	#0
		stx	zp_ptr

		stx	fred_JIM_PAGE_HI		; all in bottom 64 k of SRAM

page_loop:	stx	zp_ptr+1
		stx	fred_JIM_PAGE_LO

		ldy	#0
@l1:		lda	(zp_ptr),Y
		sta	JIM,Y
		iny
		bne	@l1

		inx
		cpx	#$60
		bne	page_loop

		lda	#$3F
		sta	sheila_MEM_LOMEMTURBO

		cli
		rts


