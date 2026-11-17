		.include "cop.inc"

		.include "oslib.inc"

		.import callmos

;	********************************************************************************
;	* COP 06 - OPOSB = OSBYTE                                                      *
;	*                                                                              *
;	* This call caries out various operations, the specific operation depending on *
;	* the contents of A on entry. Other data can be passed in X and Y. If results  *
;	* are generated, these are returned in X and Y.                                *
;	*                                                                              *
;	* On entry: A contains the reason code. The reason code determines the         *
;	* function of the call.                                                        *
;	*                                                                              *
;	* On exit: X and Y will contain results if the call produces them.             *
;	* Cy, returned                                                                 *
;	*                                                                              *
;	* A,D preserved                                                                *
;	********************************************************************************


		.segment	"NATHANDLER"

		.export	COP_06
COP_06:		
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