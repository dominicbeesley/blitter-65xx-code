
	.IFNDEF __DEFS_INC__
__DEFS_INC__:

NAT_STACK_TOP	=	$AFFF
NAT_FREE_1		=	$9000

; TODO: harmonize this with the includes in model-c-mos

NAT_OS_VECS 		:= $00FD00
NAT_OS_VECS_COUNT 	:= IX_VEC_MAX+1


; Indices - these are used in 16 bit calls i.e. CallAVector
IX_USERV				:= $00
IX_BRKV					:= $01
IX_IRQ1V				:= $02
IX_IRQ2V				:= $03
IX_CLIV					:= $04
IX_BYTEV				:= $05
IX_WORDV				:= $06
IX_WRCHV				:= $07
IX_RDCHV				:= $08
IX_FILEV				:= $09
IX_ARGSV				:= $0A
IX_BGETV				:= $0B
IX_BPUTV				:= $0C
IX_GBPBV				:= $0D
IX_FINDV				:= $0E
IX_FSCV					:= $0F
IX_EVNTV				:= $10
IX_UPTV					:= $11
IX_NETV					:= $12
IX_VDUV					:= $13
IX_KEYV					:= $14
IX_INSV					:= $15
IX_REMV					:= $16
IX_CNPV					:= $17
IX_IND1V				:= $18
IX_IND2V				:= $19
IX_IND3V				:= $1A

IX_VEC_BBC_MAX				:= $1A

IX_N_P100V				:= $1B

IX_VEC_MAX				:= $1B

; NOTE: that the native vectors are 3 byte each, the 3rd byte of each is unused and reserved
; these are not to be poked direct, instead the call a vector and claim a vector calls should be used

NAT_USERV					:=	NAT_OS_VECS+3*IX_USERV	; User vector, called by *LINE, *CODE, OSWORD >=&E0
NAT_BRKV					:=	NAT_OS_VECS+3*IX_BRKV	; The BRK vector
NAT_IRQ1V					:=	NAT_OS_VECS+3*IX_IRQ1V	; Main interrupt vector
NAT_IRQ2V					:=	NAT_OS_VECS+3*IX_IRQ2V	; Secondary interrupt vector
NAT_CLIV					:=	NAT_OS_VECS+3*IX_CLIV	; Command Line Interpreter vector
NAT_BYTEV					:=	NAT_OS_VECS+3*IX_BYTEV	; OSBYTE (*FX) calls
NAT_WORDV					:=	NAT_OS_VECS+3*IX_WORDV	; OSWORD calls
NAT_WRCHV					:=	NAT_OS_VECS+3*IX_WRCHV	; Send character to current output stream
NAT_RDCHV					:=	NAT_OS_VECS+3*IX_RDCHV	; Wait for a character from current input stream
NAT_FILEV					:=	NAT_OS_VECS+3*IX_FILEV	; Operate on a whole file, eg loading/saving/delete/etc
NAT_ARGSV					:=	NAT_OS_VECS+3*IX_ARGSV	; Read/Write arguments on an open file
NAT_BGETV					:=	NAT_OS_VECS+3*IX_BGETV	; Read a byte from an open file
NAT_BPUTV					:=	NAT_OS_VECS+3*IX_BPUTV	; Write a byte to an open file
NAT_GBPBV					:=	NAT_OS_VECS+3*IX_GBPBV	; Read/Write block of data from/to open file or device
NAT_FINDV					:=	NAT_OS_VECS+3*IX_FINDV	; Open or close a file
NAT_FSCV					:=	NAT_OS_VECS+3*IX_FSCV	; Various filing system control calls
NAT_EVNTV					:=	NAT_OS_VECS+3*IX_EVNTV	; Event handler
NAT_UPTV					:=	NAT_OS_VECS+3*IX_UPTV	; User Print vector
NAT_NETV					:=	NAT_OS_VECS+3*IX_NETV	; Network Print vector
NAT_VDUV					:=	NAT_OS_VECS+3*IX_VDUV	; Unrecognised VDU commands
NAT_KEYV					:=	NAT_OS_VECS+3*IX_KEYV	; Read the keyboard
NAT_INSV					:=	NAT_OS_VECS+3*IX_INSV	; Insert characters into a buffer
NAT_REMV					:=	NAT_OS_VECS+3*IX_REMV	; Remove characters from a buffer
NAT_CNPV					:=	NAT_OS_VECS+3*IX_CNPV	; Count or Purge a buffer
NAT_IND1V					:=	NAT_OS_VECS+3*IX_IND1V	; Spare 
NAT_IND2V					:=	NAT_OS_VECS+3*IX_IND2V	; Spare
NAT_IND3V					:=	NAT_OS_VECS+3*IX_IND3V	; Spare
NAT_N_P100V					:=	NAT_OS_VECS+3*IX_N_P100V; 100Hz poll vector


	.ENDIF