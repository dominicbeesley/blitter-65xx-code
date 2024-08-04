REM >1BPPFO3 A BASIC example of 1BPP blits with horizontal and vertical shifts

*XMLOAD S.ISHSPR #D1 20000
MODE 1:BPP%=2:SCRX%=320:SCRY%=256:COLOUR 129:CLS:FORI%=0TO100:DRAW RND(320),RND(1024):GCOL0,RND(4):NEXT

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

PROCSELDMAC:

Y%=0
FOR A%=0TO2:FOR X%=16TO19
PROCBlitSprite(A%,X%,Y%)
Y%=Y%+14
NEXT:NEXT

END

:
DEFPROCBlitSprite(A%,X%,Y%):LOCAL CC%,SA%,SHX%,W%
SA%=&FF3000+(X% DIV 4)*8+(Y% DIV 8)*640 + (Y% MOD 8)
W%=4
SHX%=X% MOD 4:IFSHX%<>0 THEN W%=W%+1:REM if there's a shift we need to widen the blit
REM plot a non masked sprite data is read from channel B, channel C is used to read 
REM existing screen data. The A channel is not executed (no mask) but the A channel
REM must be initialized with &FF to not mask off data
REM Sprite is placed on an arbitrary scan line within a cell using the CELL mode
REM address generator

?BLIT_BLITCON=BLITCON_EXEC_B+BLITCON_EXEC_C+BLITCON_EXEC_D: REM bitmap from B, original screen C, write screen D
?BLIT_FUNCGEN=&CA:REM (A AND B) OR (NOT A AND C)
?BLIT_WIDTH=W%-1
?BLIT_HEIGHT=12-1
?BLIT_SHIFT_A=SHX%
REM as there may be a shift we need to mask off bits of the mask accordingly
?BLIT_MASK_FIRST=FNshr(&FF,SHX%)
IF SHX%=0 THEN ?BLIT_MASK_LAST=&FF ELSE ?DMAC_MASK_LAST=FNshr(&FF00,SHX%)
?BLIT_DATA_A=&FF
!BLIT_ADDR_B = &20000 + (A% MOD 3) * &48
!BLIT_ADDR_C = SA%
!BLIT_STRIDE_B = 4
?BLIT_STRIDE_C = SCR_CHAR_ROW%: REM also sets STRIDE_D
BLIT_STRIDE_C?1 = SCR_CHAR_ROW% DIV 256: REM also sets STRIDE_D


?BLIT_BLITCON=BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_2BPP
ENDPROC
:
DEFPROCSELDMAC:?&EE=&D1:?&FCFF=&D1:?&FCFE=&FE:?&FCFD=&FE:ENDPROC:REM Select JIM device and set page to chipset
:
DEFFNshr(V%,N%):LOCALI%:IFN%>0THENFORI%=1TON%:V%=V%DIV2:NEXT:=V%ELSE=V%