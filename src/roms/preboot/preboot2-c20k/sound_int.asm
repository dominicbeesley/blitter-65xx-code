	.include "hardware.inc"

	.export _sound_poke

	.proc snd_dly:near
		ldy	#$08				; set and
@dl:		lda	sheila_RD_NOP_2MHz		; force a 2MHz bus sync
		dey					; execute short delay
		bne	@dl
		rts	
	.endproc


	;; void sound_poke(unsigned char v)
	.proc _sound_poke:near

		php					;

		sei					; disable interrupts
		ldy	#$ff				; System VIA port A all outputs
		sty	sheila_SYSVIA_ddra		; set
		sta	sheila_SYSVIA_ora_nh		; output A on port A
		iny					; Y=0
		sty	sheila_SYSVIA_orb			; enable sound chip
		jsr	snd_dly
		ldy	#$08				; then disable sound chip again
		sty	sheila_SYSVIA_orb		;
		jsr	snd_dly
		plp
		rts
	.endproc