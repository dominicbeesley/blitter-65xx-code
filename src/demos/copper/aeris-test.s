		.include "aeris.inc"

		.export _aeris_test_pgm, _aeris_test_pgm_end, _aeris_wait_vsync
;;		.export _aeris_movep_instr, _ae_text_rainbow
		.export _aeris_movep_instr2, _ae_sintab
		.export _aeris_test_pgm_rainbow
		.export _aeris_test_pgm_copper


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

		AE_WAIT		$1FF, 0, 20, 0
		AE_MOVE		$2, $22, $40				; reset nula

		; setup rainbow

_aeris_test_pgm_rainbow:
		AE_MOVE16	$2, $23, $1F00
		AE_MOVE16	$2, $23, $2F50
		AE_MOVE16	$2, $23, $3FB0
		AE_MOVE16	$2, $23, $4DF0
		AE_MOVE16	$2, $23, $57F0
		AE_MOVE16	$2, $23, $61F0
		AE_MOVE16	$2, $23, $70F3
		AE_MOVE16	$2, $23, $80F9
		AE_MOVE16	$2, $23, $90FF
		AE_MOVE16	$2, $23, $A09F
		AE_MOVE16	$2, $23, $B03F
		AE_MOVE16	$2, $23, $C10F
		AE_MOVE16	$2, $23, $D70F
		AE_MOVE16	$2, $23, $ED0F
		AE_MOVE16	$2, $23, $FF0B


		; copper bars
		AE_WAIT		$1FF, 0, 72, 0

_aeris_test_pgm_copper:
		AE_MOVE16	$2, $23, $0F00
		AE_WAITH
		AE_MOVE16	$2, $23, $0F20
		AE_WAITH
		AE_MOVE16	$2, $23, $0F50
		AE_WAITH
		AE_MOVE16	$2, $23, $0F80
		AE_WAITH
		AE_MOVE16	$2, $23, $0FB0
		AE_WAITH
		AE_MOVE16	$2, $23, $0FE0
		AE_WAITH
		AE_MOVE16	$2, $23, $0DF0
		AE_WAITH
		AE_MOVE16	$2, $23, $0AF0
		AE_WAITH
		AE_MOVE16	$2, $23, $07F0
		AE_WAITH
		AE_MOVE16	$2, $23, $04F0
		AE_WAITH
		AE_MOVE16	$2, $23, $01F0
		AE_WAITH
		AE_MOVE16	$2, $23, $00F0
		AE_WAITH
		AE_MOVE16	$2, $23, $00F3
		AE_WAITH
		AE_MOVE16	$2, $23, $00F6
		AE_WAITH
		AE_MOVE16	$2, $23, $00F9
		AE_WAITH
		AE_MOVE16	$2, $23, $00FC
		AE_WAITH
		AE_MOVE16	$2, $23, $00FF
		AE_WAITH
		AE_MOVE16	$2, $23, $00CF
		AE_WAITH
		AE_MOVE16	$2, $23, $009F
		AE_WAITH
		AE_MOVE16	$2, $23, $006F
		AE_WAITH
		AE_MOVE16	$2, $23, $003F
		AE_WAITH
		AE_MOVE16	$2, $23, $000F
		AE_WAITH
		AE_MOVE16	$2, $23, $010F
		AE_WAITH
		AE_MOVE16	$2, $23, $040F
		AE_WAITH
		AE_MOVE16	$2, $23, $070F
		AE_WAITH
		AE_MOVE16	$2, $23, $0A0F
		AE_WAITH
		AE_MOVE16	$2, $23, $0D0F
		AE_WAITH
		AE_MOVE16	$2, $23, $0F0E
		AE_WAITH
		AE_MOVE16	$2, $23, $0F0B
		AE_WAITH
		AE_MOVE16	$2, $23, $0F08
		AE_WAITH
		AE_MOVE16	$2, $23, $0F05
		AE_WAITH
		AE_MOVE16	$2, $23, $0F02
		AE_WAITH


		AE_MOVE16	$2, $23, $0F00
		AE_WAITH
		AE_MOVE16	$2, $23, $0F20
		AE_WAITH
		AE_MOVE16	$2, $23, $0F50
		AE_WAITH
		AE_MOVE16	$2, $23, $0F80
		AE_WAITH
		AE_MOVE16	$2, $23, $0FB0
		AE_WAITH
		AE_MOVE16	$2, $23, $0FE0
		AE_WAITH
		AE_MOVE16	$2, $23, $0DF0
		AE_WAITH
		AE_MOVE16	$2, $23, $0AF0
		AE_WAITH
		AE_MOVE16	$2, $23, $07F0
		AE_WAITH
		AE_MOVE16	$2, $23, $04F0
		AE_WAITH
		AE_MOVE16	$2, $23, $01F0
		AE_WAITH
		AE_MOVE16	$2, $23, $00F0
		AE_WAITH
		AE_MOVE16	$2, $23, $00F3
		AE_WAITH
		AE_MOVE16	$2, $23, $00F6
		AE_WAITH
		AE_MOVE16	$2, $23, $00F9
		AE_WAITH
		AE_MOVE16	$2, $23, $00FC
		AE_WAITH
		AE_MOVE16	$2, $23, $00FF
		AE_WAITH
		AE_MOVE16	$2, $23, $00CF
		AE_WAITH
		AE_MOVE16	$2, $23, $009F
		AE_WAITH
		AE_MOVE16	$2, $23, $006F
		AE_WAITH
		AE_MOVE16	$2, $23, $003F
		AE_WAITH
		AE_MOVE16	$2, $23, $000F
		AE_WAITH
		AE_MOVE16	$2, $23, $010F
		AE_WAITH
		AE_MOVE16	$2, $23, $040F
		AE_WAITH
		AE_MOVE16	$2, $23, $070F
		AE_WAITH
		AE_MOVE16	$2, $23, $0A0F
		AE_WAITH
		AE_MOVE16	$2, $23, $0D0F
		AE_WAITH
		AE_MOVE16	$2, $23, $0F0E
		AE_WAITH
		AE_MOVE16	$2, $23, $0F0B
		AE_WAITH
		AE_MOVE16	$2, $23, $0F08
		AE_WAITH
		AE_MOVE16	$2, $23, $0F05
		AE_WAITH
		AE_MOVE16	$2, $23, $0F02
		AE_WAITH


		AE_MOVE16	$2, $23, $0000
		AE_WAITH

		AE_MOVEC	1, 4

_aeris_movep_instr2:		
		AE_MOVEP	1, _ae_sintab
		AE_MOVEC	0, 16				; C0 <= 16

aeris_test_pgm_lp:
		AE_WAITH					; wait for a HSYNC
		AE_PLAY		1, 1
		AE_DSZ		0
		AE_BRA		aeris_test_pgm_lp
		AE_DSZ		1
		AE_BRA		_aeris_movep_instr2




		AE_MOVE		$0C, $B0, $81			; signal "vsync" to cpu (not actually a vsync but signals near end of picture)

		AE_WAIT 	$1FF, $00, $1FF, $00		; wait "forever"


;;		AE_WAIT 	$1FF, $00, 50, $00
;;		AE_MOVE		$2, $00, $00
;;		AE_MOVE		$2, $01, $80
;;		AE_MOVE		$2, $00, $02
;;		AE_MOVE		$2, $01, $61
;;		AE_MOVE16	$2, $23, $7F00
;;		AE_WAITH
;;		AE_MOVE		$2, $00, $00
;;		AE_MOVE		$2, $01, $7F
;;		AE_WAITH
;;		AE_WAITH
;;		AE_WAITH
;;		AE_MOVE		$2, $00, $00
;;		AE_MOVE		$2, $01, $80
;;		AE_MOVE		$2, $00, $02
;;		AE_MOVE		$2, $01, $60
;;		AE_WAITH
;;		AE_MOVE		$2, $00, $00
;;		AE_MOVE		$2, $01, $7F
;;		AE_WAITH
;;		AE_WAITH
;;		AE_WAITH
;;		AE_WAITH
;;		AE_WAITH
;;		AE_WAITH
;;		AE_WAITH
;;		AE_MOVE		$2, $00, $02
;;		AE_MOVE		$2, $01, $62
;;		AE_MOVE		$2, $00, $00
;;		AE_MOVE		$2, $01, $7D
;;		AE_WAITH
;;		AE_MOVE		$2, $00, $00
;;		AE_MOVE		$2, $01, $7F
;;		AE_MOVE16	$2, $23, $7FFF
;;
;;		AE_WAIT 	$1FF, $00, 70, $00
;;
;;
;;aeris_test_pgm_lp2:
;;
;;		AE_MOVEC	0, 16				; C0 <= 16
;;_aeris_movep_instr:
;;		AE_MOVEP	0, _ae_text_rainbow		; P0 <= _ae_text_rainbox (note this is poked at in main program)
;;_aeris_movep_instr2:		
;;		AE_MOVEP	1, _ae_sintab
;;
;;aeris_test_pgm_lp:
;;		AE_WAITH					; wait for a HSYNC
;;		AE_PLAY16	0, 2				; play 2 instructions from P0
;;		AE_PLAY		1, 1
;;		AE_ADDP		0, -8				; move P0 backwards 8
;;
;;		AE_WAIT		$000, $1F, 0, 19
;;		AE_SYNC
;;		AE_WAIT		$000, $1F, 0, 20
;;		AE_MOVE16	$2, $23, $7202
;;		AE_MOVE16	$2, $23, $F202
;;		AE_UNSYNC
;;
;;		AE_WAITH
;;		AE_PLAY16	0, 2
;;
;;		AE_WAIT		$000, $1F, 0, 14
;;		AE_SYNC
;;		AE_WAIT		$000, $1F, 0, 15
;;		AE_MOVE16	$2, $23, $7020
;;		AE_MOVE16	$2, $23, $F020
;;		AE_UNSYNC
;;
;;
;;		AE_DSZ		0
;;		AE_BRA		aeris_test_pgm_lp
;;
;;		AE_SKIP 	$1FF, $00, $108, $00
;;		AE_BRA 		aeris_test_pgm_lp2
;;
;;		AE_MOVE		$0C, $B0, $81			; signal "vsync" to cpu (not actually a vsync but signals near end of picture)
;;
;;		AE_WAIT 	$1FF, $00, $1FF, $00
;;
;;
;;_ae_text_rainbow:	; mirror finish for letter surround
;;		AE_MOVE16	$2, $23, $7F00
;;		AE_MOVE16	$2, $23, $FF00
;;
;;		AE_MOVE16	$2, $23, $7D04
;;		AE_MOVE16	$2, $23, $FD04
;;
;;		AE_MOVE16	$2, $23, $7B08
;;		AE_MOVE16	$2, $23, $FB08
;;
;;		AE_MOVE16	$2, $23, $790A
;;		AE_MOVE16	$2, $23, $F90A
;;
;;		AE_MOVE16	$2, $23, $7708
;;		AE_MOVE16	$2, $23, $F708
;;
;;		AE_MOVE16	$2, $23, $7504
;;		AE_MOVE16	$2, $23, $F504
;;
;;		AE_MOVE16	$2, $23, $7302
;;		AE_MOVE16	$2, $23, $F302
;;
;;		AE_MOVE16	$2, $23, $7100
;;		AE_MOVE16	$2, $23, $F100
;;
;;		AE_MOVE16	$2, $23, $7102
;;		AE_MOVE16	$2, $23, $F102
;;
;;		AE_MOVE16	$2, $23, $7304
;;		AE_MOVE16	$2, $23, $F304
;;
;;		AE_MOVE16	$2, $23, $7508
;;		AE_MOVE16	$2, $23, $F508
;;
;;		AE_MOVE16	$2, $23, $770A
;;		AE_MOVE16	$2, $23, $F70A
;;
;;		AE_MOVE16	$2, $23, $7908
;;		AE_MOVE16	$2, $23, $F908
;;
;;		AE_MOVE16	$2, $23, $7B04
;;		AE_MOVE16	$2, $23, $FB04
;;
;;		AE_MOVE16	$2, $23, $7D02
;;		AE_MOVE16	$2, $23, $FD02
;;
;;		AE_MOVE16	$2, $23, $7F00
;;		AE_MOVE16	$2, $23, $FF00
;;
;;
;;		AE_MOVE16	$2, $23, $7F00
;;		AE_MOVE16	$2, $23, $FF00
;;
;;		AE_MOVE16	$2, $23, $7D04
;;		AE_MOVE16	$2, $23, $FD04
;;
;;		AE_MOVE16	$2, $23, $7B08
;;		AE_MOVE16	$2, $23, $FB08
;;
;;		AE_MOVE16	$2, $23, $790A
;;		AE_MOVE16	$2, $23, $F90A
;;
;;		AE_MOVE16	$2, $23, $7708
;;		AE_MOVE16	$2, $23, $F708
;;
;;		AE_MOVE16	$2, $23, $7504
;;		AE_MOVE16	$2, $23, $F504
;;
;;		AE_MOVE16	$2, $23, $7302
;;		AE_MOVE16	$2, $23, $F302
;;
;;		AE_MOVE16	$2, $23, $7100
;;		AE_MOVE16	$2, $23, $F100
;;
;;		AE_MOVE16	$2, $23, $7102
;;		AE_MOVE16	$2, $23, $F102
;;
;;		AE_MOVE16	$2, $23, $7304
;;		AE_MOVE16	$2, $23, $F304
;;
;;		AE_MOVE16	$2, $23, $7508
;;		AE_MOVE16	$2, $23, $F508
;;
;;		AE_MOVE16	$2, $23, $770A
;;		AE_MOVE16	$2, $23, $F70A
;;
;;		AE_MOVE16	$2, $23, $7908
;;		AE_MOVE16	$2, $23, $F908
;;
;;		AE_MOVE16	$2, $23, $7B04
;;		AE_MOVE16	$2, $23, $FB04
;;
;;		AE_MOVE16	$2, $23, $7D02
;;		AE_MOVE16	$2, $23, $FD02
;;
;;		AE_MOVE16	$2, $23, $7F00
;;		AE_MOVE16	$2, $23, $FF00
;;
;;
_ae_sintab:
		AE_MOVE		$2, $22, $20
		AE_MOVE		$2, $22, $21
		AE_MOVE		$2, $22, $22
		AE_MOVE		$2, $22, $23
		AE_MOVE		$2, $22, $24
		AE_MOVE		$2, $22, $25
		AE_MOVE		$2, $22, $26
		AE_MOVE		$2, $22, $27
		AE_MOVE		$2, $22, $27
		AE_MOVE		$2, $22, $26
		AE_MOVE		$2, $22, $25
		AE_MOVE		$2, $22, $24
		AE_MOVE		$2, $22, $23
		AE_MOVE		$2, $22, $22
		AE_MOVE		$2, $22, $21
		AE_MOVE		$2, $22, $20
		AE_MOVE		$2, $22, $20
		AE_MOVE		$2, $22, $21
		AE_MOVE		$2, $22, $22
		AE_MOVE		$2, $22, $23
		AE_MOVE		$2, $22, $24
		AE_MOVE		$2, $22, $25
		AE_MOVE		$2, $22, $26
		AE_MOVE		$2, $22, $27
		AE_MOVE		$2, $22, $27
		AE_MOVE		$2, $22, $26
		AE_MOVE		$2, $22, $25
		AE_MOVE		$2, $22, $24
		AE_MOVE		$2, $22, $23
		AE_MOVE		$2, $22, $22
		AE_MOVE		$2, $22, $21
		AE_MOVE		$2, $22, $20


_aeris_test_pgm_end:	