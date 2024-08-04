   10 REM >1BPPFO3 A BASIC example of 1BPP blits with horizontal and vertical shifts
   20 *XMLOAD S.ISHSPR #D1 20000
   30 MODE 1:BPP%=2:SCRX%=320:SCRY%=256:COLOUR 129:CLS:FORI%=0TO100:DRAW RND(320),RND(1024):GCOL0,RND(4):NEXT
   40 SCR_CHAR_ROW%=SCRX%*BPP%
   50 REM BLTCON is written in two passes with top bit clear i.e. not BLTCON_ACT_ACT
   60 REM the exec flags are first set
   70 REM then with top bit set the active flag, bit mode and cell flags are set
   80 REM BLTCON/ACT byte flags
   90 BLITCON_ACT_ACT=&80:REM always set when setting act constants/execing  
  100 BLITCON_ACT_CELL=&40:REM cell addressing used i.e. move one byte left adds 8 to address moving one line down either adds 1 byte or STRIDE depending on whether line crosses an 8 line boundary
  110 BLITCON_ACT_MODE_1BPP=&00:REM 1 bit per pixel mapping 2 colours
  120 BLITCON_ACT_MODE_2BPP=&10:REM 2 bit per pixel mapping 4 colours
  130 BLITCON_ACT_MODE_4BPP=&20:REM 4 bit per pixel mapping 16 colours
  140 BLITCON_ACT_MODE_8BPP=&30:REM 8 bit per pixel mapping 256 colours
  150 BLITCON_ACT_LINE=&08:REM draw a line
  160 BLITCON_ACT_COLLISION=&04:REM gets reset for any non-zero D data (even in EXEC_D is clear)
  170 BLITCON_ACT_WRAP=&02:REM wrap C/D addresses to fit between min/max
  180 BLITCON_EXEC_A=&01
  190 BLITCON_EXEC_B=&02
  200 BLITCON_EXEC_C=&04
  210 BLITCON_EXEC_D=&08
  220 BLITCON_EXEC_E=&10
  230 BLIT_BLITCON=&FD00
  240 BLIT_FUNCGEN=&FD01
  250 BLIT_MASK_FIRST=&FD02
  260 BLIT_MASK_LAST=&FD03
  270 BLIT_WIDTH=&FD04
  280 BLIT_HEIGHT=&FD05
  290 BLIT_SHIFT_A=&FD06
  300 BLIT_STRIDE_A=&FD08
  310 BLIT_STRIDE_B=&FD0A
  320 BLIT_STRIDE_C=&FD0C
  330 BLIT_ADDR_A=&FD10
  340 BLIT_DATA_A=&FD13
  350 BLIT_ADDR_B=&FD14
  360 BLIT_DATA_B=&FD17
  370 BLIT_ADDR_C=&FD18
  380 BLIT_DATA_C=&FD1B
  390 BLIT_ADDR_E=&FD1C
  400 PROCSELDMAC:
  410 Y%=0
  420 FOR A%=0TO2:FOR X%=16TO19
  430     PROCBlitSprite(A%,X%,Y%)
  440     Y%=Y%+14
  450     NEXT:NEXT
  460 END
  470 :
  480 DEFPROCBlitSprite(A%,X%,Y%):LOCAL CC%,SA%,SHX%,W%
  490 SA%=&FF3000+(X% DIV 4)*8+(Y% DIV 8)*640 + (Y% MOD 8)
  500 W%=4
  510 SHX%=X% MOD 4:IFSHX%<>0 THEN W%=W%+1:REM if there's a shift we need to widen the blit
  520 REM plot a non masked sprite data is read from channel B, channel C is used to read 
  530 REM existing screen data. The A channel is not executed (no mask) but the A channel
  540 REM must be initialized with &FF to not mask off data
  550 REM Sprite is placed on an arbitrary scan line within a cell using the CELL mode
  560 REM address generator
  570 ?BLIT_BLITCON=BLITCON_EXEC_B+BLITCON_EXEC_C+BLITCON_EXEC_D: REM bitmap from B, original screen C, write screen D
  580 ?BLIT_FUNCGEN=&CA:REM (A AND B) OR (NOT A AND C)
  590 ?BLIT_WIDTH=W%-1
  600 ?BLIT_HEIGHT=12-1
  610 ?BLIT_SHIFT_A=SHX%
  620 REM as there may be a shift we need to mask off bits of the mask accordingly
  630 ?BLIT_MASK_FIRST=FNshr(&FF,SHX%)
  640 IF SHX%=0 THEN ?BLIT_MASK_LAST=&FF ELSE ?DMAC_MASK_LAST=FNshr(&FF00,SHX%)
  650 ?BLIT_DATA_A=&FF
  660 !BLIT_ADDR_B = &20000 + (A% MOD 3) * &48
  670 !BLIT_ADDR_C = SA%
  680 !BLIT_STRIDE_B = 4
  690 ?BLIT_STRIDE_C = SCR_CHAR_ROW%: REM also sets STRIDE_D
  700 BLIT_STRIDE_C?1 = SCR_CHAR_ROW% DIV 256: REM also sets STRIDE_D
  710 ?BLIT_BLITCON=BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_2BPP
  720 ENDPROC
  730 :
  740 DEFPROCSELDMAC:?&EE=&D1:?&FCFF=&D1:?&FCFE=&FE:?&FCFD=&FE:ENDPROC:REM Select JIM device and set page to chipset
  750 :
  760 DEFFNshr(V%,N%):LOCALI%:IFN%>0THENFORI%=1TON%:V%=V%DIV2:NEXT:=V%ELSE=V%
