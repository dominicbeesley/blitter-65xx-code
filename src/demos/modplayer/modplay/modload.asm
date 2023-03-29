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

		.include	"modplay.inc"
		.include	"common.inc"


		.export		mod_load
		.export		PrHexA
		.exportzp	zp_ld_tmp
		.exportzp	zp_ld_cmdline


		.import		mod_data
		.import		sam_data
		.import		g_song_len
		.import		song_data
		.import		my_jim_dev
		.import		song_name



		.SEGMENT "ZEROPAGE_LOAD": zeropage
zp_ld_cmdline:		.RES 2
zp_ld_ext:		.RES 4
zp_ld_fh:		.RES 1
zp_ld_tmp:		.RES 2
zp_ld_chippag:		.RES 2	; where next memory block loaded will be copied

zp_ld_orgsam		:= zp_ld_ext

zp_ld_patt_max		:= zp_ld_fh
zp_ld_samchipaddr:	.RES 3
zp_ld_samlen:		.RES 2	; bigendian TODO: could squeeze 1 more byte of sample in
zp_ld_replen:		.RES 2	; bigendian size of repeating sample - this is the length stored in table if <>0

		.CODE





mod_load:


		lda	#OSFIND_OPENIN
		jsr	OSFIND				; open file
		cmp	#0
		beq	@bknotfound

		sta	zp_ld_fh			; file handle
		tay
		ldx	#zp_ld_ext
		lda	#OSARGS_EXT
		jsr	OSARGS

		; print progress bar
		jsr	Home

		; # of 16K blocks
		lda	zp_ld_ext+3
		bne	@bktoobig
		lda	zp_ld_ext+2
		sta	zp_ld_tmp
		lda	zp_ld_ext+1

		lsr	zp_ld_tmp
		ror	A
		lsr	zp_ld_tmp
		ror	A
		lsr	zp_ld_tmp
		ror	A
		lsr	zp_ld_tmp
		ror	A
		lsr	zp_ld_tmp
		ror	A
		lsr	zp_ld_tmp
		bne	@bktoobig
		ror	A
		cmp	#$20
		bcs	@bktoobig
		sta	zp_ld_tmp


@barlp:		lda	#'.'
		jsr	OSWRCH
		dec	zp_ld_tmp
		bpl	@barlp
		
		lda	#<MODULE_CPAGE
		sta	zp_ld_chippag
		lda	#>MODULE_CPAGE
		sta	zp_ld_chippag+1			

		lda	zp_ld_fh
		sta	OSBGPB_blk_FH

		jsr	Home

		jmp	load_loop


@bknotfound:	brk
		.byte	2, "Not found"
		brk
@bktoobig:	
		jsr	Close

		brk
		.byte	3, "Too big"
		brk

Home:
		lda	#31
		jsr	OSWRCH
		lda	#0
		jsr	OSWRCH
		lda	#0
		jmp	OSWRCH
Close:
		lda	#0
		ldy	zp_ld_fh
		jmp	OSFIND


load_loop:	
		; reset load address
		lda	#$FF
		sta	OSGBPB_blk_MEM+2
		sta	OSGBPB_blk_MEM+3
		lda	#<MODULE_BASE
		sta	OSGBPB_blk_MEM
		lda	#>MODULE_BASE
		sta	OSGBPB_blk_MEM+1

		; reset load count
		lda	#0
		sta	OSGBPB_blk_NUM
		sta	OSGBPB_blk_NUM+2
		sta	OSGBPB_blk_NUM+3
		lda	#$40
		sta	OSGBPB_blk_NUM+1

		lda	#OSGBPB_READ_NOPTR
		ldx	#<OSGBPB_blk
		ldy	#>OSGBPB_blk
		jsr	OSGBPB
		php					; save carry flag

		; always copy a whole block to chip ram - even if not a full one loaded!
		lda	my_jim_dev
		cmp	#JIM_DEVNO_BLITTER
		beq	@blitter
	.ASSERT <LOAD_BLOCK_SIZE = 0, error, "LOAD_BLOCK_SIZE must be a multiple of 256"
		lda	#<MODULE_BASE
		sta	zp_ld_tmp
		lda	#>MODULE_BASE
		sta	zp_ld_tmp+1
		lda	zp_ld_chippag
		sta	fred_JIM_PAGE_LO
		lda	zp_ld_chippag+1
		sta	fred_JIM_PAGE_HI
		ldx	#>LOAD_BLOCK_SIZE
		ldy	#0
@lp_jim_ld:	lda	(zp_ld_tmp),Y
		sta	JIM,Y
		iny
		bne	@lp_jim_ld
		inc	zp_ld_tmp+1
		inc	fred_JIM_PAGE_LO
		bne	@sk_jim_pgup
		inc	fred_JIM_PAGE_HI
@sk_jim_pgup:	dex
		bne	@lp_jim_ld
		beq	@notblitter
@blitter:
		jsr	jimHardwarePage
		lda	#0
		sta	jim_DMAC_DMA_SEL
		lda	#$FF
		sta	jim_DMAC_DMA_SRC_ADDR + 0
		lda	#>MODULE_BASE
		sta	jim_DMAC_DMA_SRC_ADDR + 1
		lda	#<MODULE_BASE
		sta	jim_DMAC_DMA_SRC_ADDR + 2
		lda	zp_ld_chippag + 1
		sta	jim_DMAC_DMA_DEST_ADDR + 0
		lda	zp_ld_chippag + 0
		sta	jim_DMAC_DMA_DEST_ADDR + 1
		lda	#0
		sta	jim_DMAC_DMA_DEST_ADDR + 2
		lda	#>(LOAD_BLOCK_SIZE-1)
		sta	jim_DMAC_DMA_COUNT + 0
		lda	#<(LOAD_BLOCK_SIZE-1)
		sta	jim_DMAC_DMA_COUNT + 1
		lda	#DMACTL_ACT+DMACTL_HALT+DMACTL_STEP_DEST_UP+DMACTL_STEP_SRC_UP
		sta	jim_DMAC_DMA_CTL
@notblitter:

		; increment blit address
		clc
		lda	zp_ld_chippag
		adc	#>LOAD_BLOCK_SIZE
		sta	zp_ld_chippag
		bcc	@s1
		inc	zp_ld_chippag+1
@s1:

		lda	#'#'
		jsr	OSWRCH

		plp
		bcs	@sss1
		jmp	load_loop
@sss1:

		jsr	Close

		; get back sample info from chip ram and build a smaller sample table
		lda	my_jim_dev
		cmp	#JIM_DEVNO_BLITTER
		beq	@blitter2
		lda	#<MODULE_BASE
		sta	zp_ld_tmp
		lda	#>MODULE_BASE
		sta	zp_ld_tmp+1
		lda	#<MODULE_CPAGE			; back from start of chipram
		sta	fred_JIM_PAGE_LO
		lda	#>MODULE_CPAGE
		sta	fred_JIM_PAGE_HI
		ldx	#5				; we actually only want 1083 bytes but this will do
		ldy	#0
@lp_jim_slp:	lda	JIM,Y
		sta	(zp_ld_tmp),Y
		iny
		bne	@lp_jim_slp
		inc	zp_ld_tmp+1
		inc	fred_JIM_PAGE_LO
		bne	@sk_jim_pgup2
		inc	fred_JIM_PAGE_HI
@sk_jim_pgup2:	dex
		bne	@lp_jim_slp
		beq	@notblitter2
@blitter2:
		jsr	jimHardwarePage
		lda	#0
		sta	jim_DMAC_DMA_SEL
		lda	#$FF
		sta	jim_DMAC_DMA_DEST_ADDR + 0
		lda	#>MODULE_BASE
		sta	jim_DMAC_DMA_DEST_ADDR + 1
		lda	#<MODULE_BASE
		sta	jim_DMAC_DMA_DEST_ADDR + 2
		lda	#>MODULE_CPAGE
		sta	jim_DMAC_DMA_SRC_ADDR + 0
		lda	#<MODULE_CPAGE
		sta	jim_DMAC_DMA_SRC_ADDR + 1
		lda	#0
		sta	jim_DMAC_DMA_SRC_ADDR + 2
		lda	#>1083
		sta	jim_DMAC_DMA_COUNT + 0
		lda	#<1083
		sta	jim_DMAC_DMA_COUNT + 1
		lda	#DMACTL_ACT+DMACTL_HALT+DMACTL_STEP_DEST_UP+DMACTL_STEP_SRC_UP
		sta	jim_DMAC_DMA_CTL
@notblitter2:

		jsr	OSNEWL

		lda	#129
		jsr	OSWRCH
		lda	#157
		jsr	OSWRCH
		lda	#131
		jsr	OSWRCH

		ldx	#19
@l1:		lda	MODULE_BASE, X
		sta	song_name,X
		dex	
		bpl	@l1


		ldx	#0
@dlp:		lda	MODULE_BASE, X
		sta	mod_data+s_mod_data::mod_title,X
		beq	@s2
		jsr	OSWRCH
		inx
		cpx	#MOD_TITLE_LEN
		bne	@dlp
@s2:		
		lda	#' '
		jsr	OSWRCH
		jsr	OSWRCH
		lda	#156
		jsr	OSWRCH
		jsr	OSNEWL

		; song len
		lda	MODULE_BASE+HDR_SONG_LEN_OFFS
		sta	g_song_len

		; find highest pattern number and setup song

		lda	#0
		sta	zp_ld_patt_max
		ldx	#SONG_DATA_LEN-1
@pmlp:		lda	MODULE_BASE+HDR_SONG_DATA_OFFS,X
		sta	song_data,X
		cmp	zp_ld_patt_max
		bcc	@pmsk1
		sta	zp_ld_patt_max
@pmsk1:		dex
		bpl	@pmlp

		PRINT "Highest Pattern # "
		lda	zp_ld_patt_max
		jsr	PrHexA

		; calculate start of samples addresses
		lda	#<HDR_PATT_DATA_OFFS
		sta	zp_ld_samchipaddr		; lo address
		lda	#0		
		sta	zp_ld_samchipaddr+2
		ldx	zp_ld_patt_max
		inx
		txa
		asl	a
		rol	zp_ld_samchipaddr+2
		asl	a
		rol	zp_ld_samchipaddr+2
		adc	#(>HDR_PATT_DATA_OFFS) + (<MODULE_CPAGE)
		sta	zp_ld_samchipaddr+1
		lda	zp_ld_samchipaddr+2
		adc	#>MODULE_CPAGE
		sta	zp_ld_samchipaddr+2
@noc1:		
		lda	#' '
		jsr	OSWRCH
		lda	zp_ld_samchipaddr+2
		jsr	PrHexA
		lda	zp_ld_samchipaddr+1
		jsr	PrHexA
		lda	zp_ld_samchipaddr+0
		jsr	PrHexA

		jsr	OSNEWL


		; setup pointer to sample table as loaded
		lda	#<(MODULE_BASE+HDR_SONG_SAMPLES)
		sta	zp_ld_orgsam
		lda	#>(MODULE_BASE+HDR_SONG_SAMPLES)
		sta	zp_ld_orgsam+1


		.ASSERT .SIZEOF(s_saminfo) = 8, error, "sample table must fit 32 samples exactly in 256 bytes"
		lda	#1
		sta	zp_ld_tmp	; sample counter#
		lda	#8
@samlp:		pha
		lda	zp_ld_tmp
		jsr	PrHexA
		pla

		tax					; offset into new sample info table

		; 
		ldy	#s_modsaminfo::len+1		; big endian in both tables
		lda	(zp_ld_orgsam),Y		; len / 2
		asl	A
		sta	zp_ld_samlen+1
		dey
		lda	(zp_ld_orgsam),Y		; len / 2
		rol	A
		sta	zp_ld_samlen+0
		iny
		bcc	@samlenok
		jmp	brksamtoolong
@samlenok:
		lda	zp_ld_samlen
		bne	@samlenok2
		lda	zp_ld_samlen+1
		cmp	#3
		bcs	@samlenok2

		lda	#0
		sta	zp_ld_samlen+1			
		sta	zp_ld_samlen
		jmp	@skip_zero_sample

@samlenok2:

		; set sample start address and add len at same time

		lda	zp_ld_samchipaddr
		sta	sam_data+s_saminfo::addr+1,X	; low address of start of sample
		adc	zp_ld_samlen+1
		sta	zp_ld_samchipaddr

		lda	zp_ld_samchipaddr+1
		sta	sam_data+s_saminfo::addr+0,X	; hi address of start of sample
		adc	zp_ld_samlen+0
		sta	zp_ld_samchipaddr+1

		php
		lda	zp_ld_samchipaddr+2
		sta	zp_ld_tmp+1
		adc	#0
		sta	zp_ld_samchipaddr+2
		; fine tune in top nibble
		ldy	#s_modsaminfo::fine
		lda	(zp_ld_orgsam),Y
		asl	A	
		asl	A	
		asl	A	
		asl	A	
		ora	zp_ld_tmp+1
		sta	sam_data+s_saminfo::addr_b,X	; bank address of start of sample
		plp


		ldy	#s_modsaminfo::repoffs+1	; big endian in both tables
		lda	(zp_ld_orgsam),Y		; repeat offs / 2
		sta	zp_ld_replen+1
		asl	A
		sta	sam_data+s_saminfo::roff+1,X
		dey
		lda	(zp_ld_orgsam),Y		; repeat offs / 2
		sta	zp_ld_replen
		rol	A
		sta	sam_data+s_saminfo::roff,X
		iny

		ldy	#s_modsaminfo::vol
		lda	(zp_ld_orgsam),Y
		cmp	#$40
		bcc	@svollim
		lda	#$3F
@svollim:	sta	sam_data+s_saminfo::repfl,X

		ldy	#s_modsaminfo::replen		; big endian in both tables
		lda	(zp_ld_orgsam),Y		; repeat offs / 2
		bne	@repeatyes
		iny
		lda	(zp_ld_orgsam),Y		; repeat offs / 2
		cmp	#3
		bcc	@repeatno
@repeatyes:	

		lda	sam_data+s_saminfo::repfl,X
		ora	#$80				; flag repeat
		sta	sam_data+s_saminfo::repfl,X



		; check to see if repeat length + offset is less than sample length
		; if it is make sample that length or it will sound 'orrible
		clc
		ldy	#s_modsaminfo::replen+1		; big endian in both tables
		lda	(zp_ld_orgsam),Y		; repeat len / 2
		adc	zp_ld_replen+1
		sta	zp_ld_replen+1	
		dey
		lda	(zp_ld_orgsam),Y		; repeat len / 2
		adc	zp_ld_replen
		sta	zp_ld_replen

		asl	zp_ld_replen+1
		rol	zp_ld_replen


		sec
		lda	zp_ld_samlen+1
		sbc	zp_ld_replen+1
		lda	zp_ld_samlen
		sbc	zp_ld_replen
		;bcs	@repdone

		; truncate
		lda	zp_ld_replen
		sta	zp_ld_samlen
		lda	zp_ld_replen+1
		sta	zp_ld_samlen+1
@repeatno:

@repdone:

@skip_zero_sample:
		lda	zp_ld_samlen+1
		sec
		sbc	#1		
		sta	sam_data+s_saminfo::len+1,X
		lda	zp_ld_samlen+0
		sbc	#0
		sta	sam_data+s_saminfo::len,X


		lda	#' '
		jsr	OSWRCH
		jsr	OSWRCH
		jsr	OSWRCH

		inc	zp_ld_tmp

		clc
		lda	zp_ld_orgsam
		adc	#.SIZEOF(s_modsaminfo)
		sta	zp_ld_orgsam
		bcc	@ss1
		inc	zp_ld_orgsam+1
@ss1:

		txa
		clc
		adc	#.SIZEOF(s_saminfo)		; 8
		beq	@samlp_done
		jmp	@samlp

@samlp_done:




		rts



jimHardwarePage:
		pha
		lda	#<jim_page_DMAC
		sta	fred_JIM_PAGE_LO
		lda	#>jim_page_DMAC
		sta	fred_JIM_PAGE_HI
		pla
		rts

brksamtoolong:
		brk
		.byte 4, "Sample too long > 64K"
		brk

PrHexA:		PHA
		LSR A
		LSR A
		LSR A
		LSR A
		JSR PrNybble
		PLA
PrNybble:	AND #15
		CMP #10
		BCC PrDigit
		ADC #6
PrDigit:	ADC #'0'
		JMP	OSWRCH


		.BSS
OSGBPB_blk:
OSBGPB_blk_FH:	.RES	1
OSGBPB_blk_MEM:	.RES	4
OSGBPB_blk_NUM:	.RES	4
OSGBPB_blk_PTR:	.RES	4



		.END