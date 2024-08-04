   10REM >BLIT2 - masked sprite with shifts
   20*XMLOAD S.ISHSPR #D1 20000
   30MODE 1:BPP%=2:SCRX%=320:SCRY%=256
   40COLOUR 129:CLS
   50REMFORI%=0TO100:DRAW RND(320),RND(1024):GCOL0,RND(4):NEXT
   60SCR_CHAR_ROW%=SCRX%*BPP%
   70REM BLTCON is written in two passes with top bit clear i.e. not BLTCON_ACT_ACT
   80REM the exec flags are first set
   90REM then with top bit set the active flag, bit mode and cell flags are set
  100REM BLTCON/ACT byte flags
  110BLITCON_ACT_ACT=&80:REM always set when setting act constants/execing  
  120BLITCON_ACT_CELL=&40:REM cell addressing used i.e. move one byte left adds 8 to address moving one line down either adds 1 byte or STRIDE depending on whether line crosses an 8 line boundary
  130BLITCON_ACT_MODE_1BPP=&00:REM 1 bit per pixel mapping 2 colours
  140BLITCON_ACT_MODE_2BPP=&10:REM 2 bit per pixel mapping 4 colours
  150BLITCON_ACT_MODE_4BPP=&20:REM 4 bit per pixel mapping 16 colours
  160BLITCON_ACT_MODE_8BPP=&30:REM 8 bit per pixel mapping 256 colours
  170BLITCON_ACT_LINE=&08:REM draw a line
  180BLITCON_ACT_COLLISION=&04:REM gets reset for any non-zero D data (even in EXEC_D is clear)
  190BLITCON_ACT_WRAP=&02:REM wrap C/D addresses to fit between min/max
  200BLITCON_EXEC_A=&01
  210BLITCON_EXEC_B=&02
  220BLITCON_EXEC_C=&04
  230BLITCON_EXEC_D=&08
  240BLITCON_EXEC_E=&10
  250BLIT_BLITCON=&FD00
  260BLIT_FUNCGEN=&FD01
  270BLIT_MASK_FIRST=&FD02
  280BLIT_MASK_LAST=&FD03
  290BLIT_WIDTH=&FD04
  300BLIT_HEIGHT=&FD05
  310BLIT_SHIFT_A=&FD06
  320BLIT_STRIDE_A=&FD08
  330BLIT_STRIDE_B=&FD0A
  340BLIT_STRIDE_C=&FD0C
  350BLIT_ADDR_A=&FD10
  360BLIT_DATA_A=&FD13
  370BLIT_ADDR_B=&FD14
  380BLIT_DATA_B=&FD17
  390BLIT_ADDR_C=&FD18
  400BLIT_DATA_C=&FD1B
  410BLIT_ADDR_E=&FD1C
  420PROCSELDMAC:
  430Y%=0
  440FOR X%=16TO28
  450PROCBlitSprite(X%,Y%)
  460Y%=Y%+16
  470NEXT
  480END
  490:
  500DEFPROCBlitSprite(X%,Y%):LOCAL CC%,SA%,SHX%,W%,WM%,W2%
  510SA%=&FF3000+(X% DIV 4)*8+(Y% DIV 8)*640 + (Y% MOD 8)
  520W%=5:WM%=3
  530W2%=W%:SHX%=X% MOD 4:IFSHX%<>0 THEN W2%=W2%+1:REM if there's a shift we need to widen the blit
  540REM plot a non masked sprite data is read from channel B, channel C is used to read 
  550REM existing screen data. The A channel is not executed (no mask) but the A channel
  560REM must be initialized with &FF to not mask off data
  570REM Sprite is placed on an arbitrary scan line within a cell using the CELL mode
  580REM address generator
  590?BLIT_BLITCON=BLITCON_EXEC_A+BLITCON_EXEC_B+BLITCON_EXEC_C+BLITCON_EXEC_D: REM bitmap from B, original screen C, write screen D
  600?BLIT_FUNCGEN=&CA:REM (A AND B) OR (NOT A AND C)
  610?BLIT_WIDTH=W2%-1
  620?BLIT_HEIGHT=15-1
  630?BLIT_SHIFT_A=SHX%:REM this also sets shift B
  640REM as there may be a shift we need to mask off bits of the mask accordingly
  650?BLIT_MASK_FIRST=FNshr(&FF,SHX%)
  660IF WM%<>(W%DIV2) THEN ML%=&FFF0 ELSE ML%=&FF00:PRINT ~ML%
  670IF SHX%=0 THEN ?BLIT_MASK_LAST=&FF ELSE ?BLIT_MASK_LAST=FNshr(ML%,SHX%)
  680REM poke these first in increasing order to use !
  690!BLIT_STRIDE_A = WM%
  700!BLIT_STRIDE_B = W%
  710!BLIT_STRIDE_C = SCR_CHAR_ROW%: REM also sets STRIDE_D
  720!BLIT_ADDR_A = &202F3:REM BOAT
  730!BLIT_ADDR_B = &202A8
  740!BLIT_ADDR_C = SA%: REM also sets ADDR_D
  750?BLIT_BLITCON=BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_2BPP
  760ENDPROC
  770:
  780DEFPROCSELDMAC:?&EE=&D1:?&FCFF=&D1:?&FCFE=&FE:?&FCFD=&FE:ENDPROC:REM Select JIM device and set page to chipset
  790:
  800DEFFNshr(V%,N%):LOCALI%:IFN%>0THENFORI%=1TON%:V%=V%DIV2:NEXT:=V%ELSE=V%
