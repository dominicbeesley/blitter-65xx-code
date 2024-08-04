REM >BLIT4 - an example if using channel E to save the screen contents
REM before a blit and then restore
DIM S_SA%(10),S_RA%(10),S_W%(10),S_H%(10):REM save scr addr, save addr, width, height
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

DMAC_BLITCON=&FD00
DMAC_FUNCGEN=&FD01
DMAC_MASK_FIRST=&FD02
DMAC_MASK_LAST=&FD03
DMAC_WIDTH=&FD04
DMAC_HEIGHT=&FD05
DMAC_SHIFT_A=&FD06
DMAC_STRIDE_A=&FD08
DMAC_STRIDE_B=&FD0A
DMAC_STRIDE_C=&FD0C
DMAC_ADDR_A=&FD10
DMAC_DATA_A=&FD13
DMAC_ADDR_B=&FD14
DMAC_DATA_B=&FD17
DMAC_ADDR_C=&FD18
DMAC_DATA_C=&FD1B
DMAC_ADDR_E=&FD1C

PROCSELDMAC:

!DMAC_ADDR_E=&30000:REM save screen contents here

N%=0
READ W%
REPEAT:
 READ WM%,H%, O%, M%
 PROCBlitSprite(O%,M%,RND(280),RND(200),W%,WM%,H%)
 N%=N%+1
 READ W%:
UNTIL W%=-1

REPEAT:COLOURRND(4):P.TAB(0,30);"PRESS A KEY";:UNTIL INKEY$(0)<>""
COLOUR3:COLOUR128

P.TAB(0,0);
N%=N%-1
REPEAT
 ?DMAC_BLITCON=BLITCON_EXEC_B+BLITCON_EXEC_D: REM restore data from channel B to channel D
 ?DMAC_FUNCGEN=&CC:REM B
 ?DMAC_WIDTH=S_W%(N%)-1
 ?DMAC_HEIGHT=S_H%(N%)
 ?DMAC_SHIFT_A=0
 ?DMAC_MASK_FIRST=&FF:?DMAC_MASK_LAST=&FF:?DMAC_DATA_A=&FF:REM no mask
 !DMAC_STRIDE_B = S_W%(N%)
 !DMAC_STRIDE_C = SCR_CHAR_ROW% 
 
 !DMAC_ADDR_B = S_RA%(N%)
 !DMAC_ADDR_C = S_SA%(N%)
 ?DMAC_BLITCON=BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_2BPP
 N%=N%-1
 A%=INKEY(40)
UNTIL N%<0

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

?DMAC_BLITCON=BLITCON_EXEC_A+BLITCON_EXEC_B+BLITCON_EXEC_C+BLITCON_EXEC_D+BLITCON_EXEC_E: REM bitmap from B, original screen C, write screen D
?DMAC_FUNCGEN=&CA:REM (A AND B) OR (NOT A AND C)
?DMAC_WIDTH=W2%-1
?DMAC_HEIGHT=H%-1
?DMAC_SHIFT_A=SHX%:REM this also sets shift B
REM as there may be a shift we need to mask off bits of the mask accordingly
?DMAC_MASK_FIRST=FNshr(&FF,SHX%)
IF WM%<>(W%DIV2) THEN ML%=&FFF0 ELSE ML%=&FF00
IF SHX%=0 THEN ?DMAC_MASK_LAST=&FF ELSE ?DMAC_MASK_LAST=FNshr(ML%,SHX%)
REM poke these first in increasing order to use !
!DMAC_STRIDE_A = WM%
!DMAC_STRIDE_B = W%
?DMAC_STRIDE_C = SCR_CHAR_ROW%: REM also sets STRIDE_D
DMAC_STRIDE_C?1 = SCR_CHAR_ROW% DIV 256: REM also sets STRIDE_D


!DMAC_ADDR_A = &20000+M%
!DMAC_ADDR_B = &20000+O%
!DMAC_ADDR_C = SA%: REM also sets ADDR_D

REM before starting the blit make a record of where to restore data to
S_SA%(N%)=!DMAC_ADDR_C:S_RA%(N%)=!DMAC_ADDR_E:S_W%(N%)=?DMAC_WIDTH+1:S_H%(N%)=?DMAC_HEIGHT

?DMAC_BLITCON=BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_2BPP

ENDPROC
:
DEFPROCSELDMAC:?&EE=&D1:?&FCFF=&D1:?&FCFE=&FE:?&FCFD=&FE:ENDPROC:REM Select JIM device and set page to chipset
:
DEFFNshr(V%,N%):LOCALI%:IFN%>0THENFORI%=1TON%:V%=V%DIV2:NEXT:=V%ELSE=V%
:

REM table of start, width, height of sprites in file
DATA&04,&02,&0C,&00,&30,&04,&02,&0C,&48,&78,&04,&02,&0C,&90,&C0,&05,&03,&10,&D8,&128,&05,&03,&0C,&158,&194,&06,&03,&0A,&1B8,&1F4
DATA&02,&01,&06,&212,&21E,&07,&04,&0C,&224,&278,&05,&03,&0F,&2A8,&2F3,&02,&01,&06,&320,&32C,&03,&02,&0A,&332,&350,-1