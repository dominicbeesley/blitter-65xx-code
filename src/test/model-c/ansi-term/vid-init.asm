		
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

		; load font at FFFF3000 - assume this is mapped to gfx
		lda	#$FF
		ldx	#<FONT_FILE
		ldy	#>FONT_FILE
		jsr	OSFILE
		
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


_ULA_SETTINGS:		.byte	$9c				; 10011100
			.byte	$d8				; 11011000
			.byte	$f4				; 11110100
			.byte	$9c				; 10011100
			.byte	$88				; 10001000
			.byte	$c4				; 11000100
			.byte	$88				; 10001000
			.byte	$4b				; 01001011

;************* 6845 REGISTERS 0-11 FOR INTERLACED 16 LINE CHARS ************************

_CRTC_REG_TAB:		.byte	$7f				; 0 Horizontal Total	 =128
			.byte	$50				; 1 Horizontal Displayed =80
			.byte	$62				; 2 Horizontal Sync	 =&62
			.byte	$28				; 3 HSync Width+VSync	 =&28  VSync=2, HSync Width=8
			.byte	$26				; 4 Vertical Total	 =38
			.byte	$00				; 5 Vertial Adjust	 =0
			.byte	$19				; 6 Vertical Displayed	 =25
			.byte	$20				; 7 VSync Position	 =&20
			.byte	$03				; 8 Interlace+Cursor	 =&03  Cursor=0, Display=0, Interlace=On+Video
			.byte	$0F				; 9 Scan Lines/Character =16
			.byte	$6D				; 10 Cursor Start Line	  =&67	Blink=On, Speed=1/32, Line=13
			.byte	$0F				; 11 Cursor End Line	  =8


		.macro	PAL IX,R,G,B			
			.word (IX<<4)+R+(G<<12)+(B<<8)
		.endmacro

palette:		PAL	0,  0,  0,  0		; black
			PAL	1,  0,  0, 11		; blue
			PAL	2,  0, 11,  0		; green
			PAL	3,  0, 11, 11		; cyan
			PAL	4, 11,  0,  0		; red
			PAL	5, 11,  0, 11		; magenta
			PAL	6, 11,  5,  0		; yellow
			PAL	7, 11, 11, 11		; grey

			PAL	8,  5,  5,  5		; dark grey
			PAL	9,  5,  5, 15		; light blue
			PAL	10, 5, 15,  5		; light green
			PAL	11, 5, 15, 15		; light cyan
			PAL	12,15,  5,  5		; light red
			PAL	13,15,  5, 15		; light magenta
			PAL	14,15, 15,  5		; light yellow
			PAL	15,15, 15, 15		; white
