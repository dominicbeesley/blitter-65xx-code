REM >1BPPFO3 A BASIC example of 1BPP blits with horizontal and vertical shifts
*VNVDU ON

*XMLOAD S.ISHSPR #D1 20000
MODE 1:BPP%=2:SCRX%=320:SCRY%=256
COLOUR 129:CLS
FORI%=0TO100:DRAW RND(1280),RND(1024):GCOL0,RND(4):NEXT

VDU 19,0,16,0,0,0
VDU 19,1,16,50,190,0
VDU 19,2,16,0,60,190
VDU 19,3,16,190,120,120


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

READ W%
REPEAT:
 READ WM%,H%, O%, M%
 PROCBlitSprite(O%,M%,RND(280),RND(200),W%,WM%,H%)
 READ W%:IF W%=-1THEN RESTORE:READ W%
UNTIL0

END

:
DEFPROCBlitSprite(O%,M%,X%,Y%,W%,WM%,H%):LOCAL CC%,SA%,SHX%,ML%
SA%=&FF3000+(X% DIV 4)*8+(Y% DIV 8)*640 + (Y% MOD 8)
W2%=W%
SHX%=X% MOD 4:IFSHX%<>0 THEN W2%=W2%+1:REM if there's a shift we need to widen the blit
REM plot a non masked sprite data is read from channel B, channel C is used to read 
REM existing screen data. The A channel is not executed (no mask) but the A channel
REM must be initialized with &FF to not mask off data
REM Sprite is placed on an arbitrary scan line within a cell using the CELL mode
REM address generator

?BLIT_BLITCON=BLITCON_EXEC_A+BLITCON_EXEC_B+BLITCON_EXEC_C+BLITCON_EXEC_D: REM bitmap from B, original screen C, write screen D
?BLIT_FUNCGEN=&CA:REM (A AND B) OR (NOT A AND C)
?BLIT_WIDTH=W2%-1
?BLIT_HEIGHT=H%-1
?BLIT_SHIFT_A=SHX%:REM this also sets shift B
REM as there may be a shift we need to mask off bits of the mask accordingly
?BLIT_MASK_FIRST=FNshr(&FF,SHX%)
IF WM%<>(W%DIV2) THEN ML%=&FFF0 ELSE ML%=&FF00
IF SHX%=0 THEN ?BLIT_MASK_LAST=&FF ELSE ?DMAC_MASK_LAST=FNshr(ML%,SHX%)
REM poke these first in increasing order to use !
!BLIT_STRIDE_A = WM%
!BLIT_STRIDE_B = W%
?BLIT_STRIDE_C = SCR_CHAR_ROW%: REM also sets STRIDE_D
BLIT_STRIDE_C?1 = SCR_CHAR_ROW% DIV 256: REM also sets STRIDE_D


!BLIT_ADDR_A = &20000+M%
!BLIT_ADDR_B = &20000+O%
!BLIT_ADDR_C = SA%: REM also sets ADDR_D

?BLIT_BLITCON=BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_2BPP
ENDPROC
:
DEFPROCSELDMAC:?&EE=&D1:?&FCFF=&D1:?&FCFE=&FE:?&FCFD=&FE:ENDPROC:REM Select JIM device and set page to chipset
:
DEFFNshr(V%,N%):LOCALI%:IFN%>0THENFORI%=1TON%:V%=V%DIV2:NEXT:=V%ELSE=V%
:

REM table of start, width, height of sprites in file
DATA&04,&02,&0C,&00,&30,&04,&02,&0C,&48,&78,&04,&02,&0C,&90,&C0,&05,&03,&10,&D8,&128,&05,&03,&0C,&158,&194,&06,&03,&0A,&1B8,&1F4
DATA&02,&01,&06,&212,&21E,&07,&04,&0C,&224,&278,&05,&03,&0F,&2A8,&2F3,&02,&01,&06,&320,&32C,&03,&02,&0A,&332,&350,-1