	.include "hardware.inc"

	.export _flash_wait

.proc _flash_wait:near
		php
		sei
@lp:	
		lda	JIM
		cmp	JIM
		bne	@lp
		plp
		rts

.endproc