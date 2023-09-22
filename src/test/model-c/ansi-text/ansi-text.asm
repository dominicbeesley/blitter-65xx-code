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
zp_tmp2			:=	$73


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


;;		; palette black and white
;;		lda	#$0F
;;		clc
;;pplp:		sta	HDMI_ADDR_VIDPROC_PAL
;;		adc	#$10
;;		bpl	pplp
;;
;;		lda	#$88
;;pplp2:		sta	HDMI_ADDR_VIDPROC_PAL
;;		adc	#$10
;;		bcc	pplp2

		; palette colour
		lda	#$0F
		clc
ppl:		sta	HDMI_ADDR_VIDPROC_PAL
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


		jsr	wait

		; access text memory via JIM and fill with a repeating pattern of chars

ALPHA_BASE	:= $70	; page number in screen mem

again:
		; fill screen memory with attributes and chars
		ldx	#32				; number of lines
		ldy	#0

		lda	#>(HDMI_PAGE_MEM+ALPHA_BASE)
		sta	fred_JIM_PAGE_HI
		lda	#<(HDMI_PAGE_MEM+ALPHA_BASE)
		sta	fred_JIM_PAGE_LO
@flp3:		lda	#80
		sta	zp_tmp2
@flp:		; character
		lda	fred_JIM_PAGE_LO
		ror	A
		tya
		ror	A
		sta	JIM,Y
		iny
		; attribute
		sec
		lda	#80
		sbc	zp_tmp2
		lsr	A
		lsr	A		
		and	#$F				; foreground colour
		sta	zp_tmp		
		txa	
		and	#$F
		eor	#$F
		asl	A
		asl	A
		asl	A
		asl	A
		ora	zp_tmp
		sta	JIM,Y
		iny
		bne	@fsk1
		inc	fred_JIM_PAGE_LO
@fsk1:		dec	zp_tmp2
		bne	@flp
		dex
		bne	@flp3


		lda	#>HDMI_PAGE_REGS
		sta	fred_JIM_PAGE_HI
		lda	#<HDMI_PAGE_REGS
		sta	fred_JIM_PAGE_LO

		; point at font data for now
		lda 	#12
		sta	HDMI_ADDR_CRTC_IX
		lda	#$00
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


		jsr	wait

; copy test card image
		
		ldx	#16				; number of pages to fill
		ldy	#0

		lda	#<screen_data
		sta	zp_ptr
		lda	#>screen_data
		sta	zp_ptr+1

		lda	#>(HDMI_PAGE_MEM+ALPHA_BASE)
		sta	fred_JIM_PAGE_HI
		lda	#<(HDMI_PAGE_MEM+ALPHA_BASE)
		sta	fred_JIM_PAGE_LO

@flp2:		lda	(zp_ptr),Y
		sta	JIM,Y
		iny
		bne	@flp2
		inc	fred_JIM_PAGE_LO
		inc	zp_ptr+1
		dex
		bne	@flp2


		jsr	wait

		jmp	again

wait:
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


screen_data:		.incbin "COLOUR.VID"
scren_end:

		.macro	PAL IX,R,G,B			
			.word (IX<<4)+R+(G<<12)+(B<<8)
		.endmacro

palette:		PAL	0,  0,  0,  0		; black
			PAL	1,  0,  0,  8		; blue
			PAL	2,  0,  8,  0		; green
			PAL	3,  0,  8,  8		; cyan
			PAL	4,  8,  0,  0		; red
			PAL	5,  8,  0,  8		; magenta
			PAL	6,  8,  8,  0		; yellow
			PAL	7,  8,  8,  8		; grey

			PAL	8,  5,  5,  5		; dark grey
			PAL	9,  0,  0, 15		; light blue
			PAL	10, 0, 15,  0		; light green
			PAL	11, 0, 15, 15		; light cyan
			PAL	12,15,  0,  0		; light red
			PAL	13,15,  0, 15		; light magenta
			PAL	14,15, 15,  0		; light yellow
			PAL	15,15, 15, 15		; white
			
		.END