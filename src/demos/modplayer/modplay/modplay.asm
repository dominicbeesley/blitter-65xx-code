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

;TODO: 	mode 7 earlier when scrolling causes code corruption
;	jimprobe store in my_jim during probe	

; (c) Dossytronics/Dominic Beesley 2019

;test problems with simultaneous sound and blit

; build parameters
BUILD_TIMER_VSYNC	:=0					; when 1 uses EVENT 4 vsync, else uses user 
							; via timer1 which allowes tempo adjustment
SCREEN_BASE		:= $7C00
SCREEN_LOGO		:= SCREEN_BASE + (25-8)*40
SCREEN_LOGO_END		:= SCREEN_BASE + 2048

AERIS_LIST_ADDR		:= $008000	; shadow rom ? TODO: move this somewhere?

		.include	"oslib.inc"
		.include	"common.inc"
		.include	"hardware.inc"
		.include	"mosrom.inc"
		.include	"aeris.inc"

		.include	"modplay.inc"

		.import		mod_load
		.import		PrHexA
		.importzp	zp_ld_tmp
		.importzp	zp_ld_cmdline

		.export		mod_data
		.export		sam_data
		.export		g_song_len
		.export		song_data
		.export		my_jim_dev
		.export		song_name
		.export		play_event
		.export		here


		.ZEROPAGE


zp_si_ptr:	.res 2		; sample info ptr	(used as text pointer when reading cmd line)
zp_pattern_ptrl:.res 3		; pointer to next row in current pattern in chipram
zp_note_ptr:	.res 2		; note info ptr	
zp_cha_var_ptr:	.res 2
zp_cha_ctr:	.res 1
zp_tmp:		.res 4
zp_num1:	.res 2					; used in mul
zp_num2:	.res 2
zp_d24_remain	:= zp_tmp				; remainder of 24x8 divide
zp_d24_dividend	:= zp_tmp+3				; result of 24x8 divide
zp_d24_divisor8	:= zp_tmp+6				; the 8 bit divisor
zp_d24_tmp	:= zp_tmp+7				; the temp variable for div24x8


; tracker display
zp_scr_ptr:	.res 2
zp_disp_tmp_ptr:.res 2
zp_disp_lin_ctr:.res 1
zp_disp_row_num:.res 1
zp_disp_tmp:	.res 1
zp_disp_lp:	.res 1
zp_disp_per:	.res 2
zp_disp_oct:	.res 1
zp_disp_peak:	.res 1


		.CODE 
start:
		; scan command line for module name
		lda	#OSARGS_cmdtail
		ldy	#0
		ldx	#zp_ld_cmdline
		jsr	OSARGS
		jmp	start2

start_noice:	lda	zp_mos_txtptr
		sta	zp_ld_cmdline
		lda	zp_mos_txtptr+1
		sta	zp_ld_cmdline+1

start2:

		lda	#0
		sta	my_jim_dev

		; get filename from command line into XY for OSFIND
		dey
@again:
		
@lp1:		iny
		lda	(zp_ld_cmdline),Y
		cmp	#' '
		beq	@lp1
		cmp	#'-'
		bne	@nodev
		iny
		jsr	ParseHex
		bcc	@again
		jmp	@bkbad
@nodev:
		sty	zp_ld_tmp			; start of filename
@lp2:		iny
		lda	(zp_ld_cmdline),Y
		cmp	#' '+1
		bcs	@lp2
		cpy	zp_ld_tmp
		beq	@bkbad
		lda	#$D
		sta	(zp_ld_cmdline),Y
		clc
		lda	zp_ld_tmp
		adc	zp_ld_cmdline
		sta	filename
		lda	zp_ld_cmdline+1
		adc	#0
		sta	filename+1

		;	switch to jim device and stay switched throughout
		lda	zp_mos_jimdevsave
		sta	old_jim_dev

		lda	my_jim_dev
		beq	@probeall

		jsr	jimProbe
		beq	@probeok
		jmp	@probenotok
@probeall:
		lda	#JIM_DEVNO_BLITTER
		jsr	jimProbe
		beq	@probeok

		lda	#JIM_DEVNO_HOG1MPAULA
		jsr	jimProbe
		bne	@probenotok

@probeok:	
		sta	my_jim_dev

		; *TV 255 0
		lda	#$90
		ldx	#$FF
		ldy	#$1
		jsr	OSBYTE

		; change to mode 7
		lda	#22
		jsr	OSWRCH
		lda	#7
		jsr	OSWRCH

		lda	#0
		sta	g_aeris


		ldx	filename
		ldy	filename+1

		jsr	mod_load

		jsr	snd_devsel
		
		jsr	cls
@here:
		jsr	play_init
		jsr	play_loop

		brk
		.byte	5, "How did this happen!",0
@bkbad:		brk
		.byte	1, "Bad parameters: MODPLAY [-D0|-D1|<dev>] filename"
		brk
@probenotok:
		jsr	jimRestore
		brk	
		.byte	2, "Device not found", 0

here := @here


jimProbe:	pha
		PRINT	"probing "
		pla
		pha

		jsr	PrHexA

		pla
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO
		eor	#$FF
		eor	fred_JIM_DEVNO
		bne	jimProbefail
		php
		PRINTL	" OK"
		lda	zp_mos_jimdevsave
		plp
		rts
jimProbefail:	php
		PRINTL	" NO"
		lda	zp_mos_jimdevsave
		plp
		rts





jimRestore:
		; restore JIM
		lda	old_jim_dev
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO
		rts


ParseHex:
ParseHexLp:	lda	(zp_ld_cmdline),Y
		jsr	 OSWRCH
		iny
		jsr	ToUpper
		cmp	#' '+1
		bcc	ParseHexDone
		cmp	#'0'
		bcc	ParseHexErr
		cmp	#'9'+1
		bcs	ParseHexAlpha
		sec
		sbc	#'0'
ParseHexShAd:	asl	my_jim_dev
		asl	my_jim_dev
		asl	my_jim_dev
		asl	my_jim_dev			; multiply existing number by 16
		clc
		adc	my_jim_dev
		sta	my_jim_dev			; add current digit
		jmp	ParseHexLp
ParseHexAlpha:	cmp	#'A'
		bcc	ParseHexErr
		cmp	#'F'+1
		bcs	ParseHexErr
		sbc	#'A'-11				; note carry clear 'A'-'F' => 10-15
		jmp	ParseHexShAd
ParseHexErr:	sec
		rts
ParseHexDone:	dey
		clc
		rts
ToUpper:	cmp	#'a'
		bcc	@1
		cmp	#'z'+1
		bcs	@1
		and	#$DF
@1:		rts



handle_EVNTV:
		php
		cmp	#EVENT_NUM_4_VSYNC
		bne	@s1
		pha
		txa
		pha
		tya
		pha

		; we need to reselect the device here as this is an interrupt _and_ we need to preserve device 
		; paging registers

		lda	zp_mos_jimdevsave
		pha
		lda	my_jim_dev
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO
		lda	fred_JIM_PAGE_LO
		pha
		lda	fred_JIM_PAGE_HI
		pha

		jsr	snd_devsel

		lda	g_aeris
		beq	@A1
		jsr	aeris_vu
@A1:

	.if BUILD_TIMER_VSYNC
		jsr	play_event
	.endif

		lda	my_jim_dev
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO

		; reset device 
		pla
		sta	fred_JIM_PAGE_HI
		pla
		sta	fred_JIM_PAGE_LO
		pla
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO


		pla
		tay
		pla
		tax
		pla
@s1:		
		plp
		jmp	(old_EVNTV)



	.if !BUILD_TIMER_VSYNC  ; BUILD_TIMER_VSYNC=0 - use timer 1
handle_IRQ2V:
		; do check first
		bit	sheila_USRVIA_ifr
		bvc	@sk_no_t1

		lda	zp_mos_INT_A
		pha
		txa
		pha
		tya
		pha

		lda	zp_mos_jimdevsave
		pha
		lda	my_jim_dev
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO
		lda	fred_JIM_PAGE_LO
		pha
		lda	fred_JIM_PAGE_HI
		pha

		; clear interrupt
		lda	sheila_USRVIA_t1cl

		jsr	play_event

		lda	my_jim_dev
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO

		; reset device 
		pla
		sta	fred_JIM_PAGE_HI
		pla
		sta	fred_JIM_PAGE_LO
		pla
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO


		pla
		tay
		pla
		tax
		pla
		sta	zp_mos_INT_A

@sk_no_t1:	jmp	(old_IRQ2V)
	.endif

;-------------------------------------------------------------
; tracker loop
;-------------------------------------------------------------
play_loop:
		; wait for player to execute

		sei
		lda	g_flags
		and	#FLAGS_EXEC ^ $FF
		sta	g_flags
		CLI

		lda	#FLAGS_EXEC
@l1:		bit	g_flags
		beq	@l1

		lda	display_state
		cmp	#DISP_HELP
		beq	@skip_disp
		jsr	track_disp
		lda	display_state
		cmp	#DISP_DEBUG
		bne	@skip_notdebug
		jsr	debug_display
		jmp	@skip_disp
@skip_notdebug:

@skip_disp:

		; keyboard

		ldx	#0
		ldy	#0
		lda	#$81
		jsr	OSBYTE
		bcs	@nokeys
		txa
		jsr	ToUpper
		ldx	#0
@klkuploop:	cmp	keyfntab,X
		bne	@sk1
		jsr	dokey_fn
		jmp	@donekey
@sk1:		inx
		inx
		inx
		cpx	#keyfntablen
		bcc	@klkuploop

@nokeys:
		cpy	#27
		bne	@donekey

		jsr	play_exit

		lda	#OSBYTE_126_ESCAPE_ACK		; ack escape
		jsr	OSBYTE

		lda	g_aeris
		beq	@sa
		jsr	aeris_off
@sa:		
		jsr	jimRestore

		brk
		.byte	27
		.byte	"ESCAPE", 0
@donekey:
		jmp	play_loop

snd_devsel:	php
		pha
		lda	#>jim_page_CHIPSET
		sta	fred_JIM_PAGE_HI
		lda	#<jim_page_CHIPSET
		sta	fred_JIM_PAGE_LO
		pla
		plp
		rts

silence:
		jsr	snd_devsel
		ldx	#3
		lda	#0
@l1:		stx	jim_CS_SND_SEL
		sta	jim_CS_SND_STATUS
		dex
		bpl	@l1
		rts

play_exit:
		; exit

		lda	#OSBYTE_13_DISABLE_EVENT
		ldx	#EVENT_NUM_4_VSYNC
		jsr	OSBYTE


		sei
		lda	old_EVNTV
		sta	EVNTV
		lda	old_EVNTV+1
		sta	EVNTV+1
		cli
	.if !BUILD_TIMER_VSYNC
		sei

		lda	#VIA_IFR_BIT_T1
		sta	sheila_USRVIA_ier		; turn off T1 interrupts

		lda	old_IRQ2V
		sta	IRQ2V
		lda	old_IRQ2V+1
		sta	IRQ2V+1


		cli
	.endif

		lda	my_jim_dev
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO

		jsr	silence
		rts


;-------------------------------------------------------------
; Init tracker variables
;-------------------------------------------------------------

play_init:



		ldx	#$FF
		stx	g_song_pos
		stx	g_patt_brk
		inx
		stx	g_pat_rep
		stx	g_arp_tick
		stx	g_flags
		ldx	#6
		stx	g_speed
		dex
		stx	g_tick_ctr
		ldx	#63
		stx	g_row_pos


		; zero all cha_vars
		ldx	#(.SIZEOF(s_cha_vars)*4)-1
		lda	#0
@pilp:		sta	cha_vars,X
		dex
		bpl	@pilp

		php
		sei
		lda	EVNTV
		sta	old_EVNTV
		lda	EVNTV+1
		sta	old_EVNTV+1

		lda	#<handle_EVNTV
		sta	EVNTV
		lda	#>handle_EVNTV
		sta	EVNTV+1

		lda	#OSBYTE_14_ENABLE_EVENT
		ldx	#EVENT_NUM_4_VSYNC
		jsr	OSBYTE
	.if !BUILD_TIMER_VSYNC

		lda	IRQ2V
		sta	old_IRQ2V
		lda	IRQ2V+1
		sta	old_IRQ2V+1

		lda	#<handle_IRQ2V
		sta	IRQ2V
		lda	#>handle_IRQ2V
		sta	IRQ2V+1


		; setup User VIA T1 to generate interrupts

		ldx	#125
		jsr	more_effects_set_tempo		; set default temp to 125

		lda	sheila_USRVIA_acr
		and	#$3F
		ora	#$40
		sta	sheila_USRVIA_acr		; T1 free run mode

		lda	#VIA_IFR_BIT_T1 + VIA_IFR_BIT_ANY
		sta	sheila_USRVIA_ier		 ;enable T1 interrupt

	.endif

		plp					; restore interrupts and containue
		rts

play_key_song_prev:
		dec	g_song_pos		
		lda	#0
		sta	g_song_skip
		jmp	restart_thispat
play_key_song_next:
		inc	g_song_pos		
		lda	#0
		sta	g_song_skip
		jmp	restart_thispat

init_cha_ptr:
		ldx	#<cha_vars
		ldy	#>cha_vars
		stx	zp_cha_var_ptr
		sty	zp_cha_var_ptr+1
		ldx	#0
		stx	zp_cha_ctr
		rts

next_cha_cha_var_ptr:
		inc	zp_cha_ctr
		lda	zp_cha_var_ptr
		clc
		adc	#.SIZEOF(s_cha_vars)
		sta	zp_cha_var_ptr
		bcc	@sc
		inc	zp_cha_var_ptr + 1
@sc:		lda	#4
		cmp	zp_cha_ctr
		rts

;-------------------------------------------------------------
; event driven player, call this 50 times a second
;-------------------------------------------------------------
play_event:
		lda	#FLAGS_key_pause
		bit	g_flags
		beq	@s0
		jmp	play_event_paused			; key_pause
@s0:
		jsr	snd_devsel

		inc	g_tick_ctr
		ldx	g_tick_ctr
		cpx	g_speed		
		bcs	@s1
		jmp	play_skip_read_row
@s1:

		; check for next/prev song keys
		bit	g_song_skip
		bvs	play_key_song_prev
		bmi	play_key_song_next



		; read a row
		ldx	#0
		stx	g_tick_ctr
		stx	g_arp_tick
		lda	g_patt_brk
		bmi	@s3
		sta	g_row_pos
		lda	#$FF
		sta	g_patt_brk
		bne	@s2
@s3:		inc	g_row_pos
		ldx	g_row_pos
		cpx	#64
		bcc	sk_no_next_patt
		lda	#0
		sta	g_row_pos
		; move to next pattern
@s2:		bit	g_pat_rep
		bmi	restart_thispat

		inc	g_song_pos
		; TODO - end of song detect / loop
restart_thispat:
		lda	g_song_pos
@restart:	jsr	lookup_song
		sta	g_pattern
		bpl	@skrestart
		;jsr	silence
		lda	#0
		sta	g_song_pos
		beq	@restart
@skrestart:	jsr	start_pattern
sk_no_next_patt:
		jsr	init_cha_ptr
		jsr	get_pattern_row

channel_loop:		
		ldx	zp_cha_ctr		
		stx	jim_CS_SND_SEL

		; save peak and reset
		ldy	#s_cha_vars::cha_var_peak
		lda	jim_CS_SND_PEAK
		sta	(zp_cha_var_ptr),Y
		sta	jim_CS_SND_PEAK		; reset


		ldy	#s_cha_vars::cha_var_restart
		lda	#0
		sta	(zp_cha_var_ptr),Y

		; get sample #
		ldy	#0
		lda	(zp_note_ptr),Y
		rol	A				; get top bit of sample # in Cy
		rol	A
		rol	A
		rol	A
		ldy	#2
		lda	(zp_note_ptr),Y
		and	#$F0
		ror	a
		beq	@sk_samno
@gotasample:
		ldy	#s_cha_vars::cha_var_sn
		sta	(zp_cha_var_ptr),Y
		tax	
		; copy sample data to vars
		ldy	#s_cha_vars::cha_var_s_len
@cplp:		lda	sam_data,X		; sample info table
		sta	(zp_cha_var_ptr),Y
		inx
		iny
		cpy	#s_cha_vars::cha_var_s_repfl + 1
		bne	@cplp
		and	#$3F
		ldy	#s_cha_vars::cha_var_vol
		sta	(zp_cha_var_ptr), Y
		ldy	#s_cha_vars::cha_var_restart
		lda	#$FF
		sta	(zp_cha_var_ptr),Y


@sk_samno:	; save command and params in channel vars
		ldy	#2
		lda	(zp_note_ptr),Y
		and	#$0F
		ldy	#s_cha_vars::cha_var_cmd
		sta	(zp_cha_var_ptr),Y
		ldy	#3
		lda	(zp_note_ptr),Y
		ldy	#s_cha_vars::cha_var_parm
		sta	(zp_cha_var_ptr),Y

		; check to see if there's a period
		ldy	#0
		lda	(zp_note_ptr),Y
		and	#$0F
		sta	tmp_note_per

		ldy	#1
		lda	(zp_note_ptr),Y
		sta	tmp_note_per + 1
		ora	tmp_note_per

		beq	@sk_period

		; check for finetune
		ldy	#s_cha_vars::cha_var_s_addr_b
		lda	(zp_cha_var_ptr),Y
		and	#$F0				; get sample fintune
		beq	@nofinetune

		lsr	A
		lsr	A
		lsr	A
		tax
		lda	finetunetab, X
		sta	zp_num1
		lda	finetunetab+1, X
		sta	zp_num1+1
		lda	tmp_note_per+1			; big endian!
		sta	zp_num2
		lda	tmp_note_per+0
		sta	zp_num2+1

		jsr	mul16

		rol	zp_tmp+1
		lda	zp_tmp+2
		rol	A
		sta	tmp_note_per+1
		lda	zp_tmp+3
		rol	A
		sta	tmp_note_per+0			; big endian

@nofinetune:
		ldy	#s_cha_vars::cha_var_restart	; restart sample
		lda	#$FF
		sta	(zp_cha_var_ptr),Y


		ldy	#s_cha_vars::cha_var_cmd
		lda	(zp_cha_var_ptr),Y

		cmp	#3
		beq	@setporta_j
		cmp	#5
		bne	@sksk
@setporta_j:	jmp	@setporta
@sksk:


		lda	tmp_note_per
		ldy	#s_cha_vars::cha_var_per
		sta	(zp_cha_var_ptr),Y
		lda	tmp_note_per + 1
		iny
		sta	(zp_cha_var_ptr),Y		

		ldy	#s_cha_vars::cha_var_vib_pos
		lda	#0
		sta	(zp_cha_var_ptr),Y

@sk_period:	ldy	#s_cha_vars::cha_var_restart
		lda	(zp_cha_var_ptr),Y
		bne	@s_sample
@j_sj_nosample:	jmp	@sk_nosample
@s_sample:

		ldy	#s_cha_vars::cha_var_sn
		lda	(zp_cha_var_ptr),Y
		beq	@j_sj_nosample			; no sample info set

		; stop current sample
		lda	#0
		sta	jim_CS_SND_STATUS

		jsr	set_p_period
		ldy	#s_cha_vars::cha_var_restart
		lda	#$FF
		sta	(zp_cha_var_ptr),Y

		ldy	#s_cha_vars::cha_var_s_len + 1
		lda	(zp_cha_var_ptr),Y
		dey
		ora	(zp_cha_var_ptr),Y
		beq	@sk_nosample

		iny
		lda	(zp_cha_var_ptr),Y
		sta	jim_CS_SND_LEN
		dey
		lda	(zp_cha_var_ptr),Y
		sta	jim_CS_SND_LEN + 1
		
		ldy	#s_cha_vars::cha_var_s_roff + 1
		lda	(zp_cha_var_ptr),Y
		sta	jim_CS_SND_REPOFF
		dey
		lda	(zp_cha_var_ptr),Y
		sta	jim_CS_SND_REPOFF + 1
		
		ldy	#s_cha_vars::cha_var_s_addr_b
		lda	(zp_cha_var_ptr),Y
		and	#$0F					; blank out finetune
		sta	jim_CS_SND_ADDR + 2
		iny
		lda	(zp_cha_var_ptr),Y
		sta	jim_CS_SND_ADDR + 1
		iny
		lda	(zp_cha_var_ptr),Y
		sta	jim_CS_SND_ADDR + 0
		iny
		lda	(zp_cha_var_ptr),Y
		rol	a				; get repeat flag into bit 0
		rol	a
		and	#1
		sta	zp_tmp				; save repeat flag

;----------------------------------------------
; effect 9
;----------------------------------------------


		; check for effect #9 - sample offset
		ldy	#s_cha_vars::cha_var_cmd
		lda	(zp_cha_var_ptr),Y
		cmp	#9
		bne	@sknosampleoffset

		lda	jim_CS_SND_LEN + 1
		sec
		ldy	#s_cha_vars::cha_var_parm
		sbc	(zp_cha_var_ptr),Y
		bcc	@sk_nosample
		sta	jim_CS_SND_LEN + 1

		; adjust repeat offset
		lda	zp_tmp
		bne	@sksampleoffset_norepl

		lda	jim_CS_SND_REPOFF + 1		; hi byte of repeat offset
		sbc	(zp_cha_var_ptr),Y		; note Y and Cy already set above
		sta	jim_CS_SND_REPOFF + 1
		bcs	@sksampleoffset_norepl

		lda	#0				; if we're here the note sample offset has overflowed the repeat offset
		sta	zp_tmp				; clear repeat flag

@sksampleoffset_norepl:
		lda	jim_CS_SND_ADDR+1
		clc
		ldy	#s_cha_vars::cha_var_parm
		adc	(zp_cha_var_ptr),Y
		sta	jim_CS_SND_ADDR+1
		bcc	@sknosampleoffset_carry
		inc	jim_CS_SND_ADDR+2
@sknosampleoffset_carry:

@sknosampleoffset:
		lda	zp_tmp				; get back repeat flag
		ora	#$80
		sta	jim_CS_SND_STATUS
@sk_nosample:	jsr	check_more_effects
		jsr	set_p_vol

		lda	zp_note_ptr
		clc
		adc	#4
		sta	zp_note_ptr
		bcc	@sc
		inc	zp_note_ptr + 1
@sc:

		inc	zp_cha_ctr
		ldx	zp_cha_ctr
		cpx	#4
		bne	@ss2
		jmp	play_skip_read_row_done
@ss2:		lda	zp_cha_var_ptr
		adc	#.SIZEOF(s_cha_vars)
		sta	zp_cha_var_ptr
		bcc	@sc2
		inc	zp_cha_var_ptr + 1
@sc2:
		jmp	channel_loop

@setporta:	lda	tmp_note_per
		ldy	#s_cha_vars::cha_var_porta_per
		sta	(zp_cha_var_ptr),Y
		iny
		lda	tmp_note_per+1
		sta	(zp_cha_var_ptr),Y
		jmp	@sk_period

check_more_effects:

		ldy	#s_cha_vars::cha_var_parm
		lda	(zp_cha_var_ptr),Y
		tax
		ldy	#s_cha_vars::cha_var_cmd
		lda	(zp_cha_var_ptr),Y
		
		cmp	#$C
		beq	more_effects_set_vol
		cmp	#$F
		beq	more_effects_set_speed

		cmp	#$E
		beq	command_E

		rts

command_E:	txa
		and	#$F0
		cmp	#$A0
		bne	@sb
;command_EA_volup:
		txa
		and	#$0F
		jmp	addA2vol		
@sb:		cmp	#$B0
		bne	@sex
;command_EB_voldn:
		txa
		and	#$0F
		jmp	subA2vol
@sex:		rts



more_effects_set_vol:
		txa
		cmp	#$40
		bcc	@s1
		lda	#$3F
@s1:		ldy	#s_cha_vars::cha_var_vol
		sta	(zp_cha_var_ptr),Y
		rts

more_effects_set_speed:
		cpx	#$20
		bcs	more_effects_set_tempo
		stx	g_speed
		rts
more_effects_set_tempo:
		stx	zp_d24_divisor8		
		lda	#$A0				; number here is LE 125*1000000/50 = 2,500,000 = $2625A0
		sta	zp_d24_dividend
		lda	#$25
		sta	zp_d24_dividend+1
		lda	#$26
		sta	zp_d24_dividend+2
		jsr	div24x8
		lda	zp_d24_dividend+2
		bne	@sk_slow

		lda	zp_d24_dividend
		sta	sheila_USRVIA_t1cl
		lda	zp_d24_dividend+1
		sta	sheila_USRVIA_t1ch
		rts

@sk_slow:	lda	#$FF
		sta	sheila_USRVIA_t1cl
		sta	sheila_USRVIA_t1ch
		rts

j_effects_vib:
		jmp	effects_vib
j_effects_vib_vol_slide:
		jmp	effects_vib_vol_slide



check_effects:
		ldy	#s_cha_vars::cha_var_parm
		lda	(zp_cha_var_ptr),Y
		tax
		ldy	#s_cha_vars::cha_var_cmd
		lda	(zp_cha_var_ptr),Y
		
		beq	effects_arpeg
		cmp	#$1
		beq	effects_porta_up
		cmp	#$2
		beq	effects_porta_dn
		cmp	#$3
		beq	effects_set_tone_porta
		cmp	#$4
		beq	j_effects_vib		
		cmp	#$5
		beq	effects_tone_porta_vol_slide
		cmp	#$6
		beq	j_effects_vib_vol_slide
		cmp	#$A
		beq	effects_volume_slide
		cmp	#$D
		beq	effects_pattern_break
		rts


effects_pattern_break:
		txa					; this is in BCD! convert to binary
		pha
		lsr	a
		lsr	a
		lsr	a
		lsr	a
		sta	zp_num1
		lda	#10
		sta	zp_num2
		jsr	mul8
		pla
		and	#$0F
		clc
		adc	zp_tmp

		sta	g_patt_brk
		rts

effects_arpeg:
		jmp	do_arpeg

effects_set_tone_porta:
		txa
		beq	@s
		ldy	#s_cha_vars::cha_var_porta_speed
		sta	(zp_cha_var_ptr),Y
@s:		jmp	do_tone_porta
effects_tone_porta_vol_slide:
		jsr	do_tone_porta
		jmp	effects_volume_slide

effects_porta_up:
		ldy	#s_cha_vars::cha_var_per + 1
		stx	zp_tmp
		sec
		lda	(zp_cha_var_ptr),Y
		sbc	zp_tmp
		sta	(zp_cha_var_ptr),Y
		dey
		lda	(zp_cha_var_ptr),Y
		sbc	#0
		sta	(zp_cha_var_ptr),Y
		bcc	@reset113	
		bne	@s
		iny	
		lda	(zp_cha_var_ptr),Y
		cmp	#113
		bcs	@s
@reset113:	ldy	#s_cha_vars::cha_var_per + 1
		lda	#0
		sta	(zp_cha_var_ptr),Y
		iny
		lda	#113
		sta	(zp_cha_var_ptr),Y
@s:		jmp	set_p_period

effects_porta_dn:
		ldy	#s_cha_vars::cha_var_per + 1
		stx	zp_tmp
		clc
		lda	(zp_cha_var_ptr),Y
		adc	zp_tmp
		sta	(zp_cha_var_ptr),Y
		dey
		lda	(zp_cha_var_ptr),Y
		adc	#0
		sta	(zp_cha_var_ptr),Y
		bcc	@s
		lda	#$FF
		sta	(zp_cha_var_ptr),Y
		iny
		sta	(zp_cha_var_ptr),Y
@s:		jmp	set_p_period


effects_volume_slide:
		txa
		and	#$F0
		bne	lsr4addA2vol
		txa
		and	#$0F
		beq	effects_volume_slide_rts
subA2vol:
		ldy	#s_cha_vars::cha_var_vol
		clc
		sbc	(zp_cha_var_ptr),Y
		eor	#$FF
		bpl	effects_volume_slide_store
		lda	#0
effects_volume_slide_store:
		sta	(zp_cha_var_ptr),Y
effects_volume_slide_rts:
		rts
lsr4addA2vol:	lsr	a
		lsr	a
		lsr	a
		lsr	a
addA2vol:
		ldy	#s_cha_vars::cha_var_vol
		clc
		adc	(zp_cha_var_ptr),Y
		cmp	#63
		bcc	effects_volume_slide_store
		lda	#63
		bne	effects_volume_slide_store



effects_vib:						; TODO - always sine
		ldy	#s_cha_vars::cha_var_vib_cmd
		txa
		and	#$F0
		beq	@s1				; don't set speed if not specd
		sta	zp_tmp
		lda	(zp_cha_var_ptr),Y
		and	#$0F
		ora	zp_tmp
		sta	(zp_cha_var_ptr),Y
@s1:		txa
		and	#$0F
		beq	@s2				; don't set depth if not specd
		sta	zp_tmp
		lda	(zp_cha_var_ptr),Y
		and	#$F0
		ora	zp_tmp
		sta	(zp_cha_var_ptr),Y
@s2:
effects_do_vib:
		
		; do the vibrato
		ldy	#s_cha_vars::cha_var_vib_pos
		lda	(zp_cha_var_ptr),Y
		lsr	a
		lsr	a
		and	#$1F				; make table index
		tax
		lda	vibtab,X
		sta	zp_num1

		ldy	#s_cha_vars::cha_var_vib_cmd
		lda	(zp_cha_var_ptr),Y
		and	#$0F
		sta	zp_num2
		jsr	mul8
		asl	zp_tmp
		rol	a				; A = tab value*depth/128
		sta	zp_tmp
		lda	#0
		sta	zp_tmp+1
		dey
		lda	(zp_cha_var_ptr),Y
		bmi	@s1				; either add or subtract depending on sign 
		jsr	neg_tmp				; negate table value (make a 32 byte table into a 64 by symmetry)		
@s1:		clc
		ldy	#s_cha_vars::cha_var_per+1	; lo byte (be)
		lda	(zp_cha_var_ptr),Y
		adc	zp_tmp
		sta	zp_tmp
		dey
		lda	(zp_cha_var_ptr),Y		; hi byte (be)
		adc	zp_tmp+1
		sta	zp_tmp+1
		jsr 	set_p_period_zp_tmp

		ldy	#s_cha_vars::cha_var_vib_cmd
		lda	(zp_cha_var_ptr),Y
		and	#$F0
		lsr	a
		lsr	a
		clc
		dey
		adc	(zp_cha_var_ptr),Y		; vib pos
		sta	(zp_cha_var_ptr),Y
		rts

neg_tmp:
		sec
		lda	#0
		sbc	zp_tmp
		sta	zp_tmp
		lda	#0
		sbc	zp_tmp+1
		sta	zp_tmp+1
		rts

effects_vib_vol_slide:
		txa
		pha
		jsr	effects_do_vib
		pla
		tax
		jmp	effects_volume_slide

play_skip_read_row_done:
play_skip_read_row:
	; we're not loading a new row, apply any "current" effects

		ldx	#<cha_vars
		ldy	#>cha_vars
		stx	zp_cha_var_ptr
		sty	zp_cha_var_ptr+1
		ldx	#0
		stx	zp_cha_ctr
@cha_loop:
		ldx	zp_cha_ctr
		stx	jim_CS_SND_SEL
		jsr	check_effects

		jsr	set_p_vol


		jsr	next_cha_cha_var_ptr
		beq	@sk_cha_loop_done
		bne	@cha_loop
@sk_cha_loop_done:
		inc	g_arp_tick
		ldx	g_arp_tick
		cpx	#3
		bcc	@sk2
		ldx	#0
		stx	g_arp_tick
@sk2:

play_event_paused:
		lda	#FLAGS_EXEC
		ora	g_flags
		sta	g_flags

		rts

;--------------------------------------------------
; debugger display
;--------------------------------------------------
debug_display:
		ldy	#<$7E80
		sty	zp_scr_ptr
		ldy	#0
		lda	#>$7E80
		sta	zp_scr_ptr + 1

		ldx	#0
@gl:		lda	g_start,X
		jsr	FastPrHexA
		inx
		cpx	#g_size
		bne	@gl

		ldx	#0
		stx	zp_disp_tmp
		lda	#<cha_vars
		sta	getA+1
		lda	#>cha_vars
		sta	getA+2
		lda	#<$7EA8
		sta	zp_scr_ptr
		ldy	#0
		lda	#>$7EA8
		sta	zp_scr_ptr + 1
		
@cvclp:		ldx	#0
@cl2:		jsr	getA
		sta	zp_disp_peak
		jsr	FastPrHexA
		cpx	#.SIZEOF(s_cha_vars)
		bne	@cl2

		lda	#$94
		jsr	FastPrA

		lda	zp_disp_peak

		jsr	show_vu_A

		inc	zp_disp_tmp
		lda	zp_disp_tmp
		cmp	#4
		beq	@sk_dispdone

		clc
		tya
		adc	#80-2*.SIZEOF(s_cha_vars)-16
		tay
		lda	zp_scr_ptr +1
		adc	#0
		sta	zp_scr_ptr + 1

		lda	getA+1
		adc	#.SIZEOF(s_cha_vars)
		sta	getA+1
		bcc	@sc2
		inc	getA+2
@sc2:
		jmp	@cvclp
@sk_dispdone:
		rts

show_vu_A:
		lsr	a
		lsr	a
		lsr	a
		pha
		tax
		beq	@skvu1
		lda	#$7F
@vulp:		jsr	FastPrA
		dex
		bne	@vulp
@skvu1:

		pla
		eor	#$0F
		tax
		beq	@skvu2
		lda	#','
@vulp2:		jsr	FastPrA
		dex
		bne	@vulp2
@skvu2:
		rts


;--------------------------------------------------
; tracker display
;--------------------------------------------------

track_disp:


		lda	zp_mos_jimdevsave
		pha

		lda	my_jim_dev
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO
		lda	fred_JIM_PAGE_LO
		pha
		lda	fred_JIM_PAGE_HI
		pha

		lda	g_pattern_base_ptrl+2
		sta	fred_JIM_PAGE_HI


		ldy	#<SCREEN_BASE
		sty	zp_scr_ptr
		lda	#>SCREEN_BASE
		sta	zp_scr_ptr + 1

		ldx	#15
		stx	zp_disp_lin_ctr			; line counter
		lda	g_row_pos
		sec
		sbc	#8
		sta	zp_disp_row_num			; current row #

		adc	#7

		ldx	#0
		stx	zp_disp_tmp
		asl	a
		rol	zp_disp_tmp
		asl	a
		rol	zp_disp_tmp
		asl	a
		rol	zp_disp_tmp
		asl	a
		rol	zp_disp_tmp			; mul 16

		adc	g_pattern_base_ptrl
		sta	zp_disp_tmp_ptr

		lda	zp_disp_tmp
		adc	g_pattern_base_ptrl+1
		sta	fred_JIM_PAGE_LO

		sec
		lda	zp_disp_tmp_ptr
		sbc	#16*7
		sta	zp_disp_tmp_ptr

		lda	fred_JIM_PAGE_LO
		sbc	#0
		sta	fred_JIM_PAGE_LO

		lda	fred_JIM_PAGE_HI
		sbc	#0
		sta	fred_JIM_PAGE_HI


track_dlp:	lda	zp_disp_row_num
		bmi	track_blank_line
		cmp	#64
		bcs	track_blank_line		
		jmp	track_line
track_cnt:	inc	zp_disp_row_num
		dec	zp_disp_lin_ctr
		bne	track_dlp

		; reset device 
		lda	my_jim_dev
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO	
		pla
		sta	fred_JIM_PAGE_HI
		pla
		sta	fred_JIM_PAGE_LO
		pla
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO

		rts

track_blank_line:
		ldx	#40
		lda	#' '
@bllp:		jsr	FastPrA	
		dex
		bne	@bllp

		lda	zp_disp_tmp_ptr
		clc
		adc	#16
		sta	zp_disp_tmp_ptr
		bcc	@sk
		inc	fred_JIM_PAGE_LO
		bne	@sk
		inc	fred_JIM_PAGE_HI
@sk:		jmp	track_cnt

track_red_or_green:
		lda	zp_disp_lin_ctr
		cmp	#8
		beq	@skred
@grn:		lda	#$82
		bne	@skgrn
@skred:		lda	#$81
@skgrn:		jmp	FastPrA


	; displays a track line at u, taking notes from Y
	; a contains the row #
track_line:	
		jsr	track_red_or_green

		lda	zp_disp_row_num
		jsr	FastPrHexA
		ldx	#4				; channel counter
		stx	zp_disp_lp
		ldx	zp_disp_tmp_ptr

track_lp:	
		jsr	track_red_or_green

		jsr	track_getA
		and	#$0F
		sta	zp_disp_per+1
		jsr	track_getA
		sta	zp_disp_per

		jsr	PrNote

		lda	g_aeris
		beq	@spc
		lda	#$87
		sec
		sbc	zp_disp_lp
@notspc:	jsr	FastPrA
		jmp	@spc2

@spc:		jsr	track_red_or_green
@spc2:
		jsr	track_getA
		jsr	FastPrHexA
		jsr	track_getA
		jsr	FastPrHexA		
		dec	zp_disp_lp
		bne	track_lp
		lda	#' '
		jsr	FastPrA
		stx	zp_disp_tmp_ptr
		jmp	track_cnt


; get next byte from JIM X,JIM_LO,JIM_HI already set
track_getA:	lda	JIM,X
		inx
		bne	@sk1
		inc	fred_JIM_PAGE_LO
		bne	@sk1
		inc	fred_JIM_PAGE_HI
@sk1:		rts

getA:		lda	$FFFF,X
		inx
		rts

aevu2linenum_sta:

		sec
		eor	#$FF
		adc	#170

aevu_sta:
		; A = line number
		; X = palette info (top nyb=idx, bot=pal)

		pha
		txa
		pha
		tsx
		lda	$102,X		
		ldx	zp_tmp
		sta	aeris_sort,X
		inx
		pla
		sta	aeris_sort,X
		inx
		stx	zp_tmp
		tax
		pla
		rts

NUM_VU_ITEMS	:= 12
SZ_VU_ITEMS	:= 2

		;tweak the aeris list to show vu bars
		;make a list of things to do, sort into scan line order
aeris_vu:	

		jsr 	aeris_vu_update_program


		jsr	init_cha_ptr

		ldx	#0
		stx	zp_tmp		; offset into sort block
		ldx	#$30		; colour and palette entry
		stx     zp_tmp+1
		ldy	#s_cha_vars::cha_var_ppm
@chlp:		

		iny		
		lda	(zp_cha_var_ptr),Y
		dey
		pha
		lda	(zp_cha_var_ptr),Y
		sbc	#1
		bpl	@okppm
		lda	#0
@okppm:		sta	(zp_cha_var_ptr),Y
		pla
		cmp	(zp_cha_var_ptr),Y
		bcc	@noppm
		sta	(zp_cha_var_ptr),Y
@noppm:

		


		ldx	zp_tmp+1
		clc
		adc	#2				; make sure > peak!
		lda	(zp_cha_var_ptr),Y		;ppm
		jsr	aevu2linenum_sta
		inx
		iny
		lda	(zp_cha_var_ptr),Y		;vu
		jsr	aevu2linenum_sta
		dey
		clc
		dex
		adc	#9
		jsr	aevu_sta

		lda	zp_tmp+1
		clc
		adc	#$10
		sta	zp_tmp+1

		jsr	next_cha_cha_var_ptr
		bne	@chlp


;		;rainbow hilighter
;		ldx	#$02
;		lda	#30+9*8
;		sta	zp_tmp+1
;hiloop:		lda	zp_tmp+1
;		jsr	aevu_sta
;		inx
;		inc	zp_tmp+1
;		cpx	#$0A
;		bne	hiloop


		;sort the list by line number
		
aeris_sort_lp1:	ldy	#1
		ldx	#0
aeris_sort_lp2:
		lda	aeris_sort+2,X
		cmp	aeris_sort,X
		bcs	@noswap
		pha
		lda	aeris_sort,X
		sta	aeris_sort+2,X
		pla
		sta	aeris_sort,X
		lda	aeris_sort+3,X
		pha
		lda	aeris_sort+1,X
		sta	aeris_sort+3,X
		pla
		sta	aeris_sort+1,X
		iny
@noswap:	inx
		inx
		cpx	#NUM_VU_ITEMS*SZ_VU_ITEMS
		bne	aeris_sort_lp2
		dey
		bne	aeris_sort_lp1

		rts

aeris_vu_update_program:
		ldx	#aeris_pgm_bars4-aeris_test_pgm ; offset of waits and moves in program
		ldy	#0				; sorted list pointer

aepokelp:	lda	aeris_sort,Y
		iny

		; poke line number into wait 
		inx
		inx
		ror	A
		ror	A
		ror	A
		pha
		and	#$1F
		sta	aeris_test_pgm,X
		inx
		pla
		ror	A
		and	#$E0
		sta	aeris_test_pgm,X
		inx

		; poke colour into MOVE16
		inx
		inx
		tya
		pha					; save pointer

		lda	aeris_sort,Y
		and	#$F0				; colour #
		pha		
		lda	aeris_sort,Y
		and	#$0F
		asl	A
		tay

		pla
		ora	ae_pal,Y
		sta	aeris_test_pgm,X
		inx		
		iny
		lda	ae_pal,Y
		sta	aeris_test_pgm,X
		inx

		pla
		tay
		iny

		cpy	#NUM_VU_ITEMS*SZ_VU_ITEMS
		bne	aepokelp

		jsr	snd_devsel
		jmp	aeris_pgm2_chipram
		rts


PrNote:		txa
		pha
		lda	zp_disp_per+1
		bne	@s1
		lda	zp_disp_per
		cmp	#113
		bcc	PrNoNote
		bcs	@s2

@s1:		cmp	#$04
		bcs	PrNoNote			; >= $400
@s2:		ldx	#3
		stx	zp_disp_oct			; octave
prnotelp:	ldx	#0				; semitones counter *2

		; compare zp_disp_per to table 1st entry - if too high go to next octave

		jsr	PrNoteCmp
		beq	PrNoteLp2
		bcs	PrNoteOct
PrNoteLp2:	jsr	PrNoteCmp
		bcs	PrNoteF
		cpx	#26
		bne	PrNoteLp2

		lda	#'!'
		bne	PrNoNoteBad

PrNoNote:
		lda	#'-'
PrNoNoteBad:	jsr	FastPrA
		jsr	FastPrA
		jsr	FastPrA				; exit
PrNoteOut:	pla
		tax
		rts

PrNoteCmp:	lda	zp_disp_per+1
		cmp	pertab+1,X
		bne	@s1
		lda	zp_disp_per
		cmp	pertab,X
@s1:		php
		inx
		inx
		plp
		rts


PrNoteOct:	clc
		ror	zp_disp_per+1
		ror	zp_disp_per
		dec	zp_disp_oct
		bne	prnotelp
		; if it falls through here there's sommmat up!


PrNoteF:	lda	nottab-4,X
		jsr	FastPrA
		lda	nottab-3,X
		jsr	FastPrA
		lda	zp_disp_oct
		jsr	FastPrNyb
		jmp	PrNoteOut

set_p_period:
		ldy	#s_cha_vars::cha_var_per + 0	; note big endian - check HI byte is 0
		lda	(zp_cha_var_ptr),Y
		beq	@ck
@ok:		sta	jim_CS_SND_PERIOD + 1
		iny
		lda	(zp_cha_var_ptr),Y
		sta	jim_CS_SND_PERIOD + 0
		rts
@ck:		iny
		lda	(zp_cha_var_ptr),Y
		cmp	#113
		bcc	@notok
		dey
		lda	#0
		beq	@ok
@notok:		rts

set_p_period_zp_tmp:
		lda	zp_tmp+1			; note zp_tmp is little endian but period reg is be
		beq	@ck
@ok:		sta	jim_CS_SND_PERIOD + 1
		lda	zp_tmp
		sta	jim_CS_SND_PERIOD + 0
		rts
@ck:		lda	zp_tmp
		cmp	#113
		bcc	@notok
		lda	#0
		beq	@ok
@notok:		rts


do_arpeg:
		lda	g_arp_tick
		beq	@arp0
		cmp	#1
		beq	@arp1
		txa
		and	#$0F
		beq	@arp0
		asl	a
		
@arpatA:	tax
		lda	semitones,X
		sta	zp_num2
		inx
		lda	semitones,X
		sta	zp_num2 + 1
		ldy	#s_cha_vars::cha_var_per
		lda	(zp_cha_var_ptr),Y
		sta	zp_num1 + 1
		iny
		lda	(zp_cha_var_ptr),Y
		sta	zp_num1 
		jsr	mul16

@aaaaaa:		lda	zp_tmp + 3
		sta	jim_CS_SND_PERIOD + 1
		lda	zp_tmp + 2
		sta	jim_CS_SND_PERIOD + 0
		rts

@arp1:		txa
		and	#$F0
		beq	@arp0
		lsr	a
		lsr	a
		lsr	a
		jmp	@arpatA

@arp0:		jmp	set_p_period		; (re)set to stored period



set_p_vol:
		ldy	#s_cha_vars::cha_var_flags
		lda	(zp_cha_var_ptr),Y
		bmi	@mute
		ldy	#s_cha_vars::cha_var_vol
		lda	(zp_cha_var_ptr),Y
		asl	a
		asl	a
@s:		sta	jim_CS_SND_VOL
		rts
@mute:		lda	#0
		beq	@s

do_tone_porta:
		ldy	#s_cha_vars::cha_var_porta_per
		lda	(zp_cha_var_ptr),Y
		sta	tmp_note_porta
		iny
		lda	(zp_cha_var_ptr),Y
		; check that we have a target period
		sta	tmp_note_porta + 1
		ora	tmp_note_porta
		bne	@doit
		rts
@doit:
		;get note porta / per to tmp vars
		ldy	#s_cha_vars::cha_var_per + 1
		lda	(zp_cha_var_ptr),Y
		sta	tmp_note_per+1
		dey
		lda	(zp_cha_var_ptr),Y
		sta	tmp_note_per
		; check direction
		jsr	check_porta_dir
		beq	@done
		bcc	@down			; CC if porta > per
@s1:
		; subtract speed
		lda	tmp_note_per + 1
		ldy	#s_cha_vars::cha_var_porta_speed
		sec
		sbc	(zp_cha_var_ptr),Y
		sta	tmp_note_per + 1
		lda	tmp_note_per
		sbc	#0
		sta	tmp_note_per
		bcc	@spp_done			; it's overflowed -ve we're done!
		; check for overflow
		jsr	check_porta_dir
		beq	@spp_done
		bcs	@exitnotover		; not overflowed
		; store porta period and we're done
@spp_done:	jsr	store_porta_per
@done:		lda	#0
		ldy	#s_cha_vars::cha_var_porta_per	; clear target to indicate done
		sta	(zp_cha_var_ptr),Y
		iny
		sta	(zp_cha_var_ptr),Y
		jmp	@spr
		; store updated period in vars and exit
@exitnotover:	jsr	store_tmp_per
@spr:		jsr	set_p_period
@r:		rts

@down:
		; add speed
		lda	tmp_note_per + 1
		ldy	#s_cha_vars::cha_var_porta_speed
		clc
		adc	(zp_cha_var_ptr),Y
		sta	tmp_note_per + 1
		lda	tmp_note_per
		adc	#0
		sta	tmp_note_per
		; check for overflow
		jsr	check_porta_dir
		bcc	@exitnotover		; not overflowed
		jmp	@spp_done

	; will return Z if tmp_note_porta == tmp_note_per
	; else CS if porta < per
	; else CC if porta > per
check_porta_dir:
		; check direction
		; subtract wanted from curent ; note BE
		sec
		lda	tmp_note_per + 1
		sbc	tmp_note_porta + 1
		sta	zp_tmp				; store for zero check
		lda	tmp_note_per
		sbc	tmp_note_porta
		bne	@s1
		eor	zp_tmp
@s1:		rts



store_tmp_per:	ldy	#s_cha_vars::cha_var_per + 1
		lda	tmp_note_per + 1
		sta	(zp_cha_var_ptr),Y
		dey
		lda	tmp_note_per
		sta	(zp_cha_var_ptr),Y
		rts

store_porta_per:ldy	#s_cha_vars::cha_var_per + 1
		lda	tmp_note_porta + 1
		sta	(zp_cha_var_ptr),Y
		dey
		lda	tmp_note_porta
		sta	(zp_cha_var_ptr),Y
		rts

wait_vsync:
		lda	#19
		jmp	OSBYTE


; A = position
; return:
;	A = pattern #
lookup_song:
		and	#$7F
		cmp	g_song_len
		tax
		bcs	@end
		lda	song_data,X
		rts
@end:		lda	#$80				; return -ve for >= song length
		rts
; A = pattern #
; return:
; 	zp_note_ptr -> 1st row of pattern
;	A = 0
;	Z
start_pattern:	

		ldx	#<HDR_PATT_DATA_OFFS
		stx	zp_pattern_ptrl
		stx	g_pattern_base_ptrl
		asl	a
		asl	a
		php				; save carry
		clc
		adc	#(>HDR_PATT_DATA_OFFS)+(<MODULE_CPAGE)
		sta	zp_pattern_ptrl+1
		sta	g_pattern_base_ptrl+1
		lda	#>MODULE_CPAGE
		adc	#0
		plp
		adc	#0
		sta	zp_pattern_ptrl+2
		sta	g_pattern_base_ptrl+2
		rts


get_pattern_row:
		ldx	#4
		stx	zp_tmp
		ldx	#0
		ldy	zp_pattern_ptrl
		lda	zp_pattern_ptrl+1
		sta	fred_JIM_PAGE_LO
		lda	zp_pattern_ptrl+2
		sta	fred_JIM_PAGE_HI
@lp:		jsr	@g1
		jsr	@g1
		jsr	@g1
		jsr	@g1
		bne	@sk1
		inc	fred_JIM_PAGE_LO
		inc	zp_pattern_ptrl+1
		bne	@sk1
		inc	fred_JIM_PAGE_HI
		inc	zp_pattern_ptrl+2
@sk1:		dec	zp_tmp
		bne	@lp

		sty	zp_pattern_ptrl

		lda	#<patt_row_copy
		sta	zp_note_ptr
		lda	#>patt_row_copy
		sta	zp_note_ptr+1

		jmp	snd_devsel


@g1:		lda	JIM,Y
		sta	patt_row_copy,X
		inx
		iny
		rts
		


PRTXT:		stx	zp_si_ptr
		sty	zp_si_ptr + 1
		ldy	#0
@l:		lda	(zp_si_ptr),Y
		beq	@r
		jsr	OSASCI
		iny
		bne	@l
@r:		rts

PRIM:		pla
		sta	zp_si_ptr
		pla
		sta	zp_si_ptr + 1
		ldy	#1
@l:		lda	(zp_si_ptr),Y
		beq	@r
		jsr	OSASCI
		iny
		bne	@l
		brk
		.byte 2, "String over", 0
@r:		iny
		tya
		adc	zp_si_ptr
		sta	zp_si_ptr
		lda	#0
		adc	zp_si_ptr + 1
		sta	zp_si_ptr + 1
		jmp	(zp_si_ptr)              ; Jump back to code after string

FastPrHexA:	PHA
		LSR A
		LSR A
		LSR A
		LSR A
		JSR FastPrNyb
		PLA
FastPrNyb:	AND #15
		CMP #10
		BCC FastPrDigit
		ADC #6
FastPrDigit:	ADC #'0'
FastPrA:	sta	(zp_scr_ptr),Y
		iny
		bne	@s
		inc	zp_scr_ptr + 1
@s:		rts

FastPrSp:	lda	#' '
		jmp	FastPrA

dokey_fn:	inx
		lda	keyfntab,X
		sta	tmp_note_per
		inx
		lda	keyfntab,X
		sta	tmp_note_per + 1
		jmp	(tmp_note_per)

key_mute_cha_0:
		ldx	#0
		jmp	mute_cha_A
key_mute_cha_1:
		ldx	#1
		jmp	mute_cha_A
key_mute_cha_2:
		ldx	#2
		jmp	mute_cha_A
key_mute_cha_3:
		ldx	#3
mute_cha_A:	lda	#s_cha_vars::cha_var_flags
		clc
@l:		dex
		bmi	@s
		adc	#.SIZEOF(s_cha_vars)
		bne	@l
@s:		tax
		lda	cha_vars,X
		eor	#$80
		sta	cha_vars,X
		rts
key_pause:		
		lda	#FLAGS_key_pause
		eor	g_flags
		sta	g_flags
		rts


key_pattern_rep:
		lda	#$FF
		eor	g_pat_rep
		sta	g_pat_rep
		rts

key_song_next:
		lda	#$80
		sta	g_song_skip
		rts

key_song_prev:
		lda	#$40
		sta	g_song_skip
		rts

key_faster:
		dec	g_speed
		bne	@s1
		inc	g_speed
@s1:		rts


key_slower:
		inc	g_speed
		bne	@s1
		dec	g_speed
@s1:		rts

key_debug:	lda	display_state
		eor	#DISP_DEBUG
		and	#DISP_DEBUG
		sta	display_state
		jmp	cls


key_aeris:	lda	my_jim_dev
		cmp	#JIM_DEVNO_BLITTER
		bne	@s1

		lda	g_aeris
		bne	@aeoff
		jsr	aeris_init
		inc	g_aeris
@s1:		rts
@aeoff:		lda	#0
		sta	g_aeris
		jmp	aeris_off


key_help:	lda	display_state
		eor	#DISP_HELP
		and	#DISP_HELP
		sta	display_state
		beq	cls

		;display help
		ldx	#8
		ldy	#0
		lda	#<SCREEN_BASE
		sta	zp_scr_ptr
		lda	#>SCREEN_BASE
		sta	zp_scr_ptr+1
		lda	#<str_help
		sta	zp_disp_tmp_ptr
		lda	#>str_help
		sta	zp_disp_tmp_ptr+1
@l:		lda	(zp_disp_tmp_ptr),Y
		sta	(zp_scr_ptr),Y
		iny
		bne	@l
		inc 	zp_disp_tmp_ptr+1
		inc	zp_scr_ptr+1
		dex
		bne	@l
		rts
cls:		
		lda	#12
		jsr	OSWRCH
		lda	display_state 
		bne	@s1
		; display logo

		ldy	#0
		lda	#<SCREEN_LOGO
		sta	zp_scr_ptr
		lda	#>SCREEN_LOGO
		sta	zp_scr_ptr+1
		lda	#<str_logo
		sta	zp_disp_tmp_ptr
		lda	#>str_logo
		sta	zp_disp_tmp_ptr+1
@l:		lda	(zp_disp_tmp_ptr),Y
		sta	(zp_scr_ptr),Y
		iny
		bne	@l
		inc 	zp_disp_tmp_ptr+1
		inc	zp_scr_ptr+1
		ldx	#$40
@l2:		lda	(zp_disp_tmp_ptr),Y
		sta	(zp_scr_ptr),Y
		iny
		dex
		bne	@l2

		ldx	#2
		stx	zp_disp_tmp
		lda	#<(SCREEN_LOGO-80)
		sta	zp_scr_ptr
		lda	#>(SCREEN_LOGO-80)
		sta	zp_scr_ptr+1
		ldy	#0
		
@l3:		lda	#141-128
		jsr	FastPrA
		lda	#134-128
		jsr	FastPrA
		ldx	#0
@l4:		lda	song_name,X
		jsr	FastPrA
		inx
		cpx	#20
		bne	@l4
		tya
		clc
		adc	#40-22
		tay
		dec	zp_disp_tmp
		bne	@l3




@s1:		rts





		; mul16 taken from http://www.llx.com/~nparker/a2/mult.html#mul1
		; zp_tmp <= zp_num1 * zp_num2
mul16:
		LDA	#0       ;Initialize RESULT to 0
		STA	zp_tmp+2
		LDX	#16      ;There are 16 bits in NUM2
@L1:		LSR	zp_num2+1   ;Get low bit of NUM2
		ROR	zp_num2
		BCC	@L2       ;0 or 1?
		TAY	         ;If 1, add NUM1 (hi byte of RESULT is in A)
		CLC
		LDA	zp_num1
		ADC	zp_tmp+2
		STA	zp_tmp+2
		TYA
		ADC	zp_num1+1
@L2:		ROR	A        ;"Stairstep" shift
		ROR	zp_tmp+2
		ROR	zp_tmp+1
		ROR	zp_tmp
		DEX
		BNE	@L1
		STA	zp_tmp+3
		rts

mul8:
		LDA	#0       ;Initialize RESULT to 0
		LDX	#8       ;There are 8 bits in NUM2
@L1:		LSR	zp_num2     ;Get low bit of NUM2
		BCC	@L2       ;0 or 1?
		CLC          ;If 1, add NUM1
		ADC	zp_num1
@L2:		ROR	A        ;"Stairstep" shift (catching carry from add)
		ROR	zp_tmp
		DEX
		BNE	@L1
		STA	zp_tmp+1
		rts

		; taken from http://codebase64.org/doku.php?id=base:24bit_division_24-bit_result
div24x8:
		lda #0				        ;preset zp_d24_remain to 0
		sta zp_d24_remain
		sta zp_d24_remain+1
		sta zp_d24_remain+2
		ldx #24	        			;repeat for each bit: ...
@divloop:	asl zp_d24_dividend			;zp_d24_dividend lb & hb*2, msb -> Carry
		rol zp_d24_dividend+1	
		rol zp_d24_dividend+2
		rol zp_d24_remain			;zp_d24_remain lb & hb * 2 + msb from carry
		rol zp_d24_remain+1
		rol zp_d24_remain+2
		lda zp_d24_remain
		sec
		sbc zp_d24_divisor8			;substract zp_d24_divisor8 to see if it fits in
		tay	        			;lb result -> Y, for we may need it later
		lda zp_d24_remain+1
		sbc #0
		sta zp_d24_tmp
		lda zp_d24_remain+2
		sbc #0
		bcc @skip				;if carry=0 then zp_d24_divisor8 didn't fit in yet
		sta zp_d24_remain+2			;else save substraction result as new zp_d24_remain,
		lda zp_d24_tmp
		sta zp_d24_remain+1
		sty zp_d24_remain	
		inc zp_d24_dividend 			;and INCrement result cause zp_d24_divisor8 fit in 1 times
@skip:		dex
		bne @divloop	
		rts

aeris_off:
		jsr	snd_devsel
		lda	#0
		sta	jim_DMAC_AERIS_CTL
		;reset nula
		lda	#$40
		sta	$FE22
		rts


aeris_pgm2_chipram:
		lda	#0
		sta	jim_CS_DMA_SEL
		lda	#$FF
		sta	jim_CS_DMA_SRC_ADDR+2
		lda	#.HIBYTE(aeris_test_pgm)
		sta	jim_CS_DMA_SRC_ADDR+1
		lda	#.LOBYTE(aeris_test_pgm)
		sta	jim_CS_DMA_SRC_ADDR+0
		lda	#.BANKBYTE(AERIS_LIST_ADDR)
		sta	jim_CS_DMA_DEST_ADDR+2
		lda	#.HIBYTE(AERIS_LIST_ADDR)
		sta	jim_CS_DMA_DEST_ADDR+1
		lda	#.LOBYTE(AERIS_LIST_ADDR)
		sta	jim_CS_DMA_DEST_ADDR+0
		lda	#.HIBYTE(aeris_test_pgm_end-aeris_test_pgm-1)
		sta	jim_CS_DMA_COUNT+1
		lda	#.LOBYTE(aeris_test_pgm_end-aeris_test_pgm-1)
		sta	jim_CS_DMA_COUNT+0
	
		lda	#DMACTL_ACT + DMACTL_HALT + DMACTL_STEP_DEST_UP + DMACTL_STEP_SRC_UP
		sta	jim_CS_DMA_CTL
		rts

aeris_init:
		jsr	snd_devsel
		jsr	aeris_pgm2_chipram
	
	
		lda	#.BANKBYTE(AERIS_LIST_ADDR)
		sta	jim_DMAC_AERIS_PROGBASE
		lda	#.HIBYTE(AERIS_LIST_ADDR)
		sta	jim_DMAC_AERIS_PROGBASE+1
		lda	#.LOBYTE(AERIS_LIST_ADDR)
		sta	jim_DMAC_AERIS_PROGBASE+2
	
		lda	#AERIS_CTL_ACT
		sta	jim_DMAC_AERIS_CTL
		rts


		.DATA

		; fixed point semitones (16 bits), missing 0th as always equal
		; used by arpeggio
semitones:	.word	0
		.word	$F1A1		; 0.943874
		.word	$E411		; 0.890899
		.word	$D744		; 0.840896
		.word	$CB2F		; 0.793701
		.word	$BFC8		; 0.749154
		.word	$B504		; 0.707107
		.word	$AADC		; 0.66742
		.word	$A145		; 0.629961
		.word	$9837		; 0.594604
		.word	$8FAC		; 0.561231
		.word	$879C		; 0.529732
		.word	$8000		; 0.5
		.word	$78D0		; 0.471937
		.word	$7208		; 0.445449
		.word	$6BA2		; 0.420448
		.word	$6597		; 0.39685

keyfntab:	.byte	'1'
		.word	key_mute_cha_0
		.byte	'2'
		.word	key_mute_cha_1
		.byte	'3'
		.word	key_mute_cha_2
		.byte	'4'
		.word	key_mute_cha_3
		.byte	' '
		.word	key_pause
		.byte	'P'
		.word	key_pattern_rep
		.byte	']'
		.word	key_song_next
		.byte	'['
		.word	key_song_prev
		.byte	'F'
		.word	key_faster
		.byte	'S'
		.word	key_slower
		.byte	'H'
		.word   key_help
		.byte	'D'
		.word	key_debug
		.byte   'A'
		.word   key_aeris
keyfntablen	= *-keyfntab

pertab:		.word	220,208,196,185,175,165,156,147,139,131,124,117,111
nottab:		.byte	"C-C_D-D_E-F-F_G-G_A-A_B-"

vibtab:		.byte	$00, $18, $31, $4A, $61, $78, $8D, $A1
		.byte	$B4, $C5, $D4, $E0, $EB, $F4, $FA, $FD
		.byte	$FF, $FD, $FA, $F4, $EB, $E0, $D4, $C5
		.byte	$B4, $A1, $8D, $78, $61, $4A, $31, $18

; 8bit
;;finetunetab:	.word 256, 254, 252, 251, 249, 247, 245, 243, 271, 269, 267, 265, 264, 262, 260, 258
finetunetab:	.word	32768, 32532, 32298, 32066, 31835, 31606, 31379, 31153, 34716, 34467, 34219, 33973, 33728, 33486, 33245, 33005
; revers
;;finetunetab:	.word	32768, 33005, 33245, 33486, 33728, 33973, 34219, 34467, 30929, 31153, 31379, 31606, 31835, 32066, 32298, 32532


log_maj:	.byte	96, 84, 72, 60, 48, 36, 24
log_min:	.byte	0, 2, 3, 5, 7, 8, 9, 10

DISP_NORMAL	:= 0
DISP_HELP	:= 2
DISP_DEBUG	:= 1

display_state:	.byte	DISP_NORMAL	; 0 = normal, 1 = debug, 2 = help

str_help:
		.incbin "helptext.mo7.txt"
str_logo	:= str_help + (25-8) * 40
str_logo_end	:= str_help + 2048


aeris_test_pgm:
		AE_MOVE16	$2, $23, $0000
		AE_MOVE16	$2, $23, $30D0		;  pal 3 = NAVY
		AE_MOVE16	$2, $23, $40D0  	;  pal 4 = NAVY
		AE_MOVE16	$2, $23, $50D0  	;  pal 5 = NAVY
		AE_MOVE16	$2, $23, $60D0		;  pal 6 = NAVY

		; screen starts on line 43
		; track display ends on line 190

aeris_pgm_bars4:
		AE_WAIT		$1FF, $00, 70, 0	
		AE_MOVE16	$2, $23, $3EE0
		AE_WAIT		$1FF, $00, 90, 0	
		AE_MOVE16	$2, $23, $4EE0
		AE_WAIT		$1FF, $00, 100, 0	
		AE_MOVE16	$2, $23, $5EE0
		AE_WAIT		$1FF, $00, 100, 0	
		AE_MOVE16	$2, $23, $6EE0

		AE_WAIT		$1FF, $00, 110, 0	
		AE_MOVE16	$2, $23, $3EE0
		AE_WAIT		$1FF, $00, 110, 0	
		AE_MOVE16	$2, $23, $4EE0
		AE_WAIT		$1FF, $00, 110, 0	
		AE_MOVE16	$2, $23, $5EE0
		AE_WAIT		$1FF, $00, 110, 0	
		AE_MOVE16	$2, $23, $6EE0

		AE_WAIT		$1FF, $00, 111, 0	
		AE_MOVE16	$2, $23, $3F0F
		AE_WAIT		$1FF, $00, 111, 0	
		AE_MOVE16	$2, $23, $4F0F
		AE_WAIT		$1FF, $00, 111, 0	
		AE_MOVE16	$2, $23, $5FF0
		AE_WAIT		$1FF, $00, 111, 0	
		AE_MOVE16	$2, $23, $6FF0


		AE_WAIT		$1FF, $00, 190, 0	
		AE_MOVE16	$2, $23, $3610		;  pal 3 = BRN
		AE_MOVE16	$2, $23, $4A01  	;  pal 4 = NAVY
		AE_MOVE16	$2, $23, $5703  	;  pal 5 = PURPL
		AE_MOVE16	$2, $23, $6A50		;  pal 6 = ORANGE


		; rainbow modplay
aeris_lp:	AE_WAITH
		AE_MOVE16	$2, $23, $1E00
		AE_WAITH
		AE_MOVE16	$2, $23, $1C20
		AE_WAITH
		AE_MOVE16	$2, $23, $1A40
		AE_WAITH
		AE_MOVE16	$2, $23, $1860
		AE_WAITH
		AE_MOVE16	$2, $23, $1680
		AE_WAITH
		AE_MOVE16	$2, $23, $14A0
		AE_WAITH
		AE_MOVE16	$2, $23, $12C0
		AE_WAITH
		AE_MOVE16	$2, $23, $10E0
		AE_WAITH
		AE_MOVE16	$2, $23, $10C2
		AE_WAITH
		AE_MOVE16	$2, $23, $10A4
		AE_WAITH
		AE_MOVE16	$2, $23, $1086
		AE_WAITH
		AE_MOVE16	$2, $23, $1068
		AE_WAITH
		AE_MOVE16	$2, $23, $104A
		AE_WAITH
		AE_MOVE16	$2, $23, $102C
		AE_WAITH
		AE_MOVE16	$2, $23, $100E
		AE_WAITH
		AE_MOVE16	$2, $23, $120C
		AE_WAITH
		AE_MOVE16	$2, $23, $140A
		AE_WAITH
		AE_MOVE16	$2, $23, $1608
		AE_WAITH
		AE_MOVE16	$2, $23, $1806
		AE_WAITH
		AE_MOVE16	$2, $23, $1A04
		AE_WAITH
		AE_MOVE16	$2, $23, $1C02
		AE_BRA		aeris_lp


		AE_WAIT		$1FF, 00, $1FF, 0

ae_pal:		.byte		$0E, $E0		; have to store bigendian
		.byte		$0E, $42		; have to store bigendian
		.byte		$0F, $00		; Richard
		.byte		$0D, $80		; Of
		.byte		$0B, $B0		; York
		.byte		$00, $60		; Gave
		.byte		$00, $87		; Battle
		.byte		$00, $0F		; In
		.byte		$07, $0A		; Vain
		.byte		$00, $00		; 0

aeris_test_pgm_end:


		.BSS
song_name:	.RES	20
old_jim_dev:	.RES	1
my_jim_dev:	.RES	1
tmp_note_per:	.RES	2
tmp_note_porta:	.RES	2
tmp_note_cmd:	.RES	1
filename:	.RES	2
old_EVNTV:	.RES	2
	.if !BUILD_TIMER_VSYNC
old_IRQ2V:	.RES	2
	.endif	

g_start:
g_speed:	.RES	1
g_song_pos:	.RES	1
g_pattern:	.RES	1
g_tick_ctr:	.RES	1
g_row_pos:	.RES	1
g_arp_tick:	.RES	1
g_flags:	.RES	1
g_patt_brk:	.RES	1
g_pat_rep:	.RES	1
g_song_skip:	.RES	1
g_song_len:	.RES	1
g_aeris:	.RES	1
g_end:
g_size		:= g_end-g_start


;TODO: move this to cha_vars
g_pattern_base_ptrl:	.RES	3		; pointer to chip ram base of current pattern
patt_row_copy:	.RES	16

cha_vars:
cha_0_vars:	.TAG	s_cha_vars
cha_1_vars:	.TAG	s_cha_vars
cha_2_vars:	.TAG	s_cha_vars
cha_3_vars:	.TAG	s_cha_vars

mod_data:	.TAG	s_mod_data
sam_data:	.RES	32*.SIZEOF(s_saminfo)
song_data:	.RES	SONG_DATA_LEN

aeris_sort:	.RES	NUM_VU_ITEMS*SZ_VU_ITEMS

		.END
