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

MAX_FILENAME	:=	20
NUM_FILES	:=	50
FILESPERSCR	:=	20

		.include	"oslib.inc"
		.include	"common.inc"
		.include	"hardware.inc"
		.include	"mosrom.inc"

		.ZEROPAGE
zp_ptr:		.res 2
zp_ptr2:	.res 2
zp_ptr3:	.res 2
zp_ctr:		.res 1
		.CODE 

enter:		txs
		stx	oldstack

		lda	BRKV
		sta	oldBRKV
		lda	BRKV+1
		sta	oldBRKV+1

reenter2:	ldx	oldstack
		txs
		; mode 7
		lda	#22
		jsr	OSWRCH
		lda	#7
		jsr	OSWRCH

		; assume we're in the right directory

		ldx	#<dir_m_s
		ldy	#>dir_m_s
		jsr	OSCLI


		ldx	#<filenames
		ldy	#>filenames
		stx	zp_ptr3
		sty	zp_ptr3+1

		lda	#0
		sta	filectr

		; setup osgbp block

		sta	osgbpb_block
		ldx	#12
		bne	dir_loop_first

		; .dir loop
dir_loop:	ldx	#8
dir_loop_first:	
makeosgbplp:	lda	osgbpb_block_template,X
		sta	osgbpb_block,X
		dex
		bne	makeosgbplp
		lda	#8
		ldx	#<osgbpb_block
		ldy	#>osgbpb_block
		jsr	OSGBPB

		lda	osgbpb_block+5
		bne	done_dirloop

		ldx	osgbpb_ret
		cpx	#MAX_FILENAME+1
		bcc	@s1
		jsr	dir_top
		brk
		.byte	255
		.byte	"File too long",0
@s1:		
		inc	filectr
		ldy	#0
@l1:		lda	osgbpb_ret+1,Y
		sta	(zp_ptr3),Y
		iny
		dex
		bne	@l1
		lda	#' '
		cpy	#MAX_FILENAME
		beq	@s2
@l2:		sta	(zp_ptr3),Y
		iny
		bne	@l2

@s2:		clc
		lda	zp_ptr3
		adc	#MAX_FILENAME
		sta	zp_ptr3
		bcc	dir_loop
		inc	zp_ptr3+1
		bne	dir_loop


done_dirloop:
		jsr	dir_top

		; setup screen
		lda	#12
		jsr	OSWRCH


		lda	filectr
		cmp	#FILESPERSCR+1
		bcc	nomorebanner

		lda	#31
		jsr	OSWRCH
		lda	#0
		jsr	OSWRCH
		lda	#23
		jsr	OSWRCH
		ldx	#<morebanner_s
		ldy	#>morebanner_s
		jsr	print0
nomorebanner:

		lda	#31
		jsr	OSWRCH
		lda	#0
		jsr	OSWRCH
		lda	#0
		jsr	OSWRCH
		ldx	#<menubanner_s
		ldy	#>menubanner_s
		jsr	print0


		lda	#0
		sta	fileoffs

show_files:	ldx	fileoffs
		jsr	find_file


		lda	fileoffs
		sta	zp_ctr
		lda	#0
		sta	zp_ctr+1

show_files_lp:	lda	zp_ctr
		cmp	filectr
		bcs	nomorefilestoshow

		lda	#31
		jsr	OSWRCH
		lda	#1
		jsr	OSWRCH
		clc
		lda	zp_ctr+1
		adc	#2
		jsr	OSWRCH

		lda	#131
		jsr	OSWRCH
		lda	zp_ctr+1
		adc	#'A'
		jsr	OSWRCH
		lda	#134
		jsr	OSWRCH

		ldx	#MAX_FILENAME
		ldy	#0

show_oneflp:	lda	(zp_ptr3),Y
		jsr	OSWRCH
		iny
		dex
		bne	show_oneflp

		clc
		lda	zp_ptr3
		adc	#MAX_FILENAME
		sta	zp_ptr3
		bcc	@s7
		inc	zp_ptr3+1
@s7:
		inc	zp_ctr
		inc	zp_ctr+1
		lda	zp_ctr+1
		cmp	#FILESPERSCR
		bcc	show_files_lp		
		bcs	nomorescreenlines

nomorefilestoshow:

blankfileslp:
		lda	#31
		jsr	OSWRCH
		lda	#1
		jsr	OSWRCH
		clc
		lda	zp_ctr+1
		adc	#2
		jsr	OSWRCH

		lda	#131
		jsr	OSWRCH
		lda	#'#'
		jsr	OSWRCH
		lda	#134
		jsr	OSWRCH

		lda	#' '
		ldx	#MAX_FILENAME
@s11:		jsr	OSWRCH
		dex
		bne	@s11

		inc	zp_ctr+1
		lda	zp_ctr+1
		cmp	#FILESPERSCR
		bcc	blankfileslp		



nomorescreenlines:




waitkey:	; wait for a key
		lda	#$81
		ldx	#255
		ldy	#127
		jsr	OSBYTE
		cpy	#27
		beq	escapeme
		cpy	#0
		bne	waitkey
		
		cpx	#' '
		beq	nextpage		

		;decode and load
		txa
		sec
		sbc	#'A'
		bcc	waitkey
		clc
		adc	fileoffs
		cmp	filectr
		bcs	waitkey

		; we now have a winner!
		tax
		jsr	find_file

		ldx	#0
@l1:		lda	modplay_s,X
		beq	@s1
		sta	$700,X
		inx
		bne	@l1
@s1:		ldy	#0
		ldx	#MAX_FILENAME
@l2:		lda	(zp_ptr3),Y
		sta	$70A,Y
		iny
		dex
		bne	@l2

		lda	#13
		sta	$70A,Y

		ldx	#<reenter
		stx	BRKV
		ldx	#>reenter
		stx	BRKV+1

		ldx	#<$700
		ldy	#>$700
		jsr	OSCLI



		jmp	waitkey

nextpage:	lda	fileoffs
		clc
		adc	#FILESPERSCR
		cmp	filectr
		bcc	@s10
		lda	#0
@s10:		sta	fileoffs
		jmp	show_files


escapeme:	
		lda	#$7E			;ack escape
		jsr	OSBYTE

		lda	oldBRKV+1
		sta	BRKV+1
		lda	oldBRKV
		sta	BRKV

		ldx	oldstack
		txs

		rts

dir_top:
		lda	#<dollar
		sta	osgbpb_block
		lda	#>dollar
		sta	osgbpb_block+1
		lda	#5
		ldx	#<osgbpb_block
		ldy	#>osgbpb_block
		jsr	OSFILE

		cmp	#2
		beq	dir_top_up

		ldx	#<dir_top_s
		ldy	#>dir_top_s
		jmp	OSCLI

dir_top_up:
		ldx	#<dir_top_adfs_s
		ldy	#>dir_top_adfs_s
		jmp	OSCLI

find_file:
		lda	#0
		sta	zp_ptr3
		sta	zp_ptr3+1
		
@l4:		dex
		bmi	@s7
		clc	
		lda	zp_ptr3
		adc	#MAX_FILENAME
		sta	zp_ptr3
		bcc	@s5
		inc	zp_ptr3+1
@s5:		jmp	@l4
@s7:		clc
		lda	zp_ptr3
		adc	#<filenames
		sta	zp_ptr3
		lda	#>filenames
		adc	zp_ptr3+1
		sta	zp_ptr3+1
		rts


print0:		stx	zp_ptr
		sty	zp_ptr+1
		ldy	#0
@l:		lda	(zp_ptr),y
		beq	@s
		jsr	OSWRCH
		iny
		bne	@l
@s:		rts

reenter:	

		; clear screen and print error
		jsr	OSNEWL
		jsr	OSNEWL
		lda	#12
		jsr	OSWRCH		

		ldy	#1
msglp:		lda	(zp_mos_error_ptr),Y
		beq	@s
		jsr	OSWRCH
		iny
		bne	msglp
		jsr	OSNEWL
		jsr	OSNEWL

		lda	#OSBYTE_15_FLUSH_INPUT
		jsr	OSBYTE

		; pause to show the message for a while
@s:		lda	#20
		sta	zp_ctr
		ldx	#0
		ldy	#0
lp:		dey
		bne	lp
		dex	
		bne	lp
		lda	#OSBYTE_129_INKEY
		ldx	#0
		ldy	#0
		jsr	OSBYTE
		bcc	@s2
		cpy	#27
		beq	@s2

		dec	zp_ctr
		bne	lp

@s2:
		lda	#OSBYTE_126_ESCAPE_ACK
		jsr	OSBYTE				; acknowledge any Escape

		jmp	reenter2

		.DATA
morebanner_s:	.byte 132,157,131,"  press",136,"SPACE",137,"for more",0
menubanner_s:	.byte 129, "Modplay",130,"tracker menu",131,"(c)2020",0

dir_m_s:	.byte "DIR M", 13
dir_top_s:	.byte "DIR $", 13
dir_top_adfs_s:	.byte "DIR ^", 13
modplay_s:	.byte "MODPLAY M.",0
dollar:		.byte "$",13

osgbpb_block_template:
		.byte 	0			; +0 handle/cycle
		.word	osgbpb_ret		; +1 data address
		.word	$FFFF		
		.dword	1			; + 5 count
		.dword	0			; + 9 XFER

oldstack:	.res	1
oldBRKV:	.res	2

		.BSS

filectr:	.res	1
fileoffs:	.res	0

osgbpb_block:	.res	13

osgbpb_ret:	.res 	MAX_FILENAME*2

filenames:	.res 	MAX_FILENAME*NUM_FILES

		.END
