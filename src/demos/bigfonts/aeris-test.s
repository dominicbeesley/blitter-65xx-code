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

		.include "aeris.inc"

		.export _aeris_test_pgm, _aeris_test_pgm_end, _aeris_wait_vsync
		.export _aeris_movep_instr, _ae_text_rainbow


_aeris_wait_vsync:
		lda	#$80
		sta	$FDB0
@1:
		lda	$FDB0
		and	#1
		beq	@1

		ldx	#0
		txa
		rts

_aeris_test_pgm:


		AE_WAIT 	$1FF, $00, 70, $00


aeris_test_pgm_lp2:

		AE_MOVEC	0, 16
_aeris_movep_instr:
		AE_MOVEP	0, _ae_text_rainbow

aeris_test_pgm_lp:
		AE_WAITH
		AE_PLAY16	0, 2
		AE_ADDP		0, -8

		AE_WAIT		$000, $1F, 0, 19
		AE_SYNC
		AE_WAIT		$000, $1F, 0, 20
		AE_MOVE16	$2, $23, $7202
		AE_MOVE16	$2, $23, $F202
		AE_UNSYNC

		AE_WAITH
		AE_PLAY16	0, 2

		AE_WAIT		$000, $1F, 0, 14
		AE_SYNC
		AE_WAIT		$000, $1F, 0, 15
		AE_MOVE16	$2, $23, $7020
		AE_MOVE16	$2, $23, $F020
		AE_UNSYNC


		AE_DSZ		0
		AE_BRA		aeris_test_pgm_lp

		AE_SKIP 	$1FF, $00, $108, $00
		AE_BRA 		aeris_test_pgm_lp2

		AE_MOVE		$0C, $B0, $81		; signal to cpu

		AE_WAIT 	$1FF, $00, $1FF, $00

_ae_text_rainbow:	; mirror finish for letter surround
		AE_MOVE16	$2, $23, $7F00
		AE_MOVE16	$2, $23, $FF00

		AE_MOVE16	$2, $23, $7D04
		AE_MOVE16	$2, $23, $FD04

		AE_MOVE16	$2, $23, $7B08
		AE_MOVE16	$2, $23, $FB08

		AE_MOVE16	$2, $23, $790A
		AE_MOVE16	$2, $23, $F90A

		AE_MOVE16	$2, $23, $7708
		AE_MOVE16	$2, $23, $F708

		AE_MOVE16	$2, $23, $7504
		AE_MOVE16	$2, $23, $F504

		AE_MOVE16	$2, $23, $7302
		AE_MOVE16	$2, $23, $F302

		AE_MOVE16	$2, $23, $7100
		AE_MOVE16	$2, $23, $F100

		AE_MOVE16	$2, $23, $7102
		AE_MOVE16	$2, $23, $F102

		AE_MOVE16	$2, $23, $7304
		AE_MOVE16	$2, $23, $F304

		AE_MOVE16	$2, $23, $7508
		AE_MOVE16	$2, $23, $F508

		AE_MOVE16	$2, $23, $770A
		AE_MOVE16	$2, $23, $F70A

		AE_MOVE16	$2, $23, $7908
		AE_MOVE16	$2, $23, $F908

		AE_MOVE16	$2, $23, $7B04
		AE_MOVE16	$2, $23, $FB04

		AE_MOVE16	$2, $23, $7D02
		AE_MOVE16	$2, $23, $FD02

		AE_MOVE16	$2, $23, $7F00
		AE_MOVE16	$2, $23, $FF00


		AE_MOVE16	$2, $23, $7F00
		AE_MOVE16	$2, $23, $FF00

		AE_MOVE16	$2, $23, $7D04
		AE_MOVE16	$2, $23, $FD04

		AE_MOVE16	$2, $23, $7B08
		AE_MOVE16	$2, $23, $FB08

		AE_MOVE16	$2, $23, $790A
		AE_MOVE16	$2, $23, $F90A

		AE_MOVE16	$2, $23, $7708
		AE_MOVE16	$2, $23, $F708

		AE_MOVE16	$2, $23, $7504
		AE_MOVE16	$2, $23, $F504

		AE_MOVE16	$2, $23, $7302
		AE_MOVE16	$2, $23, $F302

		AE_MOVE16	$2, $23, $7100
		AE_MOVE16	$2, $23, $F100

		AE_MOVE16	$2, $23, $7102
		AE_MOVE16	$2, $23, $F102

		AE_MOVE16	$2, $23, $7304
		AE_MOVE16	$2, $23, $F304

		AE_MOVE16	$2, $23, $7508
		AE_MOVE16	$2, $23, $F508

		AE_MOVE16	$2, $23, $770A
		AE_MOVE16	$2, $23, $F70A

		AE_MOVE16	$2, $23, $7908
		AE_MOVE16	$2, $23, $F908

		AE_MOVE16	$2, $23, $7B04
		AE_MOVE16	$2, $23, $FB04

		AE_MOVE16	$2, $23, $7D02
		AE_MOVE16	$2, $23, $FD02

		AE_MOVE16	$2, $23, $7F00
		AE_MOVE16	$2, $23, $FF00


_aeris_test_pgm_end:	