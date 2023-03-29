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

		.import		blit_rd_bloc_be
		.import		blit_rd_bloc_be16
		.import		blit_rd_bloc_be24
		.import		blit_rd_bloc_be32
		.import		blit_rd_bloc
		.importzp	ZP_BLIT_PTR
		.importzp	ZP_BLIT_TMP
		.export		_blit_plot_masked


		.CODE

;===============================================
; blit_plot_masked
;
; On entry:
;	XY => 
;		+0	dest addr lo
;		+1	dest addr hi
;		+2	dest addr bank
;		+3	src addr lo
;		+4	src addr hi
;		+5	src addr bank
;		+6	src mask addr lo
;		+7	src mask addr hi
;		+8	src mask addr bank
;		+9	shift
;		+10	height - 1
;		+11	width - 1
;		+12	dest_stride
;		+14	src_stride
;		+16	mask_stride
;		+17	BLTCON

; On exit:
;	A,X,Y => destroyed
; runs the blit
_blit_plot_masked:
		DMAC_ENTER
		stx	ZP_BLIT_PTR
		sty	ZP_BLIT_PTR + 1
		lda	#$CA				; copy B to D, mask A, C	FUNCGEN
		sta	jim_DMAC_FUNCGEN
		ldy	#0
		ldx	#DMAC_ADDR_D_offs + 2
		jsr	blit_rd_bloc_be24		; dest addr D
		ldy	#0
		jsr	blit_rd_bloc_be24		; dest addr C
		jsr	blit_rd_bloc_be24		; src addr B
		dex					; skip data B
		jsr	blit_rd_bloc_be24		; mask addr A
		jsr	blit_rd_bloc
		and	#$0F
		sta	ZP_BLIT_TMP
		asl
		asl
		asl
		asl
		ora	ZP_BLIT_TMP
		sta	jim_DMAC_SHIFT
		ldx	#DMAC_HEIGHT_offs
		jsr	blit_rd_bloc_be16		; plot height, width
		ldx	#DMAC_STRIDE_D_offs +1		; stride D
		jsr	blit_rd_bloc_be16
		dey
		dey
		jsr	blit_rd_bloc_be16		; stride C
		jsr	blit_rd_bloc_be32		; stride B, A

		lda	#$0F
		sta	jim_DMAC_BLITCON
		jsr	blit_rd_bloc			; BLITCON ACT
		sta	jim_DMAC_BLITCON		; exec
@sk2:		DMAC_EXIT
		rts


		.END
