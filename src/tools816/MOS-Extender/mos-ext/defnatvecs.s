

		.segment "NATHANDLER"

		.import default_nat_brk:far

		.export def_nat_vecs:far
def_nat_vecs:
DEFNAT_USERV:	.faraddr	anRTL
DEFNAT_BRKV:	.faraddr	default_nat_brk
DEFNAT_IRQ1V:	.faraddr	anRTL
DEFNAT_IRQ2V:	.faraddr	anRTL
DEFNAT_CLIV:	.faraddr	anRTL
DEFNAT_BYTEV:	.faraddr	anRTL
DEFNAT_WORDV:	.faraddr	anRTL
DEFNAT_WRCHV:	.faraddr	anRTL
DEFNAT_RDCHV:	.faraddr	anRTL
DEFNAT_FILEV:	.faraddr	anRTL
DEFNAT_ARGSV:	.faraddr	anRTL
DEFNAT_BGETV:	.faraddr	anRTL
DEFNAT_BPUTV:	.faraddr	anRTL
DEFNAT_GBPBV:	.faraddr	anRTL
DEFNAT_FINDV:	.faraddr	anRTL
DEFNAT_FSCV:	.faraddr	anRTL
DEFNAT_EVNTV:	.faraddr	anRTL
DEFNAT_UPTV:	.faraddr	anRTL
DEFNAT_NETV:	.faraddr	anRTL
DEFNAT_VDUV:	.faraddr	anRTL
DEFNAT_KEYV:	.faraddr	anRTL
DEFNAT_INSV:	.faraddr	anRTL
DEFNAT_REMV:	.faraddr	anRTL
DEFNAT_CNPV:	.faraddr	anRTL
DEFNAT_IND1V:	.faraddr	anRTL
DEFNAT_IND2V:	.faraddr	anRTL
DEFNAT_IND3V:	.faraddr	anRTL
DEFNAT_N_P100V:	.faraddr	anRTL

anRTL:	rtl