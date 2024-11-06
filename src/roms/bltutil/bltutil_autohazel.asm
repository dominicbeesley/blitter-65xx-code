; MIT License
; 
; Copyright (c) 2023 Dossytronics
; https://github.com/dominicbeesley/blitter-65xx-code
; 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

		.include "mosrom.inc"
		.include "oslib.inc"
		.include "bltutil.inc"

		.export autohazel_boot_first
		.export autohazel_boot_second
		

; As all the stuff in this file happens fairly early during boot we will
; assume that we can trample on some as defined below

	.segment "ZEROPAGE_HAZEL"
zp_tmp_lo:
zp_srv_prg:	.res 1		; low byte of service_call address on stack - 1
zp_bltutil_rom:	.res 1		; rom # for this ROM
zp_srv_rom:	.res 1		; rom # for current service call
zp_srv_num:	.res 1		; current service call number
zp_srv_prevY:	.res 1		; save Y before service call
zp_srv_map:	.res 2		; a bit is set here for any rom that changed Y
zp_srv_resetY:	.res 1		; a top bit set means Cy on entry
zp_wksp_top:	.res 1		
zp_srv_resY:	.res 1		; return Y from end of service call round robin
zp_tmp_len	:= *-zp_tmp_lo	; save length


	.code

; The following routine is copied to the stack and executed from there
; it's purpose is to:
; 	- set the rom in F4/ROMSEL to X
;	- pass A, Y to service routine of ROM X at $8003
;	- return, preserving A,Y (but not X) returned from service routine
;	- restore ROM before returning to this ROM

;	STACK
;	+1..2	caller return address
;	S


service_call:
		stx	zp_mos_curROM		; switch to ROM # passed in X
	.ifdef MACH_ELK
		lda	#$0C
		sta	SHEILA_ROMCTL_SWR
	.endif
		stx	SHEILA_ROMCTL_SWR	
		lda 	zp_srv_num		; get back service call number A
		jsr	$8003			; call service routine in ROM #X
		ldx	zp_bltutil_rom
		stx	zp_mos_curROM
	.ifdef MACH_ELK
		lda	#$0C
		sta	SHEILA_ROMCTL_SWR
	.endif
		stx	SHEILA_ROMCTL_SWR
		rts
service_call_len	:= *-service_call


; On entry A,X,Y are what will be passed to service call
; On exit A,X,Y are as received from service call
; The service call function above is already on the stack at S+1
;
;	STACK
;	+1..2	caller return address
call_service_call:
		lda	#1
		pha
		lda	zp_srv_prg
		pha				; push low address of service_call-1 on stack 

;	STACK
;	+3..4	caller return address
;	+2	"1"
;	+1	low byte of service_call on stack - 1
;	S
		rts				; this will call the service routine we just pushed
						; the rts in the service_call routine will return
						; to our caller

	; execute service call on all roms below ours
	; on entry:
	;	A = service call number
	;	Y = parameter
	;	Cy = if set on entry reset Y for each rom and the maximum value returned in Y
	; on exit:
	;	A = service call number (don't allow to be captured)
	;	Y = updated parameter
	;	bits in zp_map0..1 are set if that rom # modified Y
autohazel_service:
		ror	zp_srv_resetY		; zp_srv_resetY is minus for Y resets
		sta	zp_srv_num		; save A for later
		sty	zp_srv_prevY		; save Y for later
		sty	zp_srv_resY		; result (should no roms respond)

		lda	zp_mos_curROM
		sta 	zp_bltutil_rom		; remember who we are
		and	#$F
		sta	zp_srv_rom		; number of next rom to call + 1

		; copy service trampoline to stack
		ldx	#service_call_len
@lp1:		lda	service_call-1,X
		pha
		dex
		bne	@lp1
		tsx
		stx	zp_srv_prg

		; loop through all roms below us and call service routine
@lp2:		dec	zp_srv_rom
		bmi	@sk_done
		ldx	zp_srv_rom
		
		lda	oswksp_ROMTYPE_TAB,X	; Read bit 7 on ROM type table (no ROM has type 254 &FE)
		bpl	@lp2			; If not set (+ve result), step to next ROM down

		ldy	zp_srv_prevY
		jsr	call_service_call		; call the service call A will be set later

		cpy	zp_srv_prevY
		beq	@sk2			; no change don't set bit

		; the rom changed Y, set its bit in the map registers
		lda	zp_srv_rom		; get back X (it may have been changed in the service call?)
		and	#$7
		tax
		lda	#1
		clc
@blp:		dex	
		bmi	@bsk
		rol	A
		bcc	@blp
@bsk:		ldx	zp_srv_rom
		cpx	#8
		bcs	@bsk2
		ora	zp_srv_map
		sta	zp_srv_map
		bne	@sk2			; always
@bsk2:		ora	zp_srv_map+1
		sta	zp_srv_map+1		
@sk2:		

		; check to see if Y should be update
		bit	zp_srv_resetY
		bpl	@sk_noresetY		; go round again, Y will be reset

		cpy	zp_srv_resY		; compare against result value
		bcc	@lp2			; < reset Y and go again
		bcs	@stlp2
@sk_noresetY:	sty	zp_srv_prevY		
@stlp2:		sty	zp_srv_resY
		jmp	@lp2			; go round again with new Y

		;exit service call
@sk_done:	tsx
		txa
		clc
		adc	#service_call_len
		tax
		txs
		lda	zp_srv_num
		ldy	zp_srv_resY
		rts

svc_24_CountDyn_HAZEL	:= $24
svc_21_ClaimAbs_HAZEL	:= $21
svc_22_ClaimPrv_HAZEL	:= $22
svc_23_NotifyAbs_HAZEL	:= $23

		; this is called from our own service 0 handler and will
		; do service calls 
autohazel_boot_first:
		php
		pha
		txa
		pha
		tya
		pha

		lda	#0
		sta	zp_srv_map
		sta	zp_srv_map+1

		; Ask ROMs how much private high workspace required
		ldy 	#$DC			; Start high workspace at &DC00 and work downwards
		lda 	#svc_24_CountDyn_HAZEL 
		clc				; count down from DC updating value
		jsr 	autohazel_service		;
		sty	zp_wksp_top		; Save top of shared workspace (so far)

		; Ask ROMs for maximum shared high workspace required
		ldy	#$C0
		lda 	#svc_21_ClaimAbs_HAZEL 
		sec				; reset back to C0 each time - (detect need for shared Hazel)
		jsr 	autohazel_service	;

		; check if Y > zp_wksp_top use that later for the reported value
		cpy	zp_wksp_top
		bcs	@sk1
		ldy	zp_wksp_top		
@sk1:		sty	zp_wksp_top		; Save top of shared workspace (so far)

		; enable auto hazel hardware map
		lda	zp_srv_map
		sta	sheila_ROM_AUTOHAZEL_0
		lda	zp_srv_map+1
		sta	sheila_ROM_AUTOHAZEL_1

		; Ask ROMs for private high workspace required
		lda	#svc_22_ClaimPrv_HAZEL 
		clc				; count up from top of shared
		jsr	autohazel_service   	;

		pla
		tay
		pla
		tax
		pla
		plp
		rts

		
	

autohazel_boot_second:
		php
		pha
		txa
		pha
		tya
		pha

                	ldy	zp_wksp_top		; Get top of shared high workspace
                	lda	#svc_23_NotifyAbs_HAZEL	; Tell ROMs top of shared high workspace
                	clc				; no reset of value
		jsr	autohazel_service

		pla
		tay
		pla
		tax
		pla
		plp
		rts
		




