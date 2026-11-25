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

	.global _rle_ptr
	.global _rle_load_loop
	.global _rle_read
	.global _rle_len

	.section "text","acrx"

	.a16
	.x16

_rle_mem_write:
	php
	sep	#$20
	.a8
	sta     [<r0]
	inc	_rle_ptr		; assume doesn't straddle bank!
	bne	.s
	inc	_rle_ptr+1
.s:	plp
	rts


	.a16
	.x16
_rle_load_loop:
	; TODO: check rle_len >= 0
	ldx     _rle_ptr
	stx	<r0
	ldx     _rle_ptr+2
	stx	<r0+2
.again:	
	; get command byte
	jsl	_rle_read
	cmp	#256
	bcs	.out		; treat anything >= 256 as bad
	bit	#$80		; check for CMD>=128
	bne	.literal

	; we have a run length
	sta	<r4		; save run length
	jsr	.declen
	php
	; read byte 
	jsl	_rle_read	; assume its worked
.lp:	jsr	_rle_mem_write
	dec	<r4
	bpl	.lp
	plp
	bcs	.again
	rtl

.literal:
	; we have a literal run
	and	#$7F
	sta	<r4
	jsr	.declen
	php
.lp2:	jsl	_rle_read
	jsr	_rle_mem_write
	dec	<r4
	bpl	.lp2
	plp
	bcs	.again

.out:	rtl


.declen:; subtract cmd+1 from len
	.a16
	lda	_rle_len
	clc
	sbc	<r4
	sta	_rle_len
	lda	_rle_len+2
	sbc	#0
	sta	_rle_len+2
	rts
.endproc




;;;	while(rle_len > 0) {
;;;		rle_cmd = rle_read();
;;;		if (rle_cmd < 0)
;;;			goto eof;
;;;		if (rle_cmd & 128) {
;;;			//literal
;;;			rle_cmd = rle_cmd & 127;
;;;			while (rle_cmd-- >= 0)
;;;			{
;;;				rle_val = rle_read();
;;;				if (rle_val < 0)
;;;					goto eof;
;;;				rle_mem_write(rle_val);
;;;			}
;;;			rle_len -= rle_cmd + 1;
;;;		} else {
;;;			rle_val = rle_read();
;;;			if (rle_val < 0)
;;;				goto eof;
;;;			while (rle_cmd-- >= 0) {
;;;				rle_mem_write(rle_val);
;;;			}			
;;;			rle_len -= rle_cmd + 1;
;;;		}
;;;	}
;;;