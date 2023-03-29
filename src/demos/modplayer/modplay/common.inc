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

		.MACRO PRINT MSG
		.SCOPE

		.LOCAL MSGSTR
		.PUSHSEG
		.RODATA
MSGSTR:		.BYTE MSG, 0
		.POPSEG
		pha
		txa
		pha
		ldx	#0
@p_s:		lda	MSGSTR,X
		beq	@p_s2
		jsr	OSASCI
		inx
		bne	@p_s
@p_s2:		pla
		tax
		pla

		.ENDSCOPE
		.ENDMACRO

		.MACRO PRINTL MSG
		.SCOPE

		.LOCAL MSGSTR
		.PUSHSEG
		.RODATA
MSGSTR:		.BYTE MSG, 0
		.POPSEG
		pha
		txa
		pha
		ldx	#0
@s:		lda	MSGSTR,X
		beq	@s2
		jsr	OSASCI
		inx
		bne	@s
@s2:		jsr	OSNEWL
		pla
		tax		
		pla
		.ENDSCOPE
		.ENDMACRO