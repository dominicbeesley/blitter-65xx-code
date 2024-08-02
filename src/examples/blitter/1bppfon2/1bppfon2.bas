REM >1BPPFO2 A BASIC EXAMPLE OF 1BPP BLITS
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

DMAC_BLITCON=&FD00
DMAC_FUNCGEN=&FD01
DMAC_MASK_FIRST=&FD02
DMAC_MASK_LAST=&FD03
DMAC_WIDTH=&FD04
DMAC_HEIGHT=&FD05
DMAC_SHIFT_A=&FD06
DMAC_SHIFT_B=&FD07
DMAC_STRIDE_A=&FD08
DMAC_STRIDE_B=&FD0A
DMAC_STRIDE_C=&FD0C
DMAC_STRIDE_D=&FD0E
DMAC_ADDR_A=&FD10
DMAC_DATA_A=&FD13
DMAC_ADDR_B=&FD14
DMAC_DATA_B=&FD17
DMAC_ADDR_C=&FD18
DMAC_DATA_C=&FD1B
DMAC_ADDR_D=&FD1C
DMAC_ADDR_E=&FD20



PROCSELDMAC:

REPEAT:*FX19
PROCBlitCharCell(32+RND(50),RND(4)-1,RND(312)-1, RND(240)-1)
UNTILFALSE
:
DEFPROCBlitCharCell(A%,C%,X%,Y%):LOCAL CC%,SA%
CC%=(C% AND 2)*&78 + (C% AND 1)*&0F:REM make screen colour
SA%=&FF3000+(X% DIV 4)*8+(Y% DIV 8)*640 + (Y% MOD 8)

REM plot a solid colour through a mask read from the font data in MOS ROM at 
REM FF C000 the character is aligned to a cell horizontally (not shifted) but 
REM is placed on an arbitrary scan line within a cell using the CELL mode
REM address generator

?DMAC_BLITCON=BLITCON_EXEC_A+BLITCON_EXEC_C+BLITCON_EXEC_D: REM mask from A, original screen C, write screen D
?DMAC_FUNCGEN=&CA:REM (A AND B) OR (NOT A AND C)
?DMAC_WIDTH=1
?DMAC_HEIGHT=7
?DMAC_SHIFT_A=0
?DMAC_MASK_FIRST=&FF
?DMAC_MASK_LAST=&FF
!DMAC_ADDR_A = &FFC000 + (A%-32)*8
?DMAC_DATA_B=CC%
!DMAC_ADDR_C = SA%
!DMAC_STRIDE_A = 1
?DMAC_STRIDE_C = SCR_CHAR_ROW%: REM also sets STRIDE_D
DMAC_STRIDE_C?1 = SCR_CHAR_ROW% DIV 256: REM also sets STRIDE_D
?DMAC_BLITCON=BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_2BPP
ENDPROC
:
DEFPROCSELDMAC:?&EE=&D1:?&FCFF=&D1:?&FCFE=&FE:?&FCFD=&FE:ENDPROC:REM Select JIM device and set page to chipset
