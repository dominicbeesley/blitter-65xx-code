   10REM >1BPPFO3 A BASIC example of 1BPP blits with horizontal and vertical shifts
   20*VNVDU ON
   30*XMLOAD S.ISHSPR #D1 20000
   40MODE 1:BPP%=2:SCRX%=320:SCRY%=256
   50COLOUR 129:CLS
   60FORI%=0TO100:DRAW RND(1280),RND(1024):GCOL0,RND(4):NEXT
   70VDU 19,0,16,0,0,0
   80VDU 19,1,16,50,190,0
   90VDU 19,2,16,0,60,190
  100VDU 19,3,16,190,120,120
  110SCR_CHAR_ROW%=SCRX%*BPP%
  120REM BLTCON is written in two passes with top bit clear i.e. not BLTCON_ACT_ACT
  130REM the exec flags are first set
  140REM then with top bit set the active flag, bit mode and cell flags are set
  150REM BLTCON/ACT byte flags
  160BLITCON_ACT_ACT=&80:REM always set when setting act constants/execing  
  170BLITCON_ACT_CELL=&40:REM cell addressing used i.e. move one byte left adds 8 to address moving one line down either adds 1 byte or STRIDE depending on whether line crosses an 8 line boundary
  180BLITCON_ACT_MODE_1BPP=&00:REM 1 bit per pixel mapping 2 colours
  190BLITCON_ACT_MODE_2BPP=&10:REM 2 bit per pixel mapping 4 colours
  200BLITCON_ACT_MODE_4BPP=&20:REM 4 bit per pixel mapping 16 colours
  210BLITCON_ACT_MODE_8BPP=&30:REM 8 bit per pixel mapping 256 colours
  220BLITCON_ACT_LINE=&08:REM draw a line
  230BLITCON_ACT_COLLISION=&04:REM gets reset for any non-zero D data (even in EXEC_D is clear)
  240BLITCON_ACT_WRAP=&02:REM wrap C/D addresses to fit between min/max
  250BLITCON_EXEC_A=&01
  260BLITCON_EXEC_B=&02
  270BLITCON_EXEC_C=&04
  280BLITCON_EXEC_D=&08
  290BLITCON_EXEC_E=&10
  300BLIT_BLITCON=&FD00
  310BLIT_FUNCGEN=&FD01
  320BLIT_MASK_FIRST=&FD02
  330BLIT_MASK_LAST=&FD03
  340BLIT_WIDTH=&FD04
  350BLIT_HEIGHT=&FD05
  360BLIT_SHIFT_A=&FD06
  370BLIT_STRIDE_A=&FD08
  380BLIT_STRIDE_B=&FD0A
  390BLIT_STRIDE_C=&FD0C
  400BLIT_ADDR_A=&FD10
  410BLIT_DATA_A=&FD13
  420BLIT_ADDR_B=&FD14
  430BLIT_DATA_B=&FD17
  440BLIT_ADDR_C=&FD18
  450BLIT_DATA_C=&FD1B
  460BLIT_ADDR_E=&FD1C
  470PROCSELDMAC:
  480READ W%
  490REPEAT:
  500READ WM%,H%, O%, M%
  510PROCBlitSprite(O%,M%,RND(280),RND(200),W%,WM%,H%)
  520READ W%:IF W%=-1THEN RESTORE:READ W%
  530UNTIL0
  540END
  550:
  560DEFPROCBlitSprite(O%,M%,X%,Y%,W%,WM%,H%):LOCAL CC%,SA%,SHX%,ML%,W2%
  570SA%=&FF3000+(X% DIV 4)*8+(Y% DIV 8)*640 + (Y% MOD 8)
  580W2%=W%:SHX%=X% MOD 4:IFSHX%<>0 THEN W2%=W2%+1:REM if there's a shift we need to widen the blit
  590REM plot a non masked sprite data is read from channel B, channel C is used to read 
  600REM existing screen data. The A channel is not executed (no mask) but the A channel
  610REM must be initialized with &FF to not mask off data
  620REM Sprite is placed on an arbitrary scan line within a cell using the CELL mode
  630REM address generator
  640?BLIT_BLITCON=BLITCON_EXEC_A+BLITCON_EXEC_B+BLITCON_EXEC_C+BLITCON_EXEC_D: REM bitmap from B, original screen C, write screen D
  650?BLIT_FUNCGEN=&CA:REM (A AND B) OR (NOT A AND C)
  660?BLIT_WIDTH=W2%-1
  670?BLIT_HEIGHT=H%-1
  680?BLIT_SHIFT_A=SHX%:REM this also sets shift B
  690REM as there may be a shift we need to mask off bits of the mask accordingly
  700?BLIT_MASK_FIRST=FNshr(&FF,SHX%)
  710IF WM%<>(W%DIV2) THEN ML%=&FFF0 ELSE ML%=&FF00
  720IF SHX%=0 THEN ?BLIT_MASK_LAST=&FF ELSE ?BLIT_MASK_LAST=FNshr(ML%,SHX%)
  730REM poke these first in increasing order to use !
  740!BLIT_STRIDE_A = WM%
  750!BLIT_STRIDE_B = W%
  760!BLIT_STRIDE_C = SCR_CHAR_ROW%: REM also sets STRIDE_D
  770!BLIT_ADDR_A = &20000+M%
  780!BLIT_ADDR_B = &20000+O%
  790!BLIT_ADDR_C = SA%: REM also sets ADDR_D
  800?BLIT_BLITCON=BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_2BPP
  810ENDPROC
  820:
  830DEFPROCSELDMAC:?&EE=&D1:?&FCFF=&D1:?&FCFE=&FE:?&FCFD=&FE:ENDPROC:REM Select JIM device and set page to chipset
  840:
  850DEFFNshr(V%,N%):LOCALI%:IFN%>0THENFORI%=1TON%:V%=V%DIV2:NEXT:=V%ELSE=V%
  860:
  870REM table of start, width, height of sprites in file
  880DATA&04,&02,&0C,&00,&30,&04,&02,&0C,&48,&78,&04,&02,&0C,&90,&C0,&05,&03,&10,&D8,&128,&05,&03,&0C,&158,&194,&06,&03,&0A,&1B8,&1F4
  890DATA&02,&01,&06,&212,&21E,&07,&04,&0C,&224,&278,&05,&03,&0F,&2A8,&2F3,&02,&01,&06,&320,&32C,&03,&02,&0A,&332,&350,-1
