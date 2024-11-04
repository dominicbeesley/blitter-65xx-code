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

		.export i2c_writebyte
		.export i2c_readbyte
		.export i2c_write_devaddr		
		.export i2c_OSWORD_13
		.export CMOS_ReadYX
		.export CMOS_WriteYX
		.export CMOS_WriteFirmX	
		.export CMOS_ReadFirmX
		.export CMOS_WriteMosX	
		.export CMOS_ReadMosX


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


	.scope
	; add $80 to A if map 1
CMOS_addRomOffs:	rol	A
		pha
		jsr	cfgGetRomMap
		ror	A		; map in Cy
		pla
		ror	A
		rts


; CMOS read / write 
; on entry X contains an offset in either MOS or BLTUTIL page
; if romset = 1 then $80 is added


		; read single configuration byte at location $1100+X to A, corrupts X, Y
::CMOS_ReadMosX:	pha					; space for return value
		tya
		pha
		ldy	#BLTUTIL_CMOS_PAGE_MOS
		bne	CMOS_ReadYX_int
::CMOS_ReadFirmX:	pha					; space for return value
		tya
		pha
		ldy	#BLTUTIL_CMOS_PAGE_FIRMWARE
CMOS_ReadYX_int:	txa
		jsr	CMOS_addRomOffs
		jmp	CMOS_ReadYX_int2

; Y = page in CMOS
; X = offset in page in CMOS
; on Exit
; X,Y preserved
; A = byte read
; note OSBYTE_X,Y,A registers are blammed by calling OSWORD!

::CMOS_ReadYX:	pha
		tya
		pha
		txa
CMOS_ReadYX_int2:	pha

		pha				; pointless - to make same as write

		; stack
		;	+4	return A
		;	+3	caller Y
		;	+2	caller X
		;	+1	-pad-


		jsr	CMOS_addRomOffs
		pha		; block + 7 - address low byte
		tya
		pha		; block + 6 - address hi byte - firmware page
		lda	#DEV_BLTUTIL_CMOS_EEPROM
		pha		; block + 5 - dev no
		lda	#1
		pha		; block + 4 - number to read
		lda	#2
		pha		; block + 3 - number to write
		lda	#OSWORD_OP_I2C
		pha		; block + 2 - I2C opcode
		lda	#7
		pha		; block + 1 - len out
		lda	#8
		tsx
		pha		; block + 0 - len in
		ldy	#1

		;     stack     block 
		;	+C		return A
		;	+B		caller Y
		;	+A		caller X
		;	+9		-pad-
		;	+8	+7	addr lo
		;	+7	+6	addr hi
		;	+6	+5	i2c dev no
		;	+5	+4	n read
		;	+4	+3	n write
		;	+3	+2	i2c op
		;	+2	+1	len out
		;	+1	+0	len in

		lda	#OSWORD_BLTUTIL
		jsr	OSWORD

		;     stack    block 
		;	+C		return A
		;	+B		caller Y
		;	+A		caller X
		;	+9		-pad-
		;	+8	+7	-
		;	+7	+6	d ret
		;	+6	+5	-
		;	+5	+4	-
		;	+4	+3	-
		;	+3	+2	-
		;	+2	+1	-
		;	+1	+0	-

		tsx
		lda	$107,X		
		sta	$10C,X			; return A
cmos_exit:	tsx
		txa
		clc
		adc	#9
		tax
		txs

		pla	
		tax
		pla
		tay
		pla
		rts

::CMOS_WriteMosX:	pha
		tya
		pha	
		ldy	#BLTUTIL_CMOS_PAGE_MOS
		bne	CMOS_WriteYX_int
::CMOS_WriteFirmX:pha
		tya
		pha		
		ldy	#BLTUTIL_CMOS_PAGE_FIRMWARE	
CMOS_WriteYX_int:	txa
		pha		; save caller X
		jsr	CMOS_addRomOffs		
		jmp	CMOS_WriteYX_int2
::CMOS_WriteYX:	pha
		tya
		pha
		txa		
		pha		; save caller X
CMOS_WriteYX_int2:pha		; + 8 - room for data
		pha		; + 7 - address low byte
		tya
		pha		; + 6 - address hi byte - firmware page
		lda	#DEV_BLTUTIL_CMOS_EEPROM
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

		;    stack     block 
		;	+C		caller A
		;	+B		caller Y
		;	+A		caller X
		;	+9	+8	data
		;	+8	+7	addr lo
		;	+7	+6	addr hi
		;	+6	+5	i2c dev no
		;	+5	+4	n read
		;	+4	+3	n write
		;	+3	+2	i2c op
		;	+2	+1	len out
		;	+1	+0	len in

		lda	$10B,X
		sta	$108,X			; move data into block from stacked A

		lda	#OSWORD_BLTUTIL
		jsr	OSWORD

		jsr	jimPageChipset

		; we need to poll for write to finish
@poll:		lda	#DEV_BLTUTIL_CMOS_EEPROM
		bit	bit_SEV				; set V = STOP
		sec
		jsr	i2c_writebyte
		bvs	@poll

		jmp	cmos_exit

	.endscope