	ifnd __OSLIB_NAT_INC__
__OSLIB_NAT_INC__:

;;;; COP CALLS - from Communicator 
COP_00_OPWRC				:=	$00		; WRCH
COP_01_OPWRS				:=	$01		; Write string immediate
COP_02_OPWRA				:=	$02		; Write string BHA
COP_03_OPNLI				:=	$03		; Write LF/CR
COP_04_OPRDC				:=	$04		; Wait for and read a char from input stream
COP_05_OPCLI				:=	$05		; OPCLI  - execute *command at BYX [deprecated]
COP_06_OPOSB				:=	$06		; OBYTE
COP_07_OPOSW				:=	$06		; OBWORD

COP_08_OPCAV				:=	$08		; Call A Vector - !*bad call on Communicator
COP_09_OPADV				:=	$09		; Add to vector - ?

COP_0A_OPBGT				:=	$0A		; OSBGET
COP_0C_OPFILE				:=      $0C		; OSFILE **NEW**

COP_0D_OPFND				:=	$0D		; OSFIND - deprecated on Commy - not sure need to work out for MOS/16 bit handles?
COP_0E_OPCOM				:=	$0E		; OPCOM  - execute *command at BHA

COP_15_OPASC				:=	$15		; OPASC = OSASCI - write characte, translate newlines

COP_26_OPBHA				:=	$26		; OPBHA - return address of immediate string in BHA
COP_27_OPBHI				:=	$27		; OPBHI - return following far address in BHA

COP_2F_OPIIQ				:=	$2F		; Add an IRQ handler
COP_30_OPRIQ				:=	$30		; Remove and IRQ handler
COP_31_OPMIQ				:=	$31		; Modify and IRQ handler
COP_32_OPSUM				:=	$32		; Cary-round checksum of memory area

COP_34_OPMOD				:=	$34		; Different API to commy - c.f. OS_Module on Risc OS

OPMOD_OP_INSERT				:=	$0A

COP_3F_OPBWV 				:=      $3F		; NEW OS Byte/Word Vector - add handler for OSBYTE/WORD
;;;; Service calls


	endif