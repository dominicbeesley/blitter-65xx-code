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

		.export		blit_rd_bloc_be
		.export		blit_rd_bloc_be16
		.export		blit_rd_bloc_be24
		.export		blit_rd_bloc_be32
		.export		blit_rd_bloc
		.importzp	ZP_BLIT_PTR

		.CODE
		

; read an address and convert endianness

blit_rd_bloc:
		lda	(ZP_BLIT_PTR),Y
		iny
		rts
blit_rd_bloc_be32:
		jsr	blit_rd_bloc_be
blit_rd_bloc_be24:
		jsr	blit_rd_bloc_be
blit_rd_bloc_be16:
		jsr	blit_rd_bloc_be
blit_rd_bloc_be:
		jsr	blit_rd_bloc
		sta	jim_DMAC,X
		dex
		rts


		.END
