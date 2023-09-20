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


		.include	"oslib.inc"
		.include	"hardware.inc"
		.include	"mosrom.inc"
		.include	"aeris.inc"


		; quick test program - change HDMI to mode 2, non-interlaced and copy current screen contents to base
		; of hdmi memory

HDMI_PAGE_MEM		:=	$FA00
HDMI_PAGE_REGS		:=	$FBFE
HDMI_ADDR_VIDPROC_CTL	:=	$FD20
HDMI_ADDR_VIDPROC_PAL	:=	$FD21
HDMI_ADDR_CRTC_IX	:=	$FD00
HDMI_ADDR_CRTC_DAT	:=	$FD01
HDMI_ADDR_SEQ_IX	:=	$FD02
HDMI_ADDR_SEQ_DAT	:=	$FD03


zp_ptr			:=	$70
zp_tmp			:=	$72


BASE_VIDPROC_VALUE	:= $9C ; (mode 0/3)

		.CODE

START:

		lda	#$D1
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO
	
		sei

	; set up HDMI for mode 2

		lda	#>HDMI_PAGE_REGS
		sta	fred_JIM_PAGE_HI
		lda	#<HDMI_PAGE_REGS
		sta	fred_JIM_PAGE_LO

		lda	#BASE_VIDPROC_VALUE
		sta	HDMI_ADDR_VIDPROC_CTL

		ldy	#$0b				; Y=11
		ldx	#$0b
_BCBB0:		lda	_CRTC_REG_TAB,X			; get end of 6845 registers 0-11 table
		sty	HDMI_ADDR_CRTC_IX
		sta	HDMI_ADDR_CRTC_DAT
		dex					; reduce pointers
		dey					; 
		bpl	_BCBB0				; and if still >0 do it again


		; point at font data for now
		lda 	#12
		sta	HDMI_ADDR_CRTC_IX
		lda	#6
		sta	HDMI_ADDR_CRTC_DAT
		lda 	#13
		sta	HDMI_ADDR_CRTC_IX
		lda	#0
		sta	HDMI_ADDR_CRTC_DAT


		; palette black and white
		lda	#$0F
		clc
pplp:		sta	HDMI_ADDR_VIDPROC_PAL
		adc	#$10
		bpl	pplp

		lda	#$88
pplp2:		sta	HDMI_ADDR_VIDPROC_PAL
		adc	#$10
		bcc	pplp2

		; get pointer to font
		lda	#<font_data
		sta	zp_ptr
		lda	#>font_data
		sta	zp_ptr+1

		lda	#>(HDMI_PAGE_MEM+$30)
		sta	fred_JIM_PAGE_HI
		lda	#<(HDMI_PAGE_MEM+$30)
		sta	fred_JIM_PAGE_LO

		ldy	#0
		ldx	#1+>(font_end-font_data)
lp:		lda	(zp_ptr),y
		sta	JIM,y
		iny
		bne	lp
		inc	zp_ptr+1
		inc	fred_JIM_PAGE_LO
		dex
		bne	lp

		; access text memory via JIM and fill with a repeating pattern of chars

ALPHA_BASE	:= $78	; page number in screen mem

		ldx	#8				; number of pages to fill
		ldy	#0

		lda	#>(HDMI_PAGE_MEM+ALPHA_BASE)
		sta	fred_JIM_PAGE_HI
		lda	#<(HDMI_PAGE_MEM+ALPHA_BASE)
		sta	fred_JIM_PAGE_LO

@flp:		tya
		sta	JIM,Y
		iny
		bne	@flp
		inc	fred_JIM_PAGE_LO
		dex
		bne	@flp


; wait for some time
		lda	#25
		sta	zp_tmp
		ldx	#0
		ldy	#0
@wt:		dex
		bne	@wt
		dey
		bne	@wt
		dec 	zp_tmp
		bne	@wt

		lda	#>HDMI_PAGE_REGS
		sta	fred_JIM_PAGE_HI
		lda	#<HDMI_PAGE_REGS
		sta	fred_JIM_PAGE_LO

		; point at font data for now
		lda 	#12
		sta	HDMI_ADDR_CRTC_IX
		lda	#15
		sta	HDMI_ADDR_CRTC_DAT
		lda 	#13
		sta	HDMI_ADDR_CRTC_IX
		lda	#0
		sta	HDMI_ADDR_CRTC_DAT

		; poke sequencer register to select ANSI text mode
		lda	#0
		sta	HDMI_ADDR_SEQ_IX
		lda	#1
		sta	HDMI_ADDR_SEQ_DAT		; select ansi/alpha


HERE:JMP HERE
		cli
		rts


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
			.byte	$20				; 6 Vertical Displayed	 =32
			.byte	$22				; 7 VSync Position	 =&22
			.byte	$03				; 8 Interlace+Cursor	 =&03  Cursor=0, Display=0, Interlace=On+Video
			.byte	$0F				; 9 Scan Lines/Character =16
			.byte	$6D				; 10 Cursor Start Line	  =&67	Blink=On, Speed=1/32, Line=13
			.byte	$0F				; 11 Cursor End Line	  =8


font_data:		.incbin "VGA8.F16"
font_end:

		.END