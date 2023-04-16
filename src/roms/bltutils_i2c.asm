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


		.export i2c_writebyte
		.export i2c_readbyte
		.export i2c_write_devaddr		
		.export i2c_OSWORD_13


	.macro I2C_WAIT
		.local lp
lp:		bit	jim_I2C_STAT
		bmi	lp
	.endmacro


i2c_writebyte:	; on entry A contains byte to write, Cy = start, Ov = stop
		; on exit CS if not ACK
		php
		I2C_WAIT		
		plp
		sta	jim_I2C_DATA
		lda	#I2C_BUSY
		bcc	@nostart
		ora	#I2C_START
@nostart:	bvc	@nostop
		ora	#I2C_STOP|I2C_NACK
@nostop:	sta	jim_I2C_STAT
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
		clv			; assume no immediate stop
		jsr	i2c_writebyte
		pla
		rts




i2c_OSWORD_13: