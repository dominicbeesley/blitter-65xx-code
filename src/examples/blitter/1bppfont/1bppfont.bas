REM >1BPPFONT A BASIC EXAMPLE OF 1BPP BLITS
MODE 1:BPP%=2:SCRX%=320:SCRY%=256
DIM TEMP% 4

SCR_CHAR_ROW%=SCRX%*BPP%

REM BLTCON is written in two passes with top bit clear i.e. not BLTCON_ACT_ACT
REM the exec flags are first set
REM then with top bit set the active flag, bit mode and cell flags are set
REM BLTCON/ACT byte flags

BLITCON_ACT_ACT=&80:REM always set when setting act constants/execing  
BLITCON_ACT_CELL=&40:REM cell addressing used i.e. move one byte left adds 8 to address moving one line down either adds 1 byte or STRIDE depending on whether line crosses an 8 line boundary
BLITCON_ACT_MODE_1BPP=&00:REM 1 bit per pixel mapping 2 colours
BLITCON_ACT_MODE_2BPP=&10:REM 2 bit per pixel mapping 4 colours
BLITCON_ACT_MODE_4BPP=&20:REM 4 bit per pixel mapping 16 colours
BLITCON_ACT_MODE_8BPP=&30:REM 8 bit per pixel mapping 256 colours
BLITCON_ACT_LINE=&08:REM draw a line
BLITCON_ACT_COLLISION=&04:REM gets reset for any non-zero D data (even in EXEC_D is clear)
BLITCON_ACT_WRAP=&02:REM wrap C/D addresses to fit between min/max
BLITCON_EXEC_A=&01
BLITCON_EXEC_B=&02
BLITCON_EXEC_C=&04
BLITCON_EXEC_D=&08
BLITCON_EXEC_E=&10

DMAC_BLITCON=&FD60
DMAC_FUNCGEN=&FD61
DMAC_WIDTH=&FD62
DMAC_HEIGHT=&FD63
DMAC_SHIFT=&FD64
DMAC_MASK_FIRST=&FD65
DMAC_MASK_LAST=&FD66
DMAC_DATA_A=&FD67
DMAC_ADDR_A=&FD68
DMAC_DATA_B=&FD6B
DMAC_ADDR_B=&FD6C
DMAC_ADDR_C=&FD6F
DMAC_ADDR_D=&FD72
DMAC_ADDR_E=&FD75
DMAC_STRIDE_A=&FD78
DMAC_STRIDE_B=&FD7A
DMAC_STRIDE_C=&FD7C
DMAC_STRIDE_D=&FD7E


PROCSELDMAC:

REPEAT:*FX19
PROCBlitCharCell(32+RND(50),RND(4)-1,RND(40)-1, RND(30)-1)
UNTILFALSE
:
DEFPROCBlitCharCell(A%,C%,X%,Y%):LOCAL CC%,SA%
CC%=(C% AND 2)*&78 + (C% AND 1)*&0F:REM make screen colour
SA%=&FF3000+X%*16+Y%*640

REM plot a solid colour through a mask read from the font data in MOS ROM at FF C000
REM the character is aligned to a cell (not shifted)

?DMAC_BLITCON=BLITCON_EXEC_A+BLITCON_EXEC_C+BLITCON_EXEC_D: REM mask from A, original screen C, write screen D
?DMAC_FUNCGEN=&CA:REM (A AND B) OR (NOT A AND C)
?DMAC_WIDTH=1
?DMAC_HEIGHT=7
?DMAC_SHIFT=0
?DMAC_MASK_FIRST=&FF
?DMAC_MASK_LAST=&FF
PROCPOKE24(DMAC_ADDR_A, &FFC000 + (A%-32)*8)
?DMAC_DATA_B=CC%
PROCPOKE24(DMAC_ADDR_C, SA%)
PROCPOKE24(DMAC_ADDR_D, SA%)
PROCPOKE16(DMAC_STRIDE_A, 1)
PROCPOKE16(DMAC_STRIDE_C, SCR_CHAR_ROW%)
PROCPOKE16(DMAC_STRIDE_D, SCR_CHAR_ROW%)
?DMAC_BLITCON=BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_2BPP
ENDPROC
:
DEFPROCSELDMAC:?&EE=&D1:?&FCFF=&D1:?&FCFE=&FC:?&FCFD=&FE:ENDPROC:REM Select JIM device and set page to chipset
:
DEFPROCPOKE24(A%,V%):!TEMP%=V%:A%?0=TEMP%?2:A%?1=TEMP%?1:A%?2=TEMP%?0:ENDPROC:REM Quick 24bit big-endian address poke
:
DEFPROCPOKE16(A%,V%):!TEMP%=V%:A%?0=TEMP%?1:A%?1=TEMP%?0:ENDPROC:REM Quick 16bit big-endian poke
: