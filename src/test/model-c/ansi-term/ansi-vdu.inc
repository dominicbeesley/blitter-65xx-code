.IFNDEF __ANSI_VDU_INC
.DEFINE __ANSI_VDU_INC

.IFNDEF __ANSI_VDU_ASM
		.import	my_WRCHV
		.import	my_OSBYTE

		.import crtcRegsAnsi
.ENDIF


MODE_ANSI_TEXT_COLS		= 80
MODE_ANSI_TEXT_ROWS		= 25
MODE_ANSI_ULA_CTL		= $9c
MODE0_ULA_CTL			= $9c
MOS_WRCHV_ORG			= $E0A4			; for now hard-code vdu vector pass on
MOS_BYTEV_ORG			= $E772

MODE_ANSI			= 27			; mode #

MODE_ANSI_HIMEM		= $6000				; room for 4k screen + 4k font
MODE_ANSI_CHARMAP	= $7000				; char/attr base address in CPU
MODE_ANSI_CRTC_BASE = $0800				; 2K below MA12 wrap (MA is screen addr/2)
MODE_ANSI_CHARMAP_SZ= $1000

.ENDIF