
	.IFNDEF INC_COMMON

INC_COMMON	:=	1

		.MACRO ADDR24 arg
		.word	.loword(arg)
		.byte   ^(arg)
		.ENDMACRO
	.ENDIF