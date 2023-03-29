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

	.import _rle_ptr
	.export _rle_mem_write
	.export _rle_load_loop
	.import _rle_read
	.import _rle_len

	.importzp sreg

.proc	_rle_mem_write: near
	ldx     _rle_ptr
	sta     $FD00,x
	inx
	stx	_rle_ptr
	bne     @s1
	inc     $FCFE
	bne     @s1
	inc     $FCFD
@s1:	rts

.endproc

	.data
rle_tmp_ctr: .res 1

.proc	_rle_load_loop
	; check rle_len >= 0
@again:	;lda	_rle_len
	;bmi	@out
	;ora	_rle_len+1
	;ora	_rle_len+2
	;ora	_rle_len+3
	;beq	@out

	; get command byte
	ldx	#0
	jsr	_rle_read
	cpx	#0
	bne	@out		; treat anything > 256 as bad
	ora	#0		; check for CMD>=128
	bmi	@literal

	; we have a run length
	sta	rle_tmp_ctr	; save run length
	jsr	@declen
	php
	; read byte 
	jsr	_rle_read	; assume its worked
@lp:	jsr	_rle_mem_write
	dec	rle_tmp_ctr
	bpl	@lp
	plp
	bcs	@again
	rts

@literal:
	; we have a literal run
	and	#$7F
	sta	rle_tmp_ctr
	jsr	@declen
	php
@lp2:	jsr	_rle_read
	jsr	_rle_mem_write
	dec	rle_tmp_ctr
	bpl	@lp2
	plp
	bcs	@again

@out:	rts


@declen:; subtract cmd+1 from len
	sta	sreg
	lda	_rle_len
	clc
	sbc	sreg
	sta	_rle_len
	lda	_rle_len+1
	sbc	#0
	sta	_rle_len+1
	lda	_rle_len+2
	sbc	#0
	sta	_rle_len+2
	lda	_rle_len+3
	sbc	#0
	sta	_rle_len+3
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