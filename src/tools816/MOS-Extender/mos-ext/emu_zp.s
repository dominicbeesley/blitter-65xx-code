


		.exportzp	TRAMPOLINES
		.exportzp	TRAMPO_NAT2EMU
		.exportzp	TRAMPO_EMU2NAT
		.exportzp	zp_tmpLEN
		.exportzp	zp_tmpPTR
		.exportzp	zp_emu_sp
		.exportzp	zp_nat_sp
		.exportzp	zp_mvn
		.exportzp	zp_wksp

TRAMPOLINES 	:=	$8A
TRAMPO_NAT2EMU	:=	TRAMPOLINES
TRAMPO_EMU2NAT	:=	TRAMPOLINES+3

		.zeropage
zp_tmpLEN:	.res	2
zp_tmpPTR:	.res	2
zp_emu_sp:	.res	1
zp_nat_sp:	.res	2

zp_mvn:		.res	4	

zp_wksp:	.res	32		; general purpose wksp used in COP handlers