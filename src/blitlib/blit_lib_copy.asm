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


		.import		blit_rd_bloc_be24
		.import		blit_rd_bloc_be16
		.import		blit_rd_bloc
		.importzp	ZP_BLIT_PTR
		.export		_blit_copy



		.CODE

;===============================================
; blit_copy
;
; On entry:
;	XY => 
;		+0	src addr lo
;		+1	src addr hi
;		+2	src addr bank
;		+3	dest addr lo
;		+4	dest addr hi
;		+5	dest addr bank
;		+6	length-1 lo
;		+7	length-1 hi
; On exit:
;	A,X,Y => destroyed
; runs the blit
_blit_copy:
		DMAC_ENTER
		stx	ZP_BLIT_PTR
		sty	ZP_BLIT_PTR + 1

		lda	#blit_dma_channel
		sta	jim_DMAC_DMA_SEL

		ldy	#6
		ldx	#DMAC_DMA_COUNT_offs + 1
		jsr	blit_rd_bloc_be16
		ldy	#3
		jsr	blit_rd_bloc_be24
		ldy	#0
		jsr	blit_rd_bloc_be24
		lda	#DMACTL_ACT + DMACTL_HALT + DMACTL_STEP_DEST_UP + DMACTL_STEP_SRC_UP
		sta	jim_DMAC_DMA_CTL
		DMAC_EXIT
@sk2:		rts


		.END
