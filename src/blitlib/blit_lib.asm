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
		.include	"mosrom.inc"

		.exportzp	ZP_BLIT_PTR
		.exportzp	ZP_BLIT_TMP

		.export		blit_jimdevsel
		.export		blit_jimdevrel

		.ZEROPAGE
ZP_BLIT_PTR:	.RES 2
ZP_BLIT_TMP:	.RES 1
ZP_BLIT_OLDJIM:	.RES 1
		.CODE
		

blit_jimdevsel:
		lda	zp_mos_jimdevsave
		sta	ZP_BLIT_OLDJIM
		lda	#JIM_DEVNO_BLITTER
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO
		lda	#<jim_page_DMAC
		sta	fred_JIM_PAGE_LO
		lda	#>jim_page_DMAC
		sta	fred_JIM_PAGE_HI
		rts
blit_jimdevrel:
		lda	ZP_BLIT_OLDJIM
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO
		rts

		.END
