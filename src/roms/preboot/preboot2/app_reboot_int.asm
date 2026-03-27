	.include "hardware.inc"


	.export	_app_reboot_reboot
	.include "preboot_saves.inc"
	.include "preboot.inc"

		.segment "reboot_int"

_app_reboot_reboot:
		sei
		lda	#$FF
		sta	JIM_DEVNO_BLITTER		; make sure JIM is deselected

		lda	_preboot_save_TURBO2	; need to get this before mapping out lomem turbo
		and	#<~BITS_MEM_TURBO2_PREBOOT
		ldx	#0
		stx	sheila_MEM_LOMEMTURBO	; data may have disappeared now!
		sta	PREBOOT_SAVE_TURBO2	; store in safe area...to be picked up in stack bounce below
		
		lda	#$7F
		sta	sheila_SYSVIA_ier		; this will cause a cold boot! (TODO: get from preboot-1, or should we force a cold-boot?)
		sta	sheila_SYSVIA_ifr

		ldx	#stackprog_end-stackprog-1
@rlp:		lda	stackprog,X
		sta	$100,X
		dex
		bpl	@rlp
		jmp	$100


stackprog:	lda	sheila_MEM_CTL
		and	#<~BITS_MEM_CTL_SWMOS	; swmos off - TODO:, get from preboot-1 if not map0, or should we force this?
		sta	sheila_MEM_CTL
		lda	PREBOOT_SAVE_TURBO2
		sta	sheila_MEM_TURBO2
		
		jmp	($FFFC)
stackprog_end:
