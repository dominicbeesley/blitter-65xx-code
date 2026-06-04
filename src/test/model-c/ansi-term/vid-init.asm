		
		.include	"oslib.inc"
		.include	"hardware.inc"
		.include	"mosrom.inc"
		.include	"aeris.inc"
		.include "hdmi_hw.inc"

		.global	vid_init

; This assumes a model B/C i.e. hdmi crtc, ula, nula in sheila, extra control regs in 
; chipset memory space at FBFExx


		.segment "INIT"

BASE_VIDPROC_VALUE	:= $9C ; (mode 0/3)

vid_init:
	
		sei
	
	; setup for JIM access and leave like that - we don't exit back to OS
		lda	#$D1
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO
		lda	#>HDMI_PAGE_REGS
		sta	fred_JIM_PAGE_HI
		lda	#<HDMI_PAGE_REGS
		sta	fred_JIM_PAGE_LO



	; set up HDMI for mode 2

		lda	#BASE_VIDPROC_VALUE
		sta	sheila_ULA_ctl
		sta	sysvar_VIDPROC_CTL_COPY

		ldy	#$0b				; Y=11
		ldx	#$0b
_BCBB0:		lda	_CRTC_REG_TAB,X			; get end of 6845 registers 0-11 table
		sty	sheila_CRTC_ix
		sta	sheila_CRTC_dat
		dex					; reduce pointers
		dey					; 
		bpl	_BCBB0				; and if still >0 do it again

		; palette colour
		lda	#$0F
		clc
ppl:		sta	sheila_ULA_pal			; default logical to physical colours to straight mapping
		adc	#$0F
		bcc	ppl

		; ega palette in nula
		ldx	#0
		ldy	#32
@pp2:		lda	palette,X
		sta	sheila_NULA_palaux
		inx
		dey
		bne	@pp2

		
		lda 	#12
		sta	sheila_CRTC_ix
		lda	#0
		sta	sheila_CRTC_dat
		lda 	#13
		sta	sheila_CRTC_ix
		lda	#0
		sta	sheila_CRTC_dat

		; poke sequencer register to select ANSI text mode
		lda	#0
		sta	HDMI_ADDR_SEQ_IX
		lda	#1
		sta	HDMI_ADDR_SEQ_DAT		; select ansi/alpha

		cli

		rts


FONT_FILE_NAME:		.byte	"F.VGA8",$D,0
FONT_FILE:		.word	FONT_FILE_NAME
			.dword	$FFFF3000
			.dword	0
			.dword	0
			.dword	0



