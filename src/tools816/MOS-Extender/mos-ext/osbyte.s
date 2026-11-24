		.include "cop.inc"

		.include "oslib.inc"

		.import callmos

;	********************************************************************************
; ********************************************************************************
; * COP 06 - OPOSB - OSBYTE                                                      *
; *                                                                              *
; * Action: Call the 8-bit MOS OSBYTE. The operation depends on the reason       *
; * code in A. Other data can be passed in X and Y; results are returned in      *
; * X and Y.                                                                     *
; *                                                                              *
; * On entry: A = reason code (8 bits)                                           *
; *           X, Y = parameters (8 bits)                                         *
; * On exit:  X, Y = results, as returned by the MOS (zero-extended to 16        *
; *           bits)                                                              *
; *           C    = as returned by the MOS                                      *
; *                                                                              *
; * Note: A, X and Y keep their 8-bit MOS meanings here; this call does not      *
; * follow the X:A pointer convention.                                           *
; ********************************************************************************


		.segment	"NATHANDLER"

		.export	COP_06
		.proc COP_06:far
		sep	#$30
		.a8
		.i8
		
		pea	OSBYTE
		jsl	callmos

		; we're still 8 bit X,Y,A here, DP preserved

		; return X,Y
		stx	z:DPCOP_X
		stz	z:DPCOP_X+1
		sty	z:DPCOP_Y
		stz	z:DPCOP_Y+1

		; return Cy, everything else swallowed
		php
		pla

		ror	z:DPCOP_P
		ror	A
		rol	z:DPCOP_P

		rtl
		.endproc