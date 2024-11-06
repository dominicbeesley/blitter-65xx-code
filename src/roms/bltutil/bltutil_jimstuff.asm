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

		.include "oslib.inc"
		.include "mosrom.inc"

		.include "bltutil.inc"

		.export	CheckBlitterPresent
		.export	CheckPaulaPresent
		.export	CheckBlitterPresentBrk
		.export	CheckEitherPresentBrk
		.export	brkBlitterNotPresent
		.export	jimSetDEV_blitter
		.export	jimSetDEV_paula
		.export jimSetDEV_either
		.export jimSetDEV_A
		.export brkBlitterNotPresent
		.export jimClaimDev
		.export jimReleaseDev
		.export jimPageWorkspace
		.export jimPageChipset
		.export jimPageVersion
		.export	jimSetDEV_either_stack_old
		.export jimUnStackDev
		.export jimPageSamTbl
		.export jimPageSoundWorkspace
		.export jimCheckEitherSelected
		.export jimReleaseDev_err

		.CODE
CheckBlitterPresent := jimSetDEV_blitter
CheckPaulaPresent := jimSetDEV_paula

CheckBlitterPresentBrk:
		jsr	CheckBlitterPresent
		bcs	brkBlitterNotPresent
		rts
brkBlitterNotPresent:
		M_ERROR
		.byte	$FF, "Blitter not present",0

brkEitherNotPresent:
		M_ERROR
		.byte	$FF, "Blitter/Paula not present",0

CheckEitherPresentBrk:
		jsr	jimSetDEV_either
		bcs	brkEitherNotPresent
		rts

; set jim device no and paging registers to scratch space at 00 FD00-FDFF
; returns CS if not present
;jimSetSCR:	pha
;		jsr	jimSetDEV
;		bcs	@s
;		lda	#<JIM_SCRATCH
;		sta	fred_JIM_PAGE_LO
;		lda	#>JIM_SCRATCH
;		sta	fred_JIM_PAGE_HI
;@s:		pla
;		rts

; set jim device no, return CS if not present
jimSetDEV_paula:
		pha		
		lda	#JIM_DEVNO_HOG1MPAULA
		bne	jimSetDEV_A2
jimSetDEV_blitter:
		pha		
		lda	#JIM_DEVNO_BLITTER
		bne	jimSetDEV_A2
jimSetDEV_A:	pha
jimSetDEV_A2:	sta	zp_mos_jimdevsave		; set to our device
		sta	fred_JIM_DEVNO
		eor	fred_JIM_DEVNO
		clc
		eor	#$FF				; return CS if not our device present
		beq	@s1
		sec
@s1:		pla
		rts

jimSetDEV_either:
		jsr	jimSetDEV_blitter
		bcc	@ok
		jmp	jimSetDEV_paula
@ok:		rts


; This will return with the stack containing the following:
		; 	SP+3		previously selected device
		;	SP+2		old JIM paging register LO
		;	SP+1		old JIM paging register LO

		; all register _and flags_ are preserved
jimSetDEV_either_stack_old:
		pha
		pha
		pha
		php
		pha
		txa
		pha

		; stack contents

		;	SP+8		retH
		;	SP+7		retL
		;	SP+6		spare
		;	SP+5		spare
		;	SP+4		spare
		;	SP+3		saved P
		;	SP+2		saved A
		;	SP+1		saved X
		tsx
		lda	$107,X
		sta	$104,X
		lda	$108,X
		sta	$105,X

		;	SP+8		spare
		;	SP+7		spare
		;	SP+6		spare
		;	SP+5		retH
		;	SP+4		retL
		;	SP+3		saved P
		;	SP+2		saved A
		;	SP+1		saved X

		lda	zp_mos_jimdevsave
		sta	$108,X
		jsr	jimSetDEV_either
		lda	fred_JIM_PAGE_HI
		sta	$107,X
		lda	fred_JIM_PAGE_LO
		sta	$106,X

		;	SP+8		OLD DEV NO
		;	SP+7		JIM_PAGE_HI
		;	SP+6		JIM_PAGE_LO
		;	SP+5		retH
		;	SP+4		retL
		;	SP+3		saved P
		;	SP+2		saved A
		;	SP+1		saved X

		pla
		tax
		pla
		plp
		rts



; this will restore the stack and device
jimUnStackDev:
		php
		pha
		txa
		pha

		; stack now contains

		;	SP+8		OLD DEV NO
		;	SP+7		JIM_PAGE_HI
		;	SP+6		JIM_PAGE_LO
		;	SP+5		retH
		;	SP+4		retL
		;	SP+3		saved P
		;	SP+2		saved A
		;	SP+1		saved X

		jsr	jimSetDEV_either		; TODO - do we need this in all cases?

		tsx
		lda	$106,X
		sta	fred_JIM_PAGE_LO
		lda	$107,X
		sta	fred_JIM_PAGE_HI
		lda	$108,X
		sta	zp_mos_jimdevsave
		sta	fred_JIM_DEVNO

		; fix up stack 

		lda	$105,X
		sta	$108,X
		lda	$104,X
		sta	$107,X
		lda	$103,X
		sta	$106,X
		lda	$102,X
		sta	$105,X

		;	SP+8		retH
		;	SP+7		retL
		;	SP+6		saved P
		;	SP+5		saved A
		;	SP+4		-
		;	SP+3		-
		;	SP+2		-
		;	SP+1		saved X


		pla
		tax
		pla
		pla
		pla
		pla
		plp
		rts

	

;------------------------------------------------------------------------------
; NEW JIM API routines
;------------------------------------------------------------------------------
	; on all entry points the current device number held at 
	; zp_mos_jimdevsave &EE needs to be saved and our device number set
	; in zp_mos_jimdevsave and fred_jim_DEVNO to enable the JIM memory
	; interface used for ramdiscs and scratch space

	; This routine will install a phoney return address on the stack it should
	; be called at service call / event handler entry point and will rearrange
	; the stack such that an RTS from the caller routine will call jimReleaseDev
	; before returning to the service routine caller

	; NEW: June 2022: Now stores the stack pointer at 1FF and saves previous 1FF
	; contents on the stack, this allows us to put the device back as it should
	; be no matter what state the stack has got to - used in the M_ERROR macro
	; to restore the device
jimClaimDev:
		php					; make room on stack for phoney return to jimReleaseDev 
		php					; and saved devno and jim paging registers
		php
		php
		php
		php
		php					; save flags
		pha					; save A and flags
		txa
		pha					; save X

		; stack is now
		; SP + B	caller hi
		; SP + A	caller lo		; old paging registers here
		; SP + 9	spare			; old 1FF here
		; SP + 8	spare			; devno here
		; SP + 6,7	spare			; move jimRelease Dev-1 here
		; SP + 4,5	spare			; move return address here
		; SP + 3	caller flags save
		; SP + 2	caller A save
		; SP + 1	caller X save
		; SP + 0	ToS


		tsx		
		lda	$10A,X				; get caller lo
		sta	$104,X				; move down to new location
		lda	$10B,X				; get caller hi
		sta	$105,X				; move down to new location
		lda	#<(jimReleaseDev-1)
		sta	$106,X				; add jimReleaseDev into stack
		lda	#>(jimReleaseDev-1)
		sta	$107,X				; add jimReleaseDev into stack

		lda	zp_mos_jimdevsave		; get current callers device #
		sta	$108,X

		jsr	jimSetDEV_either		; page in Blitter/Paula
		lda	fred_JIM_PAGE_LO
		sta	$10A,X
		lda	fred_JIM_PAGE_HI
		sta	$10B,X
		lda	$1FF				; preserve old $1FF
		sta	$109,X
		stx	$1FF				; $1FF now contains this stack frame pointer

		; stack is now

		; PS + B	jim hi
		; SP + A	jim lo
		; SP + 9	olf 1FF contents
		; SP + 8	Saved devno
		; SP + 6,7	Release
		; SP + 4,5	caller
		; SP + 3	caller flags save
		; SP + 2	caller A save
		; SP + 1	caller X save
		; SP + 0	ToS

		pla
		tax
		pla
		plp
		rts

		; this version of release dev doesn't return to the original caller
		; instead it restores the device from the stack (and repairs 1FF)
		; but leaves everything on the stack and returns
jimReleaseDev_err:
		pha
		txa
		pha

		ldx	$1FF		; get back original stack pointer
		lda	$109,X
		sta	$1FF		; repair stack contents 

		jsr	jimSetDEV_either
		lda	$10A,X
		sta	fred_JIM_PAGE_LO
		lda	$10B,X
		sta	fred_JIM_PAGE_HI

		lda	$108,X
		sta	zp_mos_jimdevsave		; set to saved caller's dev no
		sta	fred_JIM_DEVNO

		pla
		tax
		pla
		rts


jimReleaseDev:
		php
		pha
		txa
		pha

		; SP + 9	return hi
		; SP + 8	return lo
		; SP + 7	jim hi
		; SP + 6	jim lo
		; SP + 5	old 1FF contents
		; SP + 4	saved devno
		; SP + 3	saved flags
		; SP + 2	saved A
		; SP + 1	saved X
		; SP + 0	TOS

		tsx

		lda	$105,X
		sta	$1FF				; restore bottom of stack

		jsr	jimSetDEV_either
		lda	$106,X
		sta	fred_JIM_PAGE_LO
		lda	$107,X
		sta	fred_JIM_PAGE_HI

		lda	$104,X
		sta	zp_mos_jimdevsave		; set to saved caller's dev no
		sta	fred_JIM_DEVNO

		lda	$103,X
		sta	$107,X				; overwrite jim hi with saved flags

		; SP + 8,9	return
		; SP + 7	saved flags
		; SP + 6	jim lo
		; SP + 5	old 1FF
		; SP + 4	devno
		; SP + 3	saved flags
		; SP + 2	saved A
		; SP + 1	saved X
		; SP + 0	TOS

		; have to move the saved pla to the last pla position
		lda	$102,X
		sta	$106,X

		; SP + 8,9	return
		; SP + 7	saved flags
		; SP + 6	saved A
		; SP + 5	old 1FF
		; SP + 4	devno
		; SP + 3	saved flags
		; SP + 2	saved A
		; SP + 1	saved X
		; SP + 0	TOS


		pla
		tax
		pla
		pla					
		pla
		pla
		pla
		plp
		rts

; check if Paula or Blitter selected and return CS=1 if not
; preserves all registers except flags
jimCheckEitherSelected:
		pha
		lda	zp_mos_jimdevsave
		cmp	#JIM_DEVNO_BLITTER
		beq	@ok
		cmp	#JIM_DEVNO_HOG1MPAULA
		beq	@ok
		sec
		pla
		rts
@ok:		clc
		pla
		rts


jimPageWorkspace:
		pha
		lda	#<PAGE_ROMSCRATCH
		sta	fred_JIM_PAGE_LO
		lda	#>PAGE_ROMSCRATCH
		sta	fred_JIM_PAGE_HI
		pla
		rts

jimPageChipset:
		pha
		lda	#<jim_page_CHIPSET
		sta	fred_JIM_PAGE_LO
		lda	#>jim_page_CHIPSET
		sta	fred_JIM_PAGE_HI
		pla
		rts

jimPageSamTbl:	pha
		lda	#<PAGE_SAMPLETBL
		sta	fred_JIM_PAGE_LO
		lda	#>PAGE_SAMPLETBL
		sta	fred_JIM_PAGE_HI
		pla
		rts

jimPageSoundWorkspace:
		pha
		lda	#<PAGE_SOUNDWKSP
		sta	fred_JIM_PAGE_LO
		lda	#>PAGE_SOUNDWKSP
		sta	fred_JIM_PAGE_HI
		pla
		rts

jimPageVersion:
		pha
		lda	#<jim_page_VERSION
		sta	fred_JIM_PAGE_LO
		lda	#>jim_page_VERSION
		sta	fred_JIM_PAGE_HI
		pla
		rts
