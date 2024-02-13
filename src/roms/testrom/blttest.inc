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

NOICE_BRK_INST	:= 	$5C				; special BRK instruction for noice

ADDR_ERRBUF	:=	$100				; base of stack!

.macro		VERSION_NAME
		.byte	"BLTTEST"
.endmacro

		;TODO : move these to autogen'd files? Agree version # with JGH
.macro		VERSION_BYTE
		.byte	1
.endmacro

.macro		VERSION_STRING
		.byte	"0.01"
.endmacro

.macro		M_ERROR
		jsr	BounceErrorOffStack
.endmacro

.macro		TODO	error
		M_ERROR
		.byte	$FF
		.byte	error
		.byte	0
.endmacro

.macro		CLAIMDEV
		jsr	jimClaimDev
.endmacro

.macro		SJTE	serv, addr
		.byte	serv
		.byte	>(addr - 1)			; bytes here in order ready to be stacked then rts'd to
		.byte 	<(addr - 1)
.endmacro


zp_trans_tmp	:=	$A8				; transient command buffer
zp_trans_acc	:=	$AC				; 4 byte accumulator used in hex parsers
zp_tmp_ptr	:=	$AC				; !! NOTE: overlaps acc


