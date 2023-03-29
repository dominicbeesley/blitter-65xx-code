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

MODULE_BASE	:= $3C00
MODULE_SONG	:= MODULE_BASE + $80
MODULE_PATTERNS	:= MODULE_BASE + $100
LOAD_BLOCK_SIZE := $4000
MAX_SAMPLE_DEFS := 32
SONG_DATA_LEN	:= 128
PATTERN_LEN	:= 1024
MODULE_CPAGE	:= $0100				; page in chipram to store mod


HDR_SONG_SAMPLES	:= 20
HDR_SONG_LEN_OFFS	:= 950
HDR_SONG_DATA_OFFS	:= 952
HDR_PATT_DATA_OFFS	:= 1084


FLAGS_key_pause	:= $40					; when set key_pause playing
FLAGS_EXEC	:= $20					; set by event driven player to indicate it has run


		.STRUCT s_cha_vars
			cha_var_sn		.byte		; 1	current sample #*8 (can be used as offs into sample info table)
			cha_var_per		.word		; 2	- note big endian
			cha_var_porta_per	.word		; 2
			cha_var_porta_speed	.byte		; 1
			cha_var_vol		.byte		; 1	current volume
			cha_var_cmd		.byte		; 1
			cha_var_parm		.byte		; 1
			cha_var_s_len		.word		; 2	; note order of these important as copied from sample info table
			cha_var_s_roff		.word		; 2
			cha_var_s_addr_b	.byte		; 1
			cha_var_s_addr		.word		; 2
			cha_var_s_repfl		.byte		; 1	>$80 for repeat (low 6 bits are sample vol)
			cha_var_flags		.byte		; 1	$80 mute, $40
			cha_var_restart		.byte		; 1	
			cha_var_vib_pos		.byte
			cha_var_vib_cmd		.byte
			cha_var_ppm		.byte		; peak with decay
			cha_var_peak		.byte		; peak returned from hardware - peak is assumed to be last!
		.ENDSTRUCT

MOD_TITLE_LEN	:= 20

		.STRUCT s_mod_data
			mod_title		.RES 20
		.ENDSTRUCT

		; the compacted table stored in system memory
		.STRUCT s_saminfo
			len		.word		; 2	; note order of these important as copied from sample info table
			roff		.word		; 2
			addr_b		.byte		; 1	; low 4 bits are bank # top 4 bits are finetune
			addr		.word		; 2
			repfl		.byte		; 1	>$80 for repeat (low 6 bits are sample vol)
		.ENDSTRUCT

		; original sample layout in chip mem / mod file
		.STRUCT s_modsaminfo
			name			.res	22
			len			.word
			fine			.byte
			vol			.byte
			repoffs			.word
			replen			.word
		.ENDSTRUCT