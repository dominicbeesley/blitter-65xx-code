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

		.include	"common.inc"
		.include	"hardware.inc"
		.include	"blit_int.inc"

		.export		_blit_ctl_full
		.export		_blit_ctl_full_updE
		.export		_blit_ctl_full_noExec
		.importzp	ZP_BLIT_PTR


		.code
;===============================================
; blit_ctl_full
;
; On entry:
;	XY => full blitter register block (33 bytes)
;	The first 32 bytes should mirror the registers
;	of the blitter
;	byte 0 should contain the BLITCON_EXEC_* flags
;	byte 33 should contain the BLITCON_ACT_ flags
; On exit:
;	A,X,Y => destroyed
; runs the blit

_blit_ctl_full:

		DMAC_ENTER
		jsr	blit_ctl_full_noExec_int
		stx	jim_DMAC_DMA_DEST_ADDR + 2	; reset dmac to base of 
		sta	jim_DMAC_DMA_CTL		; and again for final byte to bltcon
		DMAC_EXIT
		rts


;===============================================
; blit_ctl_full
;
; On entry:
;	XY => full blitter register block (33 bytes)
;	The first 32 bytes should mirror the registers
;	of the blitter
;	byte 0 should contain the BLITCON_EXEC_* flags
;	byte 33 should contain the BLITCON_ACT_ flags
; On exit:
;	A,X,Y => destroyed
; runs the blit

_blit_ctl_full_noExec:
		DMAC_ENTER
		jsr	blit_ctl_full_noExec_int
		DMAC_EXIT
		rts
		
blit_ctl_full_noExec_int:
		lda	#blit_dma_channel
		sta	jim_DMAC_DMA_SEL
		stx	jim_DMAC_DMA_SRC_ADDR + 2
		sty	jim_DMAC_DMA_SRC_ADDR + 1
		ldx	#$FF
		stx	jim_DMAC_DMA_SRC_ADDR
		inx
		stx	jim_DMAC_DMA_COUNT
		ldx	#31
		stx	jim_DMAC_DMA_COUNT + 1
		ldx	#>jim_page_DMAC				; this address is in physical not cpu space!
		stx	jim_DMAC_DMA_DEST_ADDR + 0
		ldx	#<jim_page_DMAC
		stx	jim_DMAC_DMA_DEST_ADDR + 1
		ldx	#<jim_DMAC_BLITCON
		stx	jim_DMAC_DMA_DEST_ADDR + 2
		lda	#DMACTL_ACT + DMACTL_HALT + DMACTL_STEP_DEST_UP + DMACTL_STEP_SRC_UP
		sta	jim_DMAC_DMA_CTL

		rts


;===============================================
; blit_ctl_full_updE
;
; On entry:
;	XY => full blitter register block (33 bytes)
;	The first 32 bytes should mirror the registers
;	of the blitter
;	byte 0 should contain the BLITCON_EXEC_* flags
;	byte 33 should contain the BLITCON_ACT_ flags
;	the E address will be updated from the blitter
;	registers after the execute
; On exit:
;	A,X,Y => destroyed
; runs the blit

_blit_ctl_full_updE:
		DMAC_ENTER
		stx	ZP_BLIT_PTR
		sty	ZP_BLIT_PTR + 1

		jsr	blit_ctl_full_noExec_int
		stx	jim_DMAC_DMA_DEST_ADDR + 2	; reset dmac to base of 
		sta	jim_DMAC_DMA_CTL		; and again for final byte to bltcon

		ldy	#DMAC_ADDR_E_offs
		ldx	#3
@lp:		lda	jim_DMAC,Y
		sta	(ZP_BLIT_PTR),Y
		iny
		dex
		bne	@lp
		DMAC_EXIT
		rts


		.END
