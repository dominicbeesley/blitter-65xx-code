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


			.import _tilemap


DMA_BACK_SPR		:=	$010000
DMA_FRONT_SPR		:=	$020000
FRONT_SPR_MO		:=	(8*16)				; mask offset from start of spr
FRONT_SPR_SZ		:=	(2*16)+(8*16)			; size of spr

DMA_SPR_SAVE		:=	$030000				; save area for sprites

DMA_SCR_SHADOW		:=	$040000				; draw to this screen then blit to SYS

TILE_X_SZ		:=	16
TILE_Y_SZ		:=	24
TILE_B_STRIDE		:=	8
SCREEN_SZ_X		:=	160
SCREEN_SZ_Y		:=	256
SCREEN_D_STRIDE		:=	640
TILE_MAP_STRIDE		:=	30
TILE_MAP_HEIGHT		:=	30
TILE_BYTES		:=	8*24				;bytes per tile sprite (no mask)

ROOM_SZ_Y		:=	10
ROOM_SZ_X		:=	10

; 	; sprite save area block offsets
; o_spr_save_sava	equ	0
; o_spr_save_scra	equ	3
; o_spr_save_w	equ	5
; o_spr_save_h	equ	6
; o_spr_save_l	equ	7

TILE_MAP_LAYER_SZ	:=	(TILE_MAP_STRIDE*TILE_MAP_HEIGHT)
TILE_MAP_SZ		:=	(2*TILE_MAP_LAYER_SZ)
A_TILE_MAP		:=	_tilemap

.MACRO		SET_DMA_WORD	addr, val
		lda	#>val
		sta	addr
		lda	#<val
		sta	addr+1
.ENDMACRO

.MACRO		SET_DMA_ADDR	addr,val
		lda	#val / 0x10000
		sta	addr
		lda	#>(val & 0xFFFF)
		sta	addr+1
		lda	#<(val & 0xFFFF)
		sta	addr+2
.ENDMACRO


.MACRO		SET_DMA_BYTE	addr,val
		lda	#val
		sta	addr
.ENDMACRO

