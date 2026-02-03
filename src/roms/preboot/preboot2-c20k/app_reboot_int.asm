	.include "hardware.inc"


	.export	_app_reboot_reboot

		.segment "reboot_int"

_app_reboot_reboot:
		sei
		lda	#$FF
		sta	JIM_DEVNO_BLITTER		; make sure JIM is deselected

		lda	#0
		sta	sheila_MEM_LOMEMTURBO	; data may have disappeared now!
		lda	sheila_MEM_TURBO2		
		ora	#BITS_MEM_TURBO2_MAP0N1|BITS_MEM_TURBO2_THROTTLE|BITS_MEM_TURBO2_THROTTLE_MOS
		sta	sheila_MEM_TURBO2		; map 0 forced - todo, get from preboot-1
		
		lda	#$7F
		sta	sheila_SYSVIA_ier		; this will cause a cold boot! (TODO: get from preboot-1)
		sta	sheila_SYSVIA_ifr

		ldx	#stackprog_end-stackprog-1
@rlp:		lda	stackprog,X
		sta	$100,X
		dex
		bpl	@rlp
		jmp	$100


stackprog:	lda	sheila_MEM_CTL
		and	#<~BITS_MEM_CTL_SWMOS	; swmos off - todo, get from preboot-1 if not map0
		sta	sheila_MEM_CTL
		
		jmp	($FFFC)
stackprog_end:
