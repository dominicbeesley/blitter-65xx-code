REM >1BPPFONT An example of blitting a solid colour through 1bpp mask to an 
REM arbitrary character cell aligned screen address
MODE 1:BPP%=2:SCRX%=320:SCRY%=256

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

BLIT_BLITCON=&FD00
BLIT_FUNCGEN=&FD01
BLIT_MASK_FIRST=&FD02
BLIT_MASK_LAST=&FD03
BLIT_WIDTH=&FD04
BLIT_HEIGHT=&FD05
BLIT_SHIFT_A=&FD06
BLIT_STRIDE_A=&FD08
BLIT_STRIDE_B=&FD0A
BLIT_STRIDE_C=&FD0C
BLIT_ADDR_A=&FD10
BLIT_DATA_A=&FD13
BLIT_ADDR_B=&FD14
BLIT_DATA_B=&FD17
BLIT_ADDR_C=&FD18
BLIT_DATA_C=&FD1B
BLIT_ADDR_E=&FD1C

PROCSELDMAC:REM page the Blitter hardware into JIM

REPEAT:
PROCBlitCharCell(32+RND(50),RND(4)-1,RND(40)-1, RND(30)-1)
UNTILFALSE
:
DEFPROCBlitCharCell(A%,C%,X%,Y%):LOCAL CC%,SA%
CC%=(C% AND 2)*&78 + (C% AND 1)*&0F:REM make screen colour
SA%=&FF3000+X%*16+Y%*640

REM plot a solid colour through a mask read from the font data in MOS ROM at FF C000
REM the character is aligned to a cell (not shifted)

?BLIT_BLITCON=BLITCON_EXEC_A+BLITCON_EXEC_C+BLITCON_EXEC_D: REM mask from A, original screen C, write screen D
?BLIT_FUNCGEN=&CA:REM (A AND B) OR (NOT A AND C)
?BLIT_WIDTH=1
?BLIT_HEIGHT=7
?BLIT_SHIFT_A=0
?BLIT_MASK_FIRST=&FF
?BLIT_MASK_LAST=&FF
!BLIT_ADDR_A = &FFC000 + (A%-32)*8
?BLIT_DATA_B=CC%
!BLIT_ADDR_C = SA%
!BLIT_STRIDE_A = 1
?BLIT_STRIDE_C = SCR_CHAR_ROW%: REM also sets STRIDE_D
BLIT_STRIDE_C?1 = SCR_CHAR_ROW% DIV 256: REM also sets STRIDE_D
?BLIT_BLITCON=BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_2BPP
ENDPROC
:
DEFPROCSELDMAC:?&EE=&D1:?&FCFF=&D1:?&FCFE=&FE:?&FCFD=&FE:ENDPROC:REM Select JIM device and set page to chipset
