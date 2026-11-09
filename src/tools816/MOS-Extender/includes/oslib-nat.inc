	ifnd __OSLIB_NAT_INC__
__OSLIB_NAT_INC__:

EVENT_00_OUTPUT_BUF_EMPTY		:=	0
EVENT_01_INPUT_BUF_FULL			:=	1
EVENT_02_INPUT_BUF_ENTER		:=	2
EVENT_03_ADC_READY			:=	3
EVENT_04_VSYNC				:=	4
EVENT_05_INTERVAL			:=	5
EVENT_06_ESCAPE				:=	6
EVENT_07_SERIAL_ERROR			:=	7
EVENT_08_NET				:=	8
EVENT_09_USER				:=	9


FSCV_00_OPT				:=	$00
FSCV_01_EOF				:=	$01
FSCV_02_RUN				:=	$02
FSCV_03_FSCMD				:=	$03
FSCV_04_RUN				:=	$04
FSCV_05_CAT				:=	$05
FSCV_06_NEWFS				:=	$06
FSCV_07_FHRANGE				:=	$07
FSCV_08_CLI_INIT			:=	$08
FSCV_09_EX				:=	$09
FSCV_0A_INFO				:=	$0A
FSCV_0B_RUN				:=	$0B
FSCV_0C_RENAME				:=	$0C


OSBYTE_0_HOST_OS			:=	0
OSBYTE_13_DISABLE_EVENT			:=	13
OSBYTE_14_ENABLE_EVENT			:=	14
OSBYTE_15_FLUSH_INPUT			:=	15
OSBYTE_21_FLUSH_BUFFER			:=	21
OSBYTE_108_WRITE_SHADOW_STATE		:=	108
OSBYTE_118_SET_KEYBOARD_LEDS		:=	118
OSBYTE_119_CLOSE_SPOOL_AND_EXEC		:=	119
OSBYTE_126_ESCAPE_ACK			:=	126
OSBYTE_129_INKEY			:=	129
OSBYTE_135_GET_MODE			:=	135
OSBYTE_138_CHAR_IN_BUFFER		:=	138
OSBYTE_142_ENTER_LANGUAGE		:=	142
OSBYTE_143_SERVICE_CALL			:=	143
OSBYTE_153_CHAR_IN_BUFFER_CK_ESC	:=	153
OSBYTE_156_SERIAL_STATE			:=	156
OSBYTE_160_READ_VDU_VARIABLE		:=	160
OSBYTE_168_READ_ROM_POINTER_TABLE	:=	168
OSBYTE_171_ROMTAB			:=	170
OSBYTE_232_VAR_IRQ_MASK_SERIAL		:=	232
OSBYTE_234_VAR_TUBE			:=	234
OSBYTE_253_VAR_LAST_RESET		:=	253


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

SERVICE_0_NOP				:=	$0
SERVICE_1_ABSWKSP_REQ			:=	$1
SERVICE_2_RELWKSP_REQ			:=	$2
SERVICE_3_AUTOBOOT			:=	$3
SERVICE_4_UKCMD				:=	$4
SERVICE_5_UKINT				:=	$5
SERVICE_6_BRK				:=	$6
SERVICE_7_UKOSBYTE			:=	$7
SERVICE_7_UKOSWORD			:=	$8
SERVICE_9_HELP				:=	$9
SERVICE_A_ABSWKSP_CLAIM			:=	$A
SERVICE_B_NMI_RELEASE			:=	$B
SERVICE_C_NMI_CLAIM			:=	$C
SERVICE_D_ROMFS_INIT			:=	$D
SERVICE_E_ROMFS_GETB			:=	$E
SERVICE_F_FSVEC_CLAIMED			:=	$F
SERVICE_10_SPOOL_CLOSE			:=	$10
SERVICE_11_FONT_BANG			:=	$11
SERVICE_12_INITFS			:=	$12
SERVICE_13_SERIAL_CHAR			:=	$13
SERVICE_14_PRINT_CHAR			:=	$14
SERVICE_15_100Hz			:=	$15
SERVICE_25_FSINFO			:=	$25

	endif