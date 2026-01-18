

	.export _intoff
	.export _intrestore

;; unsigned char intoff();

_intoff:
	php
	pla
	sei
	ldx	#0
	rts

;; void intrestore(unsigned char P);
_intrestore:
	pha
	plp
	rts

