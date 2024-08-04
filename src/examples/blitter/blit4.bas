   10 REM >BLIT4 - an example if using channel E to save the screen contents
   20 REM before a blit and then restore
   30 DIM S_SA%(10),S_RA%(10),S_W%(10),S_H%(10):REM save scr addr, save addr, width, height
   40 *VNVDU ON
   50 *XMLOAD S.ISHSPR #D1 20000
   60 MODE 1:BPP%=2:SCRX%=320:SCRY%=256
   70 COLOUR 129:CLS
   80 FORI%=0TO100:DRAW RND(1280),RND(1024):GCOL0,RND(4):NEXT
   90 VDU 19,0,16,0,0,0
  100 VDU 19,1,16,50,190,0
  110 VDU 19,2,16,0,60,190
  120 VDU 19,3,16,190,120,120
  130 SCR_CHAR_ROW%=SCRX%*BPP%
  140 REM BLTCON is written in two passes with top bit clear i.e. not BLTCON_ACT_ACT
  150 REM the exec flags are first set
  160 REM then with top bit set the active flag, bit mode and cell flags are set
  170 REM BLTCON/ACT byte flags
  180 BLITCON_ACT_ACT=&80:REM always set when setting act constants/execing  
  190 BLITCON_ACT_CELL=&40:REM cell addressing used i.e. move one byte left adds 8 to address moving one line down either adds 1 byte or STRIDE depending on whether line crosses an 8 line boundary
  200 BLITCON_ACT_MODE_1BPP=&00:REM 1 bit per pixel mapping 2 colours
  210 BLITCON_ACT_MODE_2BPP=&10:REM 2 bit per pixel mapping 4 colours
  220 BLITCON_ACT_MODE_4BPP=&20:REM 4 bit per pixel mapping 16 colours
  230 BLITCON_ACT_MODE_8BPP=&30:REM 8 bit per pixel mapping 256 colours
  240 BLITCON_ACT_LINE=&08:REM draw a line
  250 BLITCON_ACT_COLLISION=&04:REM gets reset for any non-zero D data (even in EXEC_D is clear)
  260 BLITCON_ACT_WRAP=&02:REM wrap C/D addresses to fit between min/max
  270 BLITCON_EXEC_A=&01
  280 BLITCON_EXEC_B=&02
  290 BLITCON_EXEC_C=&04
  300 BLITCON_EXEC_D=&08
  310 BLITCON_EXEC_E=&10
  320 BLIT_BLITCON=&FD00
  330 BLIT_FUNCGEN=&FD01
  340 BLIT_MASK_FIRST=&FD02
  350 BLIT_MASK_LAST=&FD03
  360 BLIT_WIDTH=&FD04
  370 BLIT_HEIGHT=&FD05
  380 BLIT_SHIFT_A=&FD06
  390 BLIT_STRIDE_A=&FD08
  400 BLIT_STRIDE_B=&FD0A
  410 BLIT_STRIDE_C=&FD0C
  420 BLIT_ADDR_A=&FD10
  430 BLIT_DATA_A=&FD13
  440 BLIT_ADDR_B=&FD14
  450 BLIT_DATA_B=&FD17
  460 BLIT_ADDR_C=&FD18
  470 BLIT_DATA_C=&FD1B
  480 BLIT_ADDR_E=&FD1C
  490 PROCSELDMAC:
  500 !BLIT_ADDR_E=&30000:REM save screen contents here
  510 N%=0
  520 READ W%
  530 REPEAT:
  540    READ WM%,H%, O%, M%
  550    PROCBlitSprite(O%,M%,RND(280),RND(200),W%,WM%,H%)
  560    N%=N%+1
  570    READ W%:
  580   UNTIL W%=-1
  590 REPEAT:COLOURRND(4):PRINTTAB(0,30);"PRESS A KEY";:UNTIL INKEY$(0)<>""
  600 COLOUR3:COLOUR128
  610 PRINTTAB(0,0);
  620 N%=N%-1
  630 REPEAT
  640    ?BLIT_BLITCON=BLITCON_EXEC_B+BLITCON_EXEC_D: REM restore data from channel B to channel D
  650    ?BLIT_FUNCGEN=&CC:REM B
  660    ?BLIT_WIDTH=S_W%(N%)-1
  670    ?BLIT_HEIGHT=S_H%(N%)
  680    ?BLIT_SHIFT_A=0
  690    ?BLIT_MASK_FIRST=&FF:?DMAC_MASK_LAST=&FF:?DMAC_DATA_A=&FF:REM no mask
  700    !BLIT_STRIDE_B = S_W%(N%)
  710    !BLIT_STRIDE_C = SCR_CHAR_ROW% 
  720    
  730    !BLIT_ADDR_B = S_RA%(N%)
  740    !BLIT_ADDR_C = S_SA%(N%)
  750    ?BLIT_BLITCON=BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_2BPP
  760    N%=N%-1
  770    A%=INKEY(40)
  780   UNTIL N%<0
  790 END
  800 :
  810 DEFPROCBlitSprite(O%,M%,X%,Y%,W%,WM%,H%):LOCAL CC%,SA%,SHX%,ML%
  820 SA%=&FF3000+(X% DIV 4)*8+(Y% DIV 8)*640 + (Y% MOD 8)
  830 W2%=W%
  840 SHX%=X% MOD 4:IFSHX%<>0 THEN W2%=W2%+1:REM if there's a shift we need to widen the blit
  850 REM plot a non masked sprite data is read from channel B, channel C is used to read 
  860 REM existing screen data. The A channel is not executed (no mask) but the A channel
  870 REM must be initialized with &FF to not mask off data
  880 REM Sprite is placed on an arbitrary scan line within a cell using the CELL mode
  890 REM address generator
  900 ?BLIT_BLITCON=BLITCON_EXEC_A+BLITCON_EXEC_B+BLITCON_EXEC_C+BLITCON_EXEC_D+BLITCON_EXEC_E: REM bitmap from B, original screen C, write screen D
  910 ?BLIT_FUNCGEN=&CA:REM (A AND B) OR (NOT A AND C)
  920 ?BLIT_WIDTH=W2%-1
  930 ?BLIT_HEIGHT=H%-1
  940 ?BLIT_SHIFT_A=SHX%:REM this also sets shift B
  950 REM as there may be a shift we need to mask off bits of the mask accordingly
  960 ?BLIT_MASK_FIRST=FNshr(&FF,SHX%)
  970 IF WM%<>(W%DIV2) THEN ML%=&FFF0 ELSE ML%=&FF00
  980 IF SHX%=0 THEN ?BLIT_MASK_LAST=&FF ELSE ?DMAC_MASK_LAST=FNshr(ML%,SHX%)
  990 REM poke these first in increasing order to use !
 1000 !BLIT_STRIDE_A = WM%
 1010 !BLIT_STRIDE_B = W%
 1020 ?BLIT_STRIDE_C = SCR_CHAR_ROW%: REM also sets STRIDE_D
 1030 BLIT_STRIDE_C?1 = SCR_CHAR_ROW% DIV 256: REM also sets STRIDE_D
 1040 !BLIT_ADDR_A = &20000+M%
 1050 !BLIT_ADDR_B = &20000+O%
 1060 !BLIT_ADDR_C = SA%: REM also sets ADDR_D
 1070 REM before starting the blit make a record of where to restore data to
 1080 S_SA%(N%)=!BLIT_ADDR_C:S_RA%(N%)=!DMAC_ADDR_E:S_W%(N%)=?DMAC_WIDTH+1:S_H%(N%)=?DMAC_HEIGHT
 1090 ?BLIT_BLITCON=BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_2BPP
 1100 ENDPROC
 1110 :
 1120 DEFPROCSELDMAC:?&EE=&D1:?&FCFF=&D1:?&FCFE=&FE:?&FCFD=&FE:ENDPROC:REM Select JIM device and set page to chipset
 1130 :
 1140 DEFFNshr(V%,N%):LOCALI%:IFN%>0THENFORI%=1TON%:V%=V%DIV2:NEXT:=V%ELSE=V%
 1150 :
 1160 REM table of start, width, height of sprites in file
 1170 DATA&04,&02,&0C,&00,&30,&04,&02,&0C,&48,&78,&04,&02,&0C,&90,&C0,&05,&03,&10,&D8,&128,&05,&03,&0C,&158,&194,&06,&03,&0A,&1B8,&1F4
 1180 DATA&02,&01,&06,&212,&21E,&07,&04,&0C,&224,&278,&05,&03,&0F,&2A8,&2F3,&02,&01,&06,&320,&32C,&03,&02,&0A,&332,&350,-1
