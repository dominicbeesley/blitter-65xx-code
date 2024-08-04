   10 REM >1BPPFO3 A BASIC example of 1BPP blits with horizontal and vertical shifts
   20 *XMLOAD S.ISHSPR #D1 20000
   30 MODE 1:BPP%=2:SCRX%=320:SCRY%=256
   40 COLOUR 129:CLS
   50 FORI%=0TO100:DRAW RND(320),RND(1024):GCOL0,RND(4):NEXT
   60 SCR_CHAR_ROW%=SCRX%*BPP%
   70 REM BLTCON is written in two passes with top bit clear i.e. not BLTCON_ACT_ACT
   80 REM the exec flags are first set
   90 REM then with top bit set the active flag, bit mode and cell flags are set
  100 REM BLTCON/ACT byte flags
  110 BLITCON_ACT_ACT=&80:REM always set when setting act constants/execing  
  120 BLITCON_ACT_CELL=&40:REM cell addressing used i.e. move one byte left adds 8 to address moving one line down either adds 1 byte or STRIDE depending on whether line crosses an 8 line boundary
  130 BLITCON_ACT_MODE_1BPP=&00:REM 1 bit per pixel mapping 2 colours
  140 BLITCON_ACT_MODE_2BPP=&10:REM 2 bit per pixel mapping 4 colours
  150 BLITCON_ACT_MODE_4BPP=&20:REM 4 bit per pixel mapping 16 colours
  160 BLITCON_ACT_MODE_8BPP=&30:REM 8 bit per pixel mapping 256 colours
  170 BLITCON_ACT_LINE=&08:REM draw a line
  180 BLITCON_ACT_COLLISION=&04:REM gets reset for any non-zero D data (even in EXEC_D is clear)
  190 BLITCON_ACT_WRAP=&02:REM wrap C/D addresses to fit between min/max
  200 BLITCON_EXEC_A=&01
  210 BLITCON_EXEC_B=&02
  220 BLITCON_EXEC_C=&04
  230 BLITCON_EXEC_D=&08
  240 BLITCON_EXEC_E=&10
  250 BLIT_BLITCON=&FD00
  260 BLIT_FUNCGEN=&FD01
  270 BLIT_MASK_FIRST=&FD02
  280 BLIT_MASK_LAST=&FD03
  290 BLIT_WIDTH=&FD04
  300 BLIT_HEIGHT=&FD05
  310 BLIT_SHIFT_A=&FD06
  320 BLIT_STRIDE_A=&FD08
  330 BLIT_STRIDE_B=&FD0A
  340 BLIT_STRIDE_C=&FD0C
  350 BLIT_ADDR_A=&FD10
  360 BLIT_DATA_A=&FD13
  370 BLIT_ADDR_B=&FD14
  380 BLIT_DATA_B=&FD17
  390 BLIT_ADDR_C=&FD18
  400 BLIT_DATA_C=&FD1B
  410 BLIT_ADDR_E=&FD1C
  420 PROCSELDMAC:
  430 Y%=0
  440 FOR X%=16TO28
  450   PROCBlitSprite(X%,Y%)
  460   Y%=Y%+16
  470   NEXT
  480 END
  490 :
  500 DEFPROCBlitSprite(X%,Y%):LOCAL CC%,SA%,SHX%,W%
  510 SA%=&FF3000+(X% DIV 4)*8+(Y% DIV 8)*640 + (Y% MOD 8)
  520 W%=5:WM%=3
  530 SHX%=X% MOD 4:IFSHX%<>0 THEN W%=W%+1:REM if there's a shift we need to widen the blit
  540 REM plot a non masked sprite data is read from channel B, channel C is used to read 
  550 REM existing screen data. The A channel is not executed (no mask) but the A channel
  560 REM must be initialized with &FF to not mask off data
  570 REM Sprite is placed on an arbitrary scan line within a cell using the CELL mode
  580 REM address generator
  590 ?BLIT_BLITCON=BLITCON_EXEC_A+BLITCON_EXEC_B+BLITCON_EXEC_C+BLITCON_EXEC_D: REM bitmap from B, original screen C, write screen D
  600 ?BLIT_FUNCGEN=&CA:REM (A AND B) OR (NOT A AND C)
  610 ?BLIT_WIDTH=W%-1
  620 ?BLIT_HEIGHT=15-1
  630 ?BLIT_SHIFT_A=SHX%:REM this also sets shift B
  640 REM as there may be a shift we need to mask off bits of the mask accordingly
  650 ?BLIT_MASK_FIRST=FNshr(&FF,SHX%)
  660 IF WM%<>(W%DIV2) THEN ML%=&FFF0 ELSE ML%=&FF00
  670 IF SHX%=0 THEN ?BLIT_MASK_LAST=&FF ELSE ?DMAC_MASK_LAST=FNshr(ML%,SHX%)
  680 REM poke these first in increasing order to use !
  690 !BLIT_STRIDE_A = 3
  700 !BLIT_STRIDE_B = 5
  710 ?BLIT_STRIDE_C = SCR_CHAR_ROW%: REM also sets STRIDE_D
  720 BLIT_STRIDE_C?1 = SCR_CHAR_ROW% DIV 256: REM also sets STRIDE_D
  730 !BLIT_ADDR_A = &202F3:REM BOAT
  740 !BLIT_ADDR_B = &202A8
  750 !BLIT_ADDR_C = SA%: REM also sets ADDR_D
  760 ?BLIT_BLITCON=BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_2BPP
  770 ENDPROC
  780 :
  790 DEFPROCSELDMAC:?&EE=&D1:?&FCFF=&D1:?&FCFE=&FE:?&FCFD=&FE:ENDPROC:REM Select JIM device and set page to chipset
  800 :
  810 DEFFNshr(V%,N%):LOCALI%:IFN%>0THENFORI%=1TON%:V%=V%DIV2:NEXT:=V%ELSE=V%
