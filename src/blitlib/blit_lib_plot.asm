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

		.import		blit_rd_bloc_le8
		.import		blit_rd_bloc_le16
		.import		blit_rd_bloc_le24
		.import		blit_rd_bloc_le32
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
		sta	jim_CS_BLIT_FUNCGEN
		ldy	#0
		ldx	#CS_BLIT_ADDR_C_offs
		jsr	blit_rd_bloc_le24		; dest addr C/D
		ldx	#CS_BLIT_ADDR_B_offs
		jsr	blit_rd_bloc_le24		; src addr B
		ldx	#CS_BLIT_ADDR_A_offs
		jsr	blit_rd_bloc_le24		; mask addr A
		jsr	blit_rd_bloc
		sta	jim_CS_BLIT_SHIFT_A		; shift A/B
		ldx	#CS_BLIT_HEIGHT_offs
		jsr	blit_rd_bloc_le8		; plot height
		ldx	#CS_BLIT_WIDTH_offs
		jsr	blit_rd_bloc_le8		; plot width
		ldx	#CS_BLIT_STRIDE_C_offs		; stride C/D
		jsr	blit_rd_bloc_le16
		ldx	#CS_BLIT_STRIDE_B_offs		; stride B
		jsr	blit_rd_bloc_le16
		ldx	#CS_BLIT_STRIDE_A_offs		; stride A
		jsr	blit_rd_bloc_le16

		lda	#$0F
		sta	jim_CS_BLIT_BLITCON
		jsr	blit_rd_bloc			; BLITCON ACT
		sta	jim_CS_BLIT_BLITCON		; exec
@sk2:		DMAC_EXIT
		rts


		.END
