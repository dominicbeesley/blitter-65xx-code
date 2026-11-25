; 
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


;
; Screen maths adapted from C DB 2020-05-13
;
	.setcpu		"6502"
	.smart		on
	.autoimport	on
	.case		on
	.debuginfo	off
	.importzp	sp, sreg, regsave, regbank
	.importzp	tmp1, tmp2, tmp3, tmp4, ptr1, ptr2, ptr3, ptr4
	.macpack	longbranch
	.export		_XY_to_dma_scr_adr

	.include	"adv_globals.inc"

; ---------------------------------------------------------------
; unsigned long __near__ XY_to_dma_scr_adr (int, int)
; ---------------------------------------------------------------

.segment	"CODE"

.proc	_XY_to_dma_scr_adr: near

.segment	"CODE"

;
; unsigned long XY_to_dma_scr_adr(int x, int y) {
;
;
	pha			; save A for later
	stx     ptr2+1	
	and     #$F8	

	asl     A	
	rol     ptr2+1	
	asl     A	
	rol     ptr2+1	
	asl     A	
	rol     ptr2+1	
	asl     A	
	rol     ptr2+1	
	sta     ptr2	
	ldx     ptr2+1  	; ptr2 is now (y&FFF8) * $10

	stx     ptr1+1	
	asl     A	
	rol     ptr1+1	
	asl     A	
	rol     ptr1+1	
	sta     ptr1		; ptr1 is now (y&FFF8) * $40

	clc
	pla
	and     #7	
	adc     ptr2	
	sta     ptr2	
	lda     ptr2+1	
	adc     #0	
	sta     ptr2+1	
	clc
	lda     ptr1	
	adc     ptr2	
	sta     ptr2	
	lda     ptr2+1	
	adc     ptr1+1	
	sta     ptr2+1		; ptr2 is now y&7 + (y&FFF8) * $50

	ldy     #1
	lda     (sp),y
	sta     ptr1+1	
	dey
	lda     (sp),y
	and     #$FE	
	asl     A	
	rol     ptr1+1	
	asl     A	
	rol     ptr1+1	

	clc
	adc     ptr2	
	pha
	lda     ptr2+1	
	adc     ptr1+1	
	sta     ptr2+1		; add (x&0xFFFE)<<2

	lda     #.bankbyte(DMA_SCR_SHADOW)
	sta     sreg
	lda     #0	
	sta     sreg+1	
	pla
	ldx     ptr2+1	

	jmp     incsp2		; restore stack

.endproc

