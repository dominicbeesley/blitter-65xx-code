REM >1BPPFO3 A BASIC example of 1BPP blits with horizontal and vertical shifts

*XMLOAD S.ISHSPR #D1 20000
MODE 1:BPP%=2:SCRX%=320:SCRY%=256:COLOUR 129:CLS
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


Y%=0
FOR A%=0TO2:FOR X%=16TO19
PROCBlitSprite(A%,X%,Y%)
Y%=Y%+14
NEXT:NEXT

END

:
DEFPROCBlitSprite(A%,X%,Y%):LOCAL CC%,SA%,SHX%,W%
SA%=&FF3000+(X% DIV 4)*8+(Y% DIV 8)*640 + (Y% MOD 8)
SPA%=&20000 + (A% MOD 3) * &48
W%=4
SHX%=X% MOD 4:IFSHX%<>0 THEN W%=W%+1:REM if there's a shift we need to widen the blit
REM plot a non masked sprite data is read from channel B, channel C is used to read 
REM existing screen data. The A channel is not executed (no mask) but the A channel
REM must be initialized with &FF to not mask off data
REM Sprite is placed on an arbitrary scan line within a cell using the CELL mode
REM address generator

?DMAC_BLITCON=BLITCON_EXEC_A+BLITCON_EXEC_B+BLITCON_EXEC_C+BLITCON_EXEC_D: REM bitmap from B, original screen C, write screen D
?DMAC_FUNCGEN=&CA:REM (A AND B) OR (NOT A AND C)
?DMAC_WIDTH=W%-1
?DMAC_HEIGHT=12-1
?DMAC_SHIFT=(SHX%*16) + (X% MOD 8)
REM as there may be a shift we need to mask off bits of the mask accordingly
?DMAC_MASK_FIRST=FNshr(&FF,SHX%)
IF SHX%=0 THEN ?DMAC_MASK_LAST=&FF ELSE ?DMAC_MASK_LAST=FNshr(&FF00,SHX%)
PROCPOKE24(DMAC_ADDR_A, SPA%+&30)
PROCPOKE24(DMAC_ADDR_B, SPA%)
PROCPOKE24(DMAC_ADDR_C, SA%)
PROCPOKE24(DMAC_ADDR_D, SA%)
PROCPOKE16(DMAC_STRIDE_A, 2)
PROCPOKE16(DMAC_STRIDE_B, 4)
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
DEFFNshr(V%,N%):LOCALI%:IFN%>0THENFORI%=1TON%:V%=V%DIV2:NEXT:=V%ELSE=V%