; 
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

	.include "hardware.inc"
	.include "adv_globals.inc"

	.export _draw_map
	.importzp sreg, sp
	.import _XY_to_dma_scr_adr, pushax, incsp2

	.zeropage
zp_ptr_t:		.res 2
zp_tile_ptr:		.res 2
zp_tile_ptmp:		.res 1

	.data
ctr_x:		.res 1
ctr_y:		.res 1
screen_dma_addr:.res 3
	.code

_draw_map:
;;void draw_map(void *addr);
	stx	zp_ptr_t+1
	sta	zp_ptr_t

	SET_DMA_WORD	jim_DMAC_STRIDE_B, TILE_B_STRIDE
	SET_DMA_WORD	jim_DMAC_STRIDE_D, SCREEN_D_STRIDE
	SET_DMA_BYTE	jim_DMAC_HEIGHT,TILE_Y_SZ-1
	SET_DMA_BYTE	jim_DMAC_WIDTH,TILE_B_STRIDE-1
	SET_DMA_BYTE	jim_DMAC_FUNCGEN, $CC
	SET_DMA_BYTE	jim_DMAC_BLITCON, BLITCON_EXEC_B + BLITCON_EXEC_D


	ldx	#0
	txa
	jsr	pushax
	ldx	#0
	txa
	jsr	_XY_to_dma_scr_adr
	sta	screen_dma_addr
	stx	screen_dma_addr+1
	lda	sreg
	sta	screen_dma_addr+2

	lda	#ROOM_SZ_Y
	sta	ctr_y
lp_y:	lda	#ROOM_SZ_X
	sta	ctr_x
lp_x:
	; get tile from zp_ptr_t and advance
	ldy	#0
	lda	(zp_ptr_t),y
	inc	zp_ptr_t
	bne	s1
	inc	zp_ptr_t+1
s1:	
	cmp	#0
	beq	s2

	; calculate address of tile bitmap
	; assumes back tile start on a 64k boundary and are <64k
	clc
	sbc	#0					 ; DECA
	ldx	#0
	clc
	stx	jim_DMAC_ADDR_B+2
	ror	A
	sta	jim_DMAC_ADDR_B+1
	ror	jim_DMAC_ADDR_B+2			; tile_ptr = A * 80
	ror	A
	pha						; 
	lda	jim_DMAC_ADDR_B+2
	ror	A
	adc	jim_DMAC_ADDR_B+2
	sta	jim_DMAC_ADDR_B+2
	pla
	adc	jim_DMAC_ADDR_B+1

	sta	jim_DMAC_ADDR_B+1
	lda	#.LOBYTE(.HIWORD(DMA_BACK_SPR))		; ASSUME: bank not crossed
	sta	jim_DMAC_ADDR_B

	lda	screen_dma_addr
	sta	jim_DMAC_ADDR_D+2
	lda	screen_dma_addr+1
	sta	jim_DMAC_ADDR_D+1
	lda	screen_dma_addr+2
	sta	jim_DMAC_ADDR_D+0

	SET_DMA_BYTE	jim_DMAC_BLITCON, BLITCON_ACT_ACT + BLITCON_ACT_CELL + BLITCON_ACT_MODE_4BBP

s2:
	clc
	lda	screen_dma_addr
	adc	#64
	sta	screen_dma_addr
	bcc	s4
	inc	screen_dma_addr+1
s4:

	dec	ctr_x
	bne	lp_x

	clc
	lda	screen_dma_addr
	adc	#<1280
	sta	screen_dma_addr
	lda	screen_dma_addr+1
	adc	#>1280
	sta	screen_dma_addr+1

	clc
	lda	zp_ptr_t
	adc	#<(TILE_MAP_STRIDE-ROOM_SZ_X)
	sta	zp_ptr_t
	lda	zp_ptr_t+1
	adc	#>(TILE_MAP_STRIDE-ROOM_SZ_X)
	sta	zp_ptr_t+1

	dec	ctr_y
	beq	no_lp_y
	jmp	lp_y
no_lp_y:


;	screen_addr = XY_to_dma_scr_adr(ROOM_OFF_x, ROOM_OFF_y);
;	for (rows=ROOM_SZ_Y; rows > 0; rows--) 
;	{
;		for (cols=ROOM_SZ_X; cols > 0; cols--)
;		{
;			tileno=(*zp_ptr_t++);
;			if (tileno) {
;				tile_addr = DMA_BACK_SPR + TILE_BYTES * (tileno-1);
;				SET_DMA_ADDR(jim_DMAC_ADDR_D, screen_addr);
;				SET_DMA_ADDR(jim_DMAC_ADDR_B, tile_addr);
;				SET_DMA_BYTE(jim_DMAC_BLITCON, BLITCON_ACT_ACT + BLITCON_ACT_CELL + BLITCON_ACT_MODE_4BBP);
;			}
;
;			screen_addr += 64;
;		}
;		zp_ptr_t+=TILE_MAP_STRIDE-ROOM_SZ_X; //TILES STRIDE-SCREENTILES
;		screen_addr += 640;
;	}

	rts

	.end
