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

		.include "oslib.inc"
		.include "mosrom.inc"
		.include "bltutil.inc"
		.include "bltutil_utils.inc"
		.include "bltutil_romheader.inc"
		.include "bltutil_jimstuff.inc"

		.CODE


			.export _SOUND_IRQ
			.import pitch2period
			.import REMV_internal_SEV
			.import REMV_internal_CLV
			.export _LECA2


_BEB44:			jmp	_LEC59				; just to allow relative branches in early part


;*************************************************************************
;*									 *
;*	 PROCESS SOUND INTERRUPT					 *
;*									 *
;*************************************************************************




_SOUND_IRQ:		lda	#$00				; 
			sta	JIM+SNDWKSP_SYNC_HOLD_COUNT	; zero number of channels on hold for sync
			lda	JIM+SNDWKSP_SYNC_CHANS		; get number of channels required for sync
			bne	_BEB57				; if this <>0 then EB57
			inc	JIM+SNDWKSP_SYNC_HOLD_COUNT	; else number of chanels on hold for sync =1
			dec	JIM+SNDWKSP_SYNC_CHANS		; number of channels required for sync =255

_BEB57:			ldx	#$08				; set loop counter
_LEB59:			dex					; loop
			lda	JIM+SNDWKSP_QUEUE_OCC,X		; get value of &800 +offset (sound queue occupancy)
			beq	_BEB44				; if 0 goto EC59 no sound this channel
			lda	JIM+SNDWKSP_BUF_BUSY_0,X	; else get buffer busy flag
			bmi	_BEB69				; if negative (buffer empty) goto EB69
			lda	JIM+SNDWKSP_DURATION,X		; else if duration count not zer0
			bne	_BEB6C				; goto EB6C
_BEB69:			jsr	_LEC6B				; check and pick up new sound if required
_BEB6C:			lda	JIM+SNDWKSP_DURATION,X		; if duration count 0
			beq	_BEB84				; goto EB84
			cmp	#$ff				; else if it is &FF (infinite duration)
			beq	_BEB87				; go onto EB87
			dec	JIM+SNDWKSP_DURATION_SUB,X	; decrement 10 mS count
			bne	_BEB87				; and if 0
			lda	#$05				; reset to 5
			sta	JIM+SNDWKSP_DURATION_SUB,X	; to give 50 mSec delay
			dec	JIM+SNDWKSP_DURATION,X		; and decrement main counter
			bne	_BEB87				; if not zero then EB87
_BEB84:			jsr	_LEC6B				; else check and get nw sound
_BEB87:			lda	JIM+SNDWKSP_ENV_STEPREPEAT,X	; if step progress counter is 0 no envelope involved
			beq	_BEB91				; so jump to EB91
			dec	JIM+SNDWKSP_ENV_STEPREPEAT,X	; else decrement it
			bne	_BEB44				; and if not zero go on to EC59
_BEB91:			ldy	JIM+SNDWKSP_ENVELOPE_OFFS,X	; get  envelope data offset from (8C0)
			cpy	#$ff				; if 255 no envelope set so
			beq	_BEB44				; goto EC59
			lda	snd_envelope_STEP,Y		; else get get step length
			and	#$7f				; zero repeat bit
			sta	JIM+SNDWKSP_ENV_STEPREPEAT,X	; and store it
			lda	JIM+SNDWKSP_AMP_PHASE_CUR,X	; get phase counter
			cmp	#$04				; if release phase completed
			beq	_BEC07				; goto EC07
			lda	JIM+SNDWKSP_AMP_PHASE_CUR,X	; else start new step by getting phase
			clc					; 
			adc	JIM+SNDWKSP_ENVELOPE_OFFS,X	; add it to interval multiplier
			tay					; transfer to Y
			lda	snd_envelope_ALA,Y		; and get target value base for envelope
			sec					; 
			sbc	#$3f				; 
			sta	JIM+SNDWKSP_AMP_TARGET		; store modified number as current target amplitude
			lda	snd_envelope_AA,Y		; get byte from envelope store
			sta	JIM+SNDWKSP_AMP_STEP		; store as current amplitude step
			lda	JIM+SNDWKSP_AMP_CUR,X		; get base volumelevel
			pha					; save it
			clc					; clear carry
			adc	JIM+SNDWKSP_AMP_STEP		; add to current amplitude step
			bvc	_BEBCF				; if no overflow
			rol					; double it Carry = bit 7
			lda	#$3f				; if bit =1 A=&3F
			bcs	_BEBCF				; into &EBCF
			eor	#$ff				; else toggle bits (A=&C0)

				; at this point the BASIC volume commands are converted
				; &C0 (0) to &38 (-15) 3 times, In fact last 3 bits
				; are ignored so &3F represents -15

_BEBCF:			sta	JIM+SNDWKSP_AMP_CUR,X		; store in current volume
			rol					; multiply by 2
			eor	JIM+SNDWKSP_AMP_CUR,X		; if bits 6 and 7 are equal
			bpl	_BEBE1				; goto &EBE1
			lda	#$3f				; if carry clear A=&3F (maximum)
			bcc	_BEBDE				; or
			eor	#$ff				; &C0 minimum

_BEBDE:			sta	JIM+SNDWKSP_AMP_CUR,X		; and this is stored in current volume

_BEBE1:			dec	JIM+SNDWKSP_AMP_STEP		; decrement amplitude change per step
			lda	JIM+SNDWKSP_AMP_CUR,X		; get volume again
			sec					; set carry
			sbc	JIM+SNDWKSP_AMP_TARGET		; subtract target value
			eor	JIM+SNDWKSP_AMP_STEP		; negative value indicates correct trend
			bmi	_BEBF9				; so jump to next part
			lda	JIM+SNDWKSP_AMP_TARGET		; else enter new phase
			sta	JIM+SNDWKSP_AMP_CUR,X		; 
			inc	JIM+SNDWKSP_AMP_PHASE_CUR,X	; 

_BEBF9:			pla					; get the old volume level
			eor	JIM+SNDWKSP_AMP_CUR,X		; and compare with the old
			and	#$f8				; 
			beq	_BEC07				; if they are the same goto EC07
			lda	JIM+SNDWKSP_AMP_CUR,X		; else set new level
			jsr	_LEB0A				; via EB0A
_BEC07:			lda	JIM+SNDWKSP_PITCH_PHASE_CUR,X	; get absolute pitch value
			cmp	#$03				; if it =3
			beq	_LEC59				; skip rest of loop as all sections are finished
			lda	JIM+SNDWKSP_PITCH_PH_STEPS,X	; else if 814,X is not 0 current section is not
								; complete
			bne	_BEC3D				; so EC3D
			inc	JIM+SNDWKSP_PITCH_PHASE_CUR,X	; else implement a section change
			lda	JIM+SNDWKSP_PITCH_PHASE_CUR,X	; check if its complete
			cmp	#$03				; if not
			bne	_BEC2D				; goto EC2D
			ldy	JIM+SNDWKSP_ENVELOPE_OFFS,X	; else set A from
			lda	snd_envelope_STEP,Y		; &820 and &8C0 (first envelope byte)
			bmi	_LEC59				; if negative there is no repeat
			lda	#$00				; else restart section sequence
			sta	JIM+SNDWKSP_PITCH_SETTING,X	; 
			sta	JIM+SNDWKSP_PITCH_PHASE_CUR,X	; 

_BEC2D:			lda	JIM+SNDWKSP_PITCH_PHASE_CUR,X	; get number of steps in new section
			clc					; 
			adc	JIM+SNDWKSP_ENVELOPE_OFFS,X	; 
			tay					; 
			lda	snd_envelope_PN1,Y		; 
			sta	JIM+SNDWKSP_PITCH_PH_STEPS,X	; set in 814+X
			beq	_LEC59				; and if 0 then EC59

_BEC3D:			dec	JIM+SNDWKSP_PITCH_PH_STEPS,X	; decrement
			lda	JIM+SNDWKSP_ENVELOPE_OFFS,X	; and pick up rate of pitch change
			clc					; 
			adc	JIM+SNDWKSP_PITCH_PHASE_CUR,X	; 
			tay					; 
			lda	snd_envelope_PI1,Y		; 
			clc					; 
			adc	JIM+SNDWKSP_PITCH_SETTING,X	; add to rate of differential pitch change
			sta	JIM+SNDWKSP_PITCH_SETTING,X	; and save it
			clc					; 
			adc	JIM+SNDWKSP_AMP_BASE_PITCH,X	; ad to base pitch
			jsr	_LED01				; and set new pitch

_LEC59:			cpx	#$00				; if X=0 (last channel) DB: 0..7 channels!
			beq	_BEC6A				; goto EC6A (RTS)
			jmp	_LEB59				; else do loop again

_LEC60:			ldx	#$08				; X=7 again
_BEC62:			dex					; loop
			jsr	_LECA2				; clear channel
			cpx	#$00				; if not 4
			bne	_BEC62				; do it again
_BEC6A:			rts					; and return
								;
_LEC6B:			lda	JIM+SNDWKSP_AMP_PHASE_CUR,X	; check for last amplitude phase
			cmp	#$04				; is it 4 (release complete)
			beq	_BEC77				; if so EC77
			lda	#$03				; else mark release in progress
			sta	JIM+SNDWKSP_AMP_PHASE_CUR,X	; and store it
_BEC77:			lda	JIM+SNDWKSP_BUF_BUSY_0,X	; is buffer not empty
			beq	_BEC90				; if so EC90
			lda	#$00				; else mark buffer not empty
			sta	JIM+SNDWKSP_BUF_BUSY_0,X	; an store it

			ldy	#$08				; loop counter
_BEC83:			sta	JIM+SNDWKSP_SYNC_HOLD_PARAM-1,Y	; zero sync bytes
			dey					; 
			bne	_BEC83				; until Y=0

			sta	JIM+SNDWKSP_DURATION,X		; zero duration count
			dey					; and set sync count to
			sty	JIM+SNDWKSP_SYNC_CHANS		; &FF
_BEC90:			lda	JIM+SNDWKSP_SYNC_FLAG,X		; get synchronising flag
			beq	_BECDB				; if its 0 then ECDB
			lda	JIM+SNDWKSP_SYNC_HOLD_COUNT	; else get number of channels on hold
			beq	_LECD0				; if 0 then ECD0
			lda	#$00				; else
			sta	JIM+SNDWKSP_SYNC_FLAG,X		; zero sync flag
_BEC9F:			jmp	_LED98				; and goto ED98

_LECA2:			jsr	_LEB03				; silence the channel
			tya					; Y=0 A=Y
			sta	JIM+SNDWKSP_DURATION,X		; zero main count
			sta	JIM+SNDWKSP_BUF_BUSY_0,X	; mark buffer not empty
			sta	JIM+SNDWKSP_QUEUE_OCC,X		; mark channel dormant
			ldy	#$07				; loop counter
_BECB1:			sta	JIM+SNDWKSP_SYNC_HOLD_PARAM,Y	; zero sync flags
			dey					; 
			bpl	_BECB1				; 

			sty	JIM+SNDWKSP_SYNC_CHANS		; number of channels to &FF
			bmi	_BED06				; jump to ED06 ALWAYS

_BECBC:			php					; save flags
			sei					; and disable interrupts
			lda	JIM+SNDWKSP_AMP_PHASE_CUR,X	; check for end of release
			cmp	#$04				; 
			bne	_BECCF				; and if not found ECCF
			jsr	REMV_internal_SEV		; elseexamine buffer
			bcc	_BECCF				; if not empty ECCF
			lda	#$00				; else mark channel dormant
			sta	JIM+SNDWKSP_QUEUE_OCC,X		; 
_BECCF:			plp					; get back flags

_LECD0:			ldy	JIM+SNDWKSP_ENVELOPE_OFFS,X	; if no envelope 820=&FF
			cpy	#$ff				; 
			bne	_BECDA				; then terminate sound
			jsr	_LEB03				; via EB03
_BECDA:			rts					; else return

;************ Synchronise sound routines **********************************

_BECDB:			jsr	REMV_internal_SEV		; examine buffer if empty carry set
			bcs	_BECBC				; 
			and	#$07				; else examine next word if>3 or 0 DB: 7 is max sync
			beq	_BEC9F				; goto ED98 (via EC9F)
			lda	JIM+SNDWKSP_SYNC_CHANS		; else get synchronising count
			beq	_BECFE				; in 0 (complete) goto ECFE
			inc	JIM+SNDWKSP_SYNC_FLAG,X		; else set sync flag
			bit	JIM+SNDWKSP_SYNC_CHANS		; if 0838 is +ve S has already been set so
			bpl	_BECFB				; jump to ECFB
			jsr	REMV_internal_SEV		; else get first byte
			and	#$07				; mask bits 0,1			DB: 7 is max sync
			sta	JIM+SNDWKSP_SYNC_CHANS		; and store result
			bpl	_BECFE				; Jump to ECFE (ALWAYS!!)

_BECFB:			dec	JIM+SNDWKSP_SYNC_CHANS		; decrement 0838
_BECFE:			jmp	_LECD0				; and silence the channel if envelope not in use

;************ Pitch setting ***********************************************

	;; TODO: is this needed? If it is need to reset it when new note played?

_LED01:		;	cmp	JIM+SNDWKSP_SYNC_HOLD_PARAM,X	; If A=&82C,X then pitch is unchanged
		;	beq	_BECDA				; then exit via ECDA
_BED06:			sta	JIM+SNDWKSP_SYNC_HOLD_PARAM,X	; store new pitch


; DB: removed stuff for noise
			jsr	pitch2period
			jmp	_LEB22





;**************** Pick up and interpret sound buffer data *****************

_LED98:			php					; push flags
			sei					; disable interrupts
			jsr	REMV_internal_CLV		; read a byte from buffer
			pha					; push A
			and	#$08				; isolate H bit
			beq	_BEDB7				; if 0 then EDB7
			pla					; get back A
			ldy	JIM+SNDWKSP_ENVELOPE_OFFS,X	; if &820,X=&FF
			cpy	#$ff				; envelope is not in use
			bne	_BEDAD				; 
			jsr	_LEB03				; so call EB03 to silence channel

_BEDAD:			jsr	REMV_internal_CLV		; clear buffer of redundant data
			jsr	REMV_internal_CLV		; and again
			jsr	REMV_internal_CLV		; and again
			plp					; get back flags
			jmp	_LEDF7				; set main duration count using last byte from buffer

_BEDB7:			;DB: This bit different to load sample # into table
			jsr	REMV_internal_CLV		; DB: get next byte contains env flag and sample #
			pha
			and	#$7f
			ora	#$80
			sta	JIM+SNDWKSP_SAMPLE_NO,X		; DB: store sample #
			pla
			bpl	_BEDC8				; DB: envelope detected
			

			pla					; get back A
			and	#$f0				; zero bits 0-3
			eor	#$ff				; invert A
			lsr	A				; shift right
			sec					; 
			sbc	#$40				; subtract &40
			jsr	_LEB0A				; and set volume
			lda	#$ff				; A=&FF
			bne	_BEDC8_2

_BEDC8:			pla
			and 	#$f0

_BEDC8_2:		sta	JIM+SNDWKSP_ENVELOPE_OFFS,X	; get envelope no.-1 *16 into A
			lda	#$05				; set duration sub-counter
			sta	JIM+SNDWKSP_DURATION_SUB,X	; 
			lda	#$01				; set phase counter
			sta	JIM+SNDWKSP_ENV_STEPREPEAT,X	; 
			lda	#$00				; set step counter
			sta	JIM+SNDWKSP_PITCH_PH_STEPS,X	; 
			sta	JIM+SNDWKSP_AMP_PHASE_CUR,X	; and envelope phase
			sta	JIM+SNDWKSP_PITCH_SETTING,X	; and pitch differential
			lda	#$ff				; 
			sta	JIM+SNDWKSP_PITCH_PHASE_CUR,X	; set step count
			jsr	REMV_internal_CLV		; read pitch
			sta	JIM+SNDWKSP_AMP_BASE_PITCH,X	; set it
			jsr	REMV_internal_CLV		; read buffer
			plp					; 
			pha					; save duration
			lda	JIM+SNDWKSP_AMP_BASE_PITCH,X	; get back pitch value
			jsr	_LED01				; and set it
			pla					; get back duration
_LEDF7:			sta	JIM+SNDWKSP_DURATION,X		; set it
			rts					; and return



_LEB03:	; set volume to zero and end envelope
			lda	#$04				; mark end of release phase
			sta	JIM+SNDWKSP_AMP_PHASE_CUR,X	; to channel X
			lda	#$c0				; load code for zero volume
			sta	JIM+SNDWKSP_AMP_CUR,X
			jsr	jimPageChipset
			stx	jim_DMAC_SND_SEL
			cpx	jim_DMAC_SND_SEL
			bne	@nochan				; check channel selected
			lda	#0
			sta	jim_DMAC_SND_VOL		; zero volume
			sta	jim_DMAC_SND_DATA		; zero output
			sta	jim_DMAC_SND_STATUS		; stop sound
@nochan:		jmp	jimPageSoundWorkspace

_LEB0A: ; set volume
			sta	JIM+SNDWKSP_AMP_CUR,X		; store A to give basic sound level of Zero
			and	#$78
			clc
			adc	#$40
			asl	A
			jsr	jimPageChipset
			stx	jim_DMAC_SND_SEL
			cpx	jim_DMAC_SND_SEL
			bne	@nochan				; check channel selected
			sta	jim_DMAC_SND_VOL
@nochan:		jmp	jimPageSoundWorkspace

_LEB22: ; set period
			lda	JIM+SNDWKSP_FREQ_LO
			pha
			lda	JIM+SNDWKSP_FREQ_HI
			pha
			txa
			pha					; save channel number
			lda	JIM+SNDWKSP_SAMPLE_NO,X
			pha
			lda	#0
			sta	JIM+SNDWKSP_SAMPLE_NO,X		; mark that we've set up sample


			jsr	jimPageChipset
			stx	jim_DMAC_SND_SEL
			cpx	jim_DMAC_SND_SEL		; check to see that channel is actually set
			bne	@nochan


			pla
			bpl	@nosampleneeded			; check to see if sample is set, if clear assume
								; has already been done
			;	get sample number to X
			asl	A
			asl	A
			asl	A
			tax
			;	look up sample info from sample table

			jsr	jimPageSamTbl
			lda	JIM+SAMTBLOFFS_BASE+1,X
			bmi	@nosample
			pha
			lda	JIM+SAMTBLOFFS_BASE,X
			pha
			lda	JIM+SAMTBLOFFS_LEN+1,X
			pha
			lda	JIM+SAMTBLOFFS_LEN,X
			pha
			lda	JIM+SAMTBLOFFS_REPL+1,X
			pha
			lda	JIM+SAMTBLOFFS_REPL,X
			pha
			lda	JIM+SAMTBLOFFS_FLAGS,X


			jsr	jimPageChipset			; page in chipset

			rol	A				; cy has repeat flag

			lda	#0
			sta	jim_DMAC_SND_ADDR+2		; low byte always on page boundary
			pla	
			sta	jim_DMAC_SND_REPOFF+1
			pla	
			sta	jim_DMAC_SND_REPOFF
			pla	
			sta	jim_DMAC_SND_LEN+1
			pla	
			sta	jim_DMAC_SND_LEN
			pla	
			sta	jim_DMAC_SND_ADDR+1
			pla	
			sta	jim_DMAC_SND_ADDR+0

			pla
			tax					; get back channel #

			pla
			sta	jim_DMAC_SND_PERIOD
			pla
			sta	jim_DMAC_SND_PERIOD+1		; set period

			lda	#$40
			rol	A				; carry flag from above - repeat flag
			sta	jim_DMAC_SND_STATUS		; start sound playing
			jmp	jimPageSoundWorkspace


@nosampleneeded:
			pla
			tax					; get back channel #

			jsr	jimPageChipset			; page in chipset
			pla
			sta	jim_DMAC_SND_PERIOD
			pla
			sta	jim_DMAC_SND_PERIOD+1		; set period
			jmp	jimPageSoundWorkspace

@nochan:		pla
@nosample:	
			pla
			tax
			pla
			pla					; discard pushed values
			jmp	jimPageSoundWorkspace		; exit
