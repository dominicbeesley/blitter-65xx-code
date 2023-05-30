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

; all the routines here assume jimPageChipset has been called to set the device
; page to point at the chipset

		.include	"hardware.inc"
		.include	"mosrom.inc"
		.include	"oslib.inc"
		.include	"bltutil.inc"
		.include "bltutil_romheader.inc"
		.include "bltutil_jimstuff.inc"


		.export i2c_writebyte
		.export i2c_readbyte
		.export i2c_write_devaddr		
		.export i2c_OSWORD_13
		.export bltutil_firmCMOSWrite	
		.export bltutil_firmCMOSRead


CMOS_PAGE_FIRMWARE = $11		; page in CMOS / Flash EEPROM for BLTUTIL's config
DEV_CMOS_EEPROM = $A0		; device number for CMOS/EEPROM

	.macro I2C_WAIT
		.local lp
lp:		bit	jim_I2C_STAT
		bmi	lp
	.endmacro


i2c_writebyte:	; on entry A contains byte to write, Cy = start, Ov = stop
		; on exit VS if not ACK
		php
		I2C_WAIT		
		plp
		sta	jim_I2C_DATA
		lda	#I2C_BUSY
		bcc	@nostart
		ora	#I2C_START
@nostart:	bvc	@nostop
		ora	#I2C_STOP|I2C_NACK
@nostop:		sta	jim_I2C_STAT
		I2C_WAIT
		rts

i2c_readbyte:	; on entry Cy contains NOT Ack|Stop
		php
		I2C_WAIT
		plp
		lda	#I2C_BUSY|I2C_RNW
		bcc	@nostop
		ora	#I2C_NACK|I2C_STOP
@nostop:	sta	jim_I2C_STAT
		I2C_WAIT
		lda	jim_I2C_DATA
		rts


i2c_write_devaddr:; on entry Cy contains 1 for read else write
		pha
		php
		ror	A		; clear/replace bottom bit of device no
		plp		
		rol	A		; bottom bit now contains carr bit
		sec			; set start condition for device address (re)select
		jsr	i2c_writebyte
		pla
		rts




i2c_OSWORD_13:	jsr	jimPageChipset

		ldy	#3
		lda	(zp_mos_OSBW_X),Y
		iny
		ora	(zp_mos_OSBW_X),Y
		bmi	@ret		; bad lengths
		beq	@probe

		ldy	#3
		lda	(zp_mos_OSBW_X),Y ; # to write
		tax
		beq	@donewrite


		clc
		clv
		jsr	@setdev
		bvs	@ret

		ldy	#6
@wrloop:		lda	(zp_mos_OSBW_X),Y
		clv
		dex
		bne	@notlastwrite
		; this is last write will we be doing reads, if not set overflow
		pha
		tya
		pha
		ldy	#4
		lda	(zp_mos_OSBW_X),Y
		bne	@notlastwriteandread
		bit	bit_SEV		; set overflow
@notlastwriteandread:
		pla
		tay
		pla
@notlastwrite:	inx		
		clc			; no start cond
		jsr	i2c_writebyte
	
		bcc 	@writeok
		lda	#0
		sta	jim_I2C_STAT	; force a STOP
		jsr	@x23		; update write count
		bcs	@ret		; exit

@writeok:	iny
		dex
		bne	@wrloop
		jsr	@x23		; update write count

@donewrite:	; read

		ldy	#4
		lda	(zp_mos_OSBW_X),Y ; # to read
		tax
		beq	@ret		; we're done

		sec			; indicate a read
		clv
		jsr	@setdev
		bvs	@ret


		ldy	#6
@rdlp:		txa
		eor	#$FF
		cmp	#$FE
		jsr	i2c_readbyte
		sta	(zp_mos_OSBW_X),Y
		iny
		dex
		bne	@rdlp
		txa
		ldy	#4
		sta	(zp_mos_OSBW_X),Y
		jmp	ServiceOutA0


@probe:		bit	bit_SEV
		clc
		jsr	@setdev
@ret:		jmp	ServiceOutA0

@setdev:		tya
		pha
		ldy	#5
		lda	(zp_mos_OSBW_X),Y	;device address
		jsr	i2c_write_devaddr
		and	#$FE
		bvc	@ok1
		ora	#1
@ok1:		sta	(zp_mos_OSBW_X),Y ; save device address with bottom bit indicates ack
		pla
		tay
		rts



@x23:		ldy	#3
		txa
		sta	(zp_mos_OSBW_X),Y
		rts

bit_SEV:	.byte	$C0

		; read single configuration byte at location $1100+Y to A, corrupts X, Y
bltutil_firmCMOSRead:		
		tya
		pha		; + 7 - address low byte
		lda	#CMOS_PAGE_FIRMWARE	
		pha		; + 6 - address hi byte - firmware page
		lda	#DEV_CMOS_EEPROM
		pha		; + 5 - dev no
		lda	#1
		pha		; + 4 - number to read
		lda	#2
		pha		; + 3 - number to write
		lda	#OSWORD_OP_I2C
		pha		; + 2 - I2C opcode
		lda	#7
		pha		; + 1 - len out
		lda	#8
		tsx
		pha		; + 0 - len in
		ldy	#1
		lda	#OSWORD_BLTUTIL
		jsr	OSWORD
		pla
		pla
		pla
		pla
		pla
		pla
		pla
		tax
		pla
		txa
		rts

bltutil_firmCMOSWrite:		
		pha		; + 8 - data
		tya
		pha		; + 7 - address low byte
		lda	#CMOS_PAGE_FIRMWARE	
		pha		; + 6 - address hi byte - firmware page
		lda	#DEV_CMOS_EEPROM
		pha		; + 5 - dev no
		lda	#0
		pha		; + 4 - number to read
		lda	#3
		pha		; + 3 - number to write
		lda	#OSWORD_OP_I2C
		pha		; + 2 - I2C opcode
		lda	#5
		pha		; + 1 - len out
		lda	#9
		tsx
		pha		; + 0 - len in
		ldy	#1
		lda	#OSWORD_BLTUTIL
		jsr	OSWORD
		tsx
		txa
		clc
		adc	#9
		tax
		txs
		rts
