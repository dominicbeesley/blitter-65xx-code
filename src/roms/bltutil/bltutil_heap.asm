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

		; TODO : user option for preserve on break

		.include "oslib.inc"
		.include "hardware.inc"
		.include "mosrom.inc"
		.include "bltutil.inc"

		.export heap_init
		.export heap_OSWORD_bltutil
		.export cmdHeapInfo


; TODO: change to all big-endian storage so the heap can be shared with 6x09 more easily, or keep 
; as LE so that 65816 can use same?

; The allocation table is a single page of 64 entries each entry is
;	+0	16bit	PageNum
;	+2	16bit	Flags | Number of pages
;		Flags are in top two bits of Number of pages
;	$80	Entry is used
;	$40	Entry is a free "hole" in the map


HEAPFLAG_FREE	:=	$40
HEAPFLAG_INUSE	:=	$80


		.CODE

		; on entry A contains the number of 64 banks to use for the heap

heap_init:	jsr	jimSetDEV_either		; either Blitter or Paula don't care which here
		bcc	@ok1
		rts
@ok1:		

		jsr	jimPageWorkspace


@s1:		ldx	#0
		stx	JIM+SCRATCH_HEAPTOP
		sta	JIM+SCRATCH_HEAPTOP+1		; as passed in in A - number of banks

		ldx	#$01				; set lower limit at 64k
		stx	JIM+SCRATCH_HEAPLIM+1
		dex
		stx	JIM+SCRATCH_HEAPLIM


		jmp	heap_clear_int

heap_clear:	
		jsr	jimSetDEV_either		; either Blitter or Paula don't care which here
		bcc	@ok1
		rts
@ok1:		jsr	jimPageWorkspace
heap_clear_int:
		ldx	JIM+SCRATCH_HEAPTOP
		ldy	JIM+SCRATCH_HEAPTOP+1

		; check to see if limit is > HEAPLIM
		cpy	JIM+SCRATCH_HEAPLIM+1
		bcc	@heap_no_space
		bne	@heap_has_space
		cpx	JIM+SCRATCH_HEAPLIM
		bcc	@heap_no_space
		beq	@heap_no_space

@heap_has_space:
		
		jsr	decXY
		stx	JIM+SCRATCH_HEAPBOT
		sty	JIM+SCRATCH_HEAPBOT+1		; set heap limit at top of RAM-1 (reserve one page for block map)


		; clear the heap map
		jsr	jimPageAllocTable
		ldx	#0
		lda	#0
@l:		sta	JIM,X
		dex
		bne	@l

		rts

@heap_no_space:	

		stx	JIM+SCRATCH_HEAPBOT
		sty	JIM+SCRATCH_HEAPBOT+1		; set heap limit at top of RAM
		rts


decXY:		cpx	#0
		beq	@s2
		dex
		rts
@s2:		dex
		dey
		rts

jimPageAllocTable:					; TODO return error if no alloc table!
		pha
		txa
		pha
		tya
		pha
		jsr	jimPageWorkspace
		ldx	JIM+SCRATCH_HEAPTOP
		ldy	JIM+SCRATCH_HEAPTOP+1
		jsr	decXY
		stx	fred_JIM_PAGE_LO
		sty	fred_JIM_PAGE_HI
		pla
		tay
		pla
		tax
		pla
		rts


;		A = $99
;	XY?0 <16 - Get SWROM base address
;	---------------------------------
;	On Entry:
;		XY?0 	= Rom #
;		XY?1	= flags: (combination of)
;			$80	= current set
;			$C0	= alternate set
;			$20	= ignore memi (ignore inhibit)
;			$01	= map 1 (map 0 if unset)
;		XY?2	?
;	On Exit:
;		XY?0	= return flags
;			$80	= set if On board Flash
;			$40	= set if SYS
;			$20	= memi (swrom/ram inhibited)
;			$01	= map 1 (map 0 if not set)
;		XY?1	= rom base page lo ($80 if SYS)
;		XY?2	= rom base page hi ($FF if SYS)



heap_OSWORD_bltutil:	
	;	+0	params len
	;	+1	params ret len
	;	+2	op number < $10 == get rom #

		ldy	#2
		lda	(zp_mos_OSBW_X),Y		; get rom/call no
		cmp	#$10			
		bcs	@s1
		jmp	oswordGetRomBase
@s1:		cmp	#OSWORD_OP_ALLOC
		bne	@s2
		jmp	oswordAlloc
@s2:		cmp	#OSWORD_OP_FREE
		beq	oswordFree
		cmp	#OSWORD_OP_I2C
		bne	@s3
		jmp	i2c_OSWORD_13
@s3:		jmp	ServiceOutA0

oswordFree:	jsr	jimSetDEV_either
		bcs	@exit
		jsr	jimPageAllocTable

		; search alloc table for our block
		ldx	#0
@fndlp:		lda	JIM+3,X				; is block allocated;
		bpl	@skfnd
		and	#HEAPFLAG_FREE			; is it already freed
		bne	@skfnd
		ldy	#3
		lda	(zp_mos_OSBW_X),Y
		cmp	JIM+0,X
		bne	@skfnd
		iny
		lda	(zp_mos_OSBW_X),Y
		cmp	JIM+1,X
		beq	@fnd
@skfnd:		inx
		inx
		inx
		inx
		bne	@fndlp
@exit:		jmp	ServiceOutA0
@fnd:		lda	JIM+3,X				; mark block as free
		ora	#HEAPFLAG_FREE
		sta	JIM+3,X

		
heap_coalesceX:
		; try to either join the current block with other neighbouring blocks, or if at
		; tbe bottom of the heap return the space to the user area

		txa
		pha				; save for later if we need it

@again:
		pla
		pha
		tax				; get current block number

		; get end address of current block
		clc 
		lda	JIM+0,X
		adc	JIM+2,X
		sta	zp_mos_OSBW_X
		lda	JIM+3,X
		and	#$3F
		adc	JIM+1,X
		sta	zp_mos_OSBW_X+1

		; check to see if there are any blocks immediately after and join to that
		ldy	#0
@coalp:		lda	JIM+3,Y
		and	#$C0
		cmp	#$C0
		bne	@empty			; not a free block, ignore

		lda	JIM+0,Y
		cmp	zp_mos_OSBW_X
		bne	@snab
		lda	JIM+1,Y
		cmp	zp_mos_OSBW_X+1
		bne	@snab

		; this block Y is immediately above us coalesce with it 
		clc
		lda	JIM+2,Y
		adc	JIM+2,X
		sta	JIM+2,X

		lda	JIM+3,Y
		and	#$3F
		sta	JIM+3,Y			; empty that alloc table entry
		adc	JIM+3,X
		ora	#$C0			; remark as used and free
		sta	JIM+3,X

@snab:		; check to see if this block is below X
		clc
		lda	JIM+2,Y
		adc	JIM+0,Y
		eor	JIM+0,X			; use eor to set Z and preserve C
		bne	@snbel			; not just below us skip
		lda	JIM+3,Y
		and	#$3F
		adc	JIM+1,Y
		eor	JIM+1,X
		and	#$3F			; unnecessary?
		bne	@snbel

		; it is below block at X, extend at Y and mark X free
		clc
		lda	JIM+2,Y
		adc	JIM+2,X
		sta	JIM+2,Y
		lda	JIM+3,X
		and	#$3F
		sta	JIM+3,X			; mark unused
		adc	JIM+3,Y
		ora	#$C0			; remark used and free
		sta	JIM+3,Y
		tya
		tax				; Y becomes current block

@snbel:
@empty:		iny
		iny
		iny
		iny
		bne	@coalp

@bottomsup:
		; check to see if current block is at the bottom of the heap
		ldy	JIM+1,X
		lda	JIM+0,X
		tax
		jsr	jimPageWorkspace
		cpx	JIM+SCRATCH_HEAPBOT
		bne	@notbot
		cpy	JIM+SCRATCH_HEAPBOT+1
		bne	@notbot

		; it is at the bottom, get the length and add to the bottom pointer and exit
		jsr	jimPageAllocTable
		pla
		tax
		lda	JIM+3,X			; length hi
		and	#$3F
		sta	JIM+3,X			; mark entry unused
		tay
		lda	JIM+2,X
		jsr	jimPageWorkspace

		clc
		adc	JIM+SCRATCH_HEAPBOT
		sta	JIM+SCRATCH_HEAPBOT
		tya
		adc	JIM+SCRATCH_HEAPBOT+1
		sta	JIM+SCRATCH_HEAPBOT+1
		jmp	ServiceOutA0

@notbot:	pla
		jmp	ServiceOutA0


ALLOC_ERR_NOBLIT	:= 0
ALLOC_ERR_BADREQ	:= 3
ALLOC_ERR_OUTOFM	:= 1
ALLOC_ERR_SLOTS		:= 2


oswordAlloc:
		jsr	jimSetDEV_either
		bcc	@nff1
		lda	#ALLOC_ERR_NOBLIT
		jmp	@fail
@nff1:
	;	+3..4	number of pages requested
	; returns
	;	+3..4	page number allocated or $FFFF for fail


		; check for 0 length
		ldy	#4
		lda	(zp_mos_OSBW_X),Y
		dey
		ora	(zp_mos_OSBW_X),Y
		bne	@ok1
		lda	#ALLOC_ERR_BADREQ
		jmp	@fail
@ok1:		
		jsr	PushAcc					; save ZP accumulator


		; search for a free slot
		; in the allocation table
		jsr	jimPageAllocTable
		ldx	#0
@flp:		lda	JIM+3,X
		bpl	@fnd1
		inx
		inx
		inx
		inx
		bne	@flp
		lda	#ALLOC_ERR_SLOTS
		jmp	@fail3		
@fnd1:		stx	zp_trans_acc+3				; destination block for our new alloc all being well

		; search for a free block that is large enough 
		ldx	#$FF
		stx	zp_trans_acc				; this is our block number matched
		stx	zp_trans_acc+1				; size of matched block
		stx	zp_trans_acc+2				; 
		inx
@fblp:		lda	JIM+3,X					; check free
		and	#$C0
		cmp	#$C0
		bne	@fbsk

		sec		
		ldy	#3
		lda	JIM+2,X
		cmp	(zp_mos_OSBW_X),Y
		bne	@np1
		iny
		lda	JIM+3,X
		and	#$3F
		cmp	(zp_mos_OSBW_X),Y
		bne	@np1

		stx	zp_trans_acc			; perfect fit use this block		
		lda	JIM+0,X
		sta	zp_trans_acc+1
		lda	JIM+1,X
		sta	zp_trans_acc+2
		
		stx	zp_trans_acc+3
		jmp     @fnd

@np1:

		ldy	#3
		lda	JIM+2,X
		sbc	(zp_mos_OSBW_X),Y
		lda	JIM+3,X
		and	#$3F
		iny	
		sbc	(zp_mos_OSBW_X),Y
		bcc	@fbsk

		; now check if there's already a match if the matched is smaller
		ldy	zp_trans_acc
		bmi	@ok
		
		sec
		lda	JIM+2,X
		sbc	zp_trans_acc+1
		lda	JIM+3,X
		and	#$3F
		sbc	zp_trans_acc+2
		bcs	@fbsk
@ok:		stx	zp_trans_acc+0
		lda	JIM+2,X
		stx	zp_trans_acc+1
		lda	JIM+3,X
		and	#$3F
		stx	zp_trans_acc+2


@fbsk:		inx
		inx
		inx
		inx
		bne	@fblp

		ldx	zp_trans_acc				; get back found slot
		bmi	@extend

		; we now need to grab space from this slot
		; move start on by requested length
		ldy	#3
		clc
		lda	JIM+0,X
		sta	zp_trans_acc+1				; this will be our alloc'd base
		adc	(zp_mos_OSBW_X),Y
		sta	JIM+0,X
		lda	JIM+1,X
		sta	zp_trans_acc+2				; this will be our alloc'd base
		iny
		adc	(zp_mos_OSBW_X),Y
		sta	JIM+1,X

		;reduce length of free block by req'd length
		sec
		dey						; 3
		lda	JIM+2,X
		sbc	(zp_mos_OSBW_X),Y
		sta	JIM+2,X
		lda	JIM+3,X
		and	#$3F
		iny
		sbc	(zp_mos_OSBW_X),Y
		ora	#$C0
		sta	JIM+3,X
		bne	@fnd


@extend:

		jsr	jimPageWorkspace
		ldy	#3
		; decrease BOT and see if we still fit
		sec
		lda	JIM+SCRATCH_HEAPBOT
		sbc	(zp_mos_OSBW_X),Y
		sta	zp_trans_acc+1				; new heapbot / our base if success
		iny
		lda	JIM+SCRATCH_HEAPBOT+1
		sbc	(zp_mos_OSBW_X),Y
		sta	zp_trans_acc+2				; new heapbot / our base if success
		bmi	@fail3
		cmp	JIM+SCRATCH_HEAPLIM+1
		bcc	@fail3
		lda	zp_trans_acc+1
		cmp	JIM+SCRATCH_HEAPLIM
		lda	#ALLOC_ERR_OUTOFM
		bcc	@fail3

		lda	zp_trans_acc+2
		sta	JIM+SCRATCH_HEAPBOT+1
		lda	zp_trans_acc+1
		sta	JIM+SCRATCH_HEAPBOT			; move bottom



		; >= limit store as new bottom and return
		; stack the result and then try and find a slot



@fnd:		
		jsr	jimPageAllocTable 

		ldx	zp_trans_acc+3

		; store length in alloc table
		ldy	#4
		lda	(zp_mos_OSBW_X),Y
		ora	#$80			; mark "in use"
		sta	JIM+3,X
		dey
		lda	(zp_mos_OSBW_X),Y
		sta	JIM+2,X

@fnd2:

		ldy	#3
		lda	zp_trans_acc+1
		sta	(zp_mos_OSBW_X),Y
		sta	JIM+0,X

		iny
		lda	zp_trans_acc+2
		sta	(zp_mos_OSBW_X),Y
		sta	JIM+1,X
		jsr	PopAcc
		jmp	ServiceOutA0

@fail3:		jsr	PopAcc
@fail:		ldy	#3
		sta	(zp_mos_OSBW_X),Y
		lda	#$FF
		iny
		sta	(zp_mos_OSBW_X),Y
		jmp	ServiceOutA0

_getcurset:	pha
		jsr	cfgGetRomMap
		bcs	@bad				; return 0 is no onboard roms
		ror	A				; Cy set if ==1
		pla
		and	#OSWORD_BLTUTIL_FLAG_ALTERNATE
		beq	@cont00
		; alternate flag is active, toggle carry
		jsr	@toglcy				
@cont00:		jmp	_cont0

@bad:		pla
		clc	
		bcc	_cont0

@toglcy:	rol	a
		eor	#1
		ror	a
		rts


oswordGetRomBase:
	;	+2	rom #
	;	+3	roms flags
	;		(see SRLOAD)
	; returns
	;	+2	flags
	;	+3..4	page number

		ldy	#0
		sty	zp_mos_OSBW_A			; clear ret
		ldy	#3				; point at flags
		jsr	cfgGetRomMap			; check for mem inhibit TODO: mege with getcurset below?
		bvc	@notmemi
		lda	#OSWORD_BLTUTIL_RET_MEMI
		sta	zp_mos_OSBW_A			; set memi in return flags		
		lda	(zp_mos_OSBW_X),Y
		and	#OSWORD_BLTUTIL_FLAG_IGNOREMEMI	; get flags
		beq	@sys
@notmemi:	;work out which map
		lda	(zp_mos_OSBW_X),Y		; get flags
		bmi	_getcurset
		ror	A				; map1 into Cy
@map1:
		; at this point CS = map1, CC = map 0
		php					; save flags
		bcc	@notmap1
		lda	#1
		ora	zp_mos_OSBW_A
		sta	zp_mos_OSBW_A
@notmap1:	lda	#0
		pha
		tsx
		dey
		lda	(zp_mos_OSBW_X),Y		; get rom #
	.ifdef MACH_ELK
		eor	#$0C				; bodge address bases
	.else
		bcs	@nohole				; hole in Elk for both maps
	.endif

		; check for C20K - no hole in either map
		; x still contains board level - compare for C20k
		cpx	#BOARD_LEVEL_C20K
		bcs	@nohole

		cmp	#4
		bcc	@nohole
		cmp	#8
		bcc	@sys2
		; calculate offset of rom in area
@nohole:	pha
		ror	a
		ror	a
		and	#OSWORD_BLTUTIL_RET_FLASH	;$80
		ora	zp_mos_OSBW_A
		sta	zp_mos_OSBW_A			; set Flash flag
		pla
		and	#$0E
		lsr	a
		ror	$101,X
		lsr	a
		ror	$101,X
		lsr	a
		ror	$101,X
		adc	#$7E		
		iny
		iny
		sta	(zp_mos_OSBW_X),Y
		dey
		pla
		sta	(zp_mos_OSBW_X),Y
		; check if rom/ram
		dey
		lda	(zp_mos_OSBW_X),Y
		ror	A				; odd / even in CY
		iny
		iny
		lda	(zp_mos_OSBW_X),Y		
		bcc	@ram
		; add $20 to rom/ram address high
		adc	#$20-1				; Cy is set above
@ram:		plp					; if cy set subtract 2 from hi (php at @map1)
		bcc	@map0_2
		sbc	#2
@map0_2:	sta	(zp_mos_OSBW_X),Y
		lda	zp_mos_OSBW_A
		jmp	@retA



@sys2:		pla
		plp
@sys:		; either memi or SYS
		ldy	#4
		lda	#$FF
		sta	(zp_mos_OSBW_X),Y
		dey
		lda	#$80
		sta	(zp_mos_OSBW_X),Y
		lda	#OSWORD_BLTUTIL_RET_SYS
		ora	zp_mos_OSBW_A
	
@retA:		sta	zp_mos_OSBW_A

		jsr	cfgGetRomMap
		bcs	@forceCur
		eor	zp_mos_OSBW_A
		eor	#1				; eor MAP1 with cur map and flip
		asl	A				; into bit 2
		jmp	@setFl2
@forceCur:	lda	#OSWORD_BLTUTIL_RET_ISCUR	; set "current" 
@setFl2:	ora	zp_mos_OSBW_A

		ldy	#2
		sta	(zp_mos_OSBW_X),Y
		lda	#OSWORD_BLTUTIL
		sta	zp_mos_OSBW_A			; restore zp_mos_OSBW_A
		jmp	ServiceOutA0			; ServiceOutA0 

_cont0 = @map1



cmdHeapInfo:	jsr	CheckEitherPresentBrk
		jsr	jimPageWorkspace		; page in scratch space bottom

@bp:		lda	#0
		sta	JIM+SCRATCH_TMP+0

		jsr	SkipSpacesPTR
		jsr	ToUpper
		cmp	#'V'				; verbose flag
		bne	@s1
		dec	JIM+SCRATCH_TMP+0
@s1:
		HEAD16  "Heap Top"

		ldx	JIM+SCRATCH_HEAPTOP
		ldy	JIM+SCRATCH_HEAPTOP+1
		jsr	PrintHexAmpXY
		lda	#0
		jsr	PrintHexA

		HEAD16  "Heap Bottom"

		ldx	JIM+SCRATCH_HEAPBOT
		ldy	JIM+SCRATCH_HEAPBOT+1
		jsr	PrintHexAmpXY
		lda	#0
		jsr	PrintHexA

		HEAD16  "Heap Low"

		ldx	JIM+SCRATCH_HEAPLIM
		ldy	JIM+SCRATCH_HEAPLIM+1
		jsr	PrintHexAmpXY
		lda	#0
		jsr	PrintHexA

		HEAD16	"Total free"

		; print free space in bytes	 
		sec
		lda	JIM+SCRATCH_HEAPBOT
		sbc	JIM+SCRATCH_HEAPLIM
		sta	zp_trans_acc+1
		lda	JIM+SCRATCH_HEAPBOT+1
		sbc	JIM+SCRATCH_HEAPLIM+1
		sta	zp_trans_acc+2
		lda	#0
		sta	zp_trans_acc+0
		sta	zp_trans_acc+3

		; go through alloc table and include any blocks in there

		jsr	jimPageAllocTable
		ldx	#0
@lf:		lda	JIM+3,X
		and	#$C0
		cmp	#$C0
		bne	@sklf
		clc
		lda	JIM+2,x
		adc	zp_trans_acc+1
		sta	zp_trans_acc+1
		lda	JIM+3,X
		and	#$3F
		adc	zp_trans_acc+2
		sta	zp_trans_acc+2		; assume <16M

@sklf:		inx
		inx
		inx
		inx
		bne	@lf

		jsr	jimPageWorkspace

		jsr	PrintBytesAndK

		HEAD16	"Largest free"


		; find largest allocation block free
		; first try below heap

		sec
		lda	JIM+SCRATCH_HEAPBOT
		sbc	JIM+SCRATCH_HEAPLIM
		sta	zp_trans_acc+1
		lda	JIM+SCRATCH_HEAPBOT+1
		sbc	JIM+SCRATCH_HEAPLIM+1
		sta	zp_trans_acc+2

		; scan alloc table for any larger ones
		jsr	jimPageAllocTable
		ldx	#0

@llp:		lda	JIM+2,X
		and	#$C0
		cmp	#$C0
		bne	@lsk
		lda	JIM+2,X
		sbc	zp_trans_acc+1
		lda	JIM+3,X
		and	#$3F
		sbc	zp_trans_acc+2
		bcc	@lsk
		; this one is use it
		lda	JIM+2,X
		sta	zp_trans_acc+1
		lda	JIM+3,X
		and	#$3F
		sta	zp_trans_acc+2

@lsk:		inx
		inx
		inx
		inx
		bne	@llp

		jsr	jimPageWorkspace

		jsr	PrintBytesAndK
		jsr	PrintNL

		lda	JIM+SCRATCH_TMP+0
		bpl	@exit				; not verbose

		; display allocation table entries
		ldx	#0
		jsr	jimPageAllocTable
@allop:		lda	JIM+3,X
		bpl	@allsk

		pha
		txa
		jsr	PrintHexA
		jsr	PrintSpc
		pla

		and	#$40				; check if "free"
		php
		lda	JIM+1,X				; base address
		jsr	PrintHexA
		lda	JIM+0,X
		jsr	PrintHexA

		jsr	PrintSpc
		lda	JIM+3,X
		and	#$3F				; mask flags
		jsr	PrintHexA
		lda	JIM+2,X
		jsr	PrintHexA

		plp
		beq	@nf
		txa
		pha
		jsr	PrintImmedT
		TOPTERM  " (free)"
		pla
		tax

@nf:		jsr	OSNEWL
@allsk:		inx
		inx
		inx
		inx
		bne	@allop

@exit:		rts


