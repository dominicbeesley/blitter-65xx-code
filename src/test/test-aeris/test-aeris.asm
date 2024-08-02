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



	; enable jim
	lda	#JIM_DEVNO_BLITTER
	sta	fred_JIM_DEVNO
	lda	fred_JIM_DEVNO	

	jsr	jimDMACPAGE


	;aeris setup at $00 1000

	lda	#0
	sta	jim_CS_DMA_SEL
	lda	#$FF
	sta	jim_CS_DMA_SRC_ADDR+2
	lda	#.HIBYTE(aeris_test_pgm)
	sta	jim_CS_DMA_SRC_ADDR+1
	lda	#.LOBYTE(aeris_test_pgm)
	sta	jim_CS_DMA_SRC_ADDR+0
	lda	#$00
	sta	jim_CS_DMA_DEST_ADDR+2
	lda	#$10
	sta	jim_CS_DMA_DEST_ADDR+1
	lda	#$00
	sta	jim_CS_DMA_DEST_ADDR+0
	lda	#.HIBYTE(aeris_test_pgm_end-aeris_test_pgm-1)
	sta	jim_CS_DMA_COUNT+1
	lda	#.LOBYTE(aeris_test_pgm_end-aeris_test_pgm-1)
	sta	jim_CS_DMA_COUNT+0

	lda	#DMACTL_ACT + DMACTL_HALT + DMACTL_STEP_DEST_UP + DMACTL_STEP_SRC_UP
	sta	jim_CS_DMA_CTL


	lda	#$00
	sta	jim_CS_AERIS_PROGBASE+2
	lda	#$10
	sta	jim_CS_AERIS_PROGBASE+1
	lda	#$00
	sta	jim_CS_AERIS_PROGBASE+0

	lda	#$80
	sta	jim_CS_AERIS_CTL
	rts


jimDMACPAGE:
	pha
	lda	#<jim_page_CHIPSET
	sta	fred_JIM_PAGE_LO
	lda	#>jim_page_CHIPSET
	sta	fred_JIM_PAGE_HI
	pla
	rts


aeris_test_pgm:
		AE_MOVE16	$2, $23, $0000			; black background

		AE_DSZ		7				; decrement ctr 7
		AE_BRA		aeris_sk1			; 
		AE_MOVEC	7, 2				; reset to 2 if 0

		AE_DSZ		0				; dec ctr 0
		AE_BRA		aeris_sk1		
		AE_MOVEC	0, 30				; reset to 30 if 0
aeris_sk1:
		AE_MOVEP	0, aeris_rainbow		; P0 points at rainbow

		AE_WAIT		$1FF, $00, 70, 0		; wait for line #70


aeris_lp1:	
		AE_MOVEPP	1, 0				; P1 = P0 (prog start)

		AE_MOVEC	2, 9				; C2 = 	9
aeris_lp2:	
		AE_MOVECC	1, 0				; C1 = 	C0
		AE_ADDC		1, 4				; C1 += 4
		AE_PLAY16	1, 1				; do one line of rainbow

aeris_lp3:	AE_UNSYNC
		AE_WAITH					; wait for HS
		AE_SYNC
		AE_DSZ		1				; dec C1
		AE_BRA		aeris_lp3			; if C1 > 0 goto lp3

		AE_DSZ		2				; 
		AE_BRA		aeris_lp2

		AE_SKIP		$1FF, $00, 200, 0
		AE_BRA		aeris_lp1
		AE_UNSYNC

		AE_WAIT		$1FF, $00, $1FF, 0

		

aeris_rainbow:			
		AE_MOVE16	$2, $23, $0000		; black
		AE_MOVE16	$2, $23, $0600		; red
		AE_MOVE16	$2, $23, $0640		; orange
		AE_MOVE16	$2, $23, $0660		; yellow
		AE_MOVE16	$2, $23, $0060		; green
		AE_MOVE16	$2, $23, $0006		; blue
		AE_MOVE16	$2, $23, $0203		; indigo
		AE_MOVE16	$2, $23, $0636		; violet
		AE_MOVE16	$2, $23, $0000		; black

aeris_test_pgm_end:



		.END