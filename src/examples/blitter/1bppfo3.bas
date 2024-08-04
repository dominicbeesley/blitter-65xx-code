   10 REM >1BPPFO3 A BASIC example of 1BPP blits with horizontal and vertical shifts
   20 MODE 1:BPP%=2:SCRX%=320:SCRY%=256
   30 SCR_CHAR_ROW%=SCRX%*BPP%
   40 REM BLTCON is written in two passes with top bit clear i.e. not BLTCON_ACT_ACT
   50 REM the exec flags are first set
   60 REM then with top bit set the active flag, bit mode and cell flags are set
   70 REM BLTCON/ACT byte flags
   80 BLITCON_ACT_ACT=&80:REM always set when setting act constants/execing  
   90 BLITCON_ACT_CELL=&40:REM cell addressing used i.e. move one byte left adds 8 to address moving one line down either adds 1 byte or STRIDE depending on whether line crosses an 8 line boundary
  100 BLITCON_ACT_MODE_1BPP=&00:REM 1 bit per pixel mapping 2 colours
  110 BLITCON_ACT_MODE_2BPP=&10:REM 2 bit per pixel mapping 4 colours
  120 BLITCON_ACT_MODE_4BPP=&20:REM 4 bit per pixel mapping 16 colours
  130 BLITCON_ACT_MODE_8BPP=&30:REM 8 bit per pixel mapping 256 colours
  140 BLITCON_ACT_LINE=&08:REM draw a line
  150 BLITCON_ACT_COLLISION=&04:REM gets reset for any non-zero D data (even in EXEC_D is clear)
  160 BLITCON_ACT_WRAP=&02:REM wrap C/D addresses to fit between min/max
  170 BLITCON_EXEC_A=&01
  180 BLITCON_EXEC_B=&02
  190 BLITCON_EXEC_C=&04
  200 BLITCON_EXEC_D=&08
  210 BLITCON_EXEC_E=&10
  220 BLIT_BLITCON=&FD00
  230 BLIT_FUNCGEN=&FD01
  240 BLIT_MASK_FIRST=&FD02
  250 BLIT_MASK_LAST=&FD03
  260 BLIT_WIDTH=&FD04
  270 BLIT_HEIGHT=&FD05
  280 BLIT_SHIFT_A=&FD06
  290 BLIT_STRIDE_A=&FD08
  300 BLIT_STRIDE_B=&FD0A
  310 BLIT_STRIDE_C=&FD0C
  320 BLIT_ADDR_A=&FD10
  330 BLIT_DATA_A=&FD13
  340 BLIT_ADDR_B=&FD14
  350 BLIT_DATA_B=&FD17
  360 BLIT_ADDR_C=&FD18
  370 BLIT_DATA_C=&FD1B
  380 BLIT_ADDR_E=&FD1C
  390 PROCSELDMAC:
  400 REPEAT:*FX19
  410   PROCBlitCharCell(32+RND(50),RND(4)-1,RND(312)-1, RND(240)-1)
  420   UNTILFALSE
  430 :
  440 DEFPROCBlitCharCell(A%,C%,X%,Y%):LOCAL CC%,SA%,SHX%,W%
  450 CC%=(C% AND 2)*&78 + (C% AND 1)*&0F:REM make screen colour
  460 SA%=&FF3000+(X% DIV 4)*8+(Y% DIV 8)*640 + (Y% MOD 8)
  470 W%=1
  480 SHX%=X% MOD 4:IFSHX%<>0 THEN W%=W%+1:REM if there's a shift we need to widen the blit
  490 REM plot a solid colour through a mask read from the font data in MOS ROM at 
  500 REM FF C000 the character is aligned to a cell horizontally (not shifted) but 
  510 REM is placed on an arbitrary scan line within a cell using the CELL mode
  520 REM address generator
  530 ?BLIT_BLITCON=BLITCON_EXEC_A+BLITCON_EXEC_C+BLITCON_EXEC_D: REM mask from A, original screen C, write screen D
  540 ?BLIT_FUNCGEN=&CA:REM (A AND B) OR (NOT A AND C)
  550 ?BLIT_WIDTH=W%
  560 ?BLIT_HEIGHT=7
  570 ?BLIT_SHIFT_A=SHX%
  580 REM as there may be a shift we need to mask off bits of the mask accordingly
  590 ?BLIT_MASK_FIRST=FNshr(&FF,SHX%)
  600 ?BLIT_MASK_LAST=FNshr(&FF00,SHX%)
  610 !BLIT_ADDR_A = &FFC000 + (A%-32)*8
  620 ?BLIT_DATA_B=CC%
  630 !BLIT_ADDR_C = SA%
  640 !BLIT_STRIDE_A = 1
  650 ?BLIT_STRIDE_C = SCR_CHAR_ROW%: REM also sets STRIDE_D
  660 BLIT_STRIDE_C?1 = SCR_CHAR_ROW% DIV 256: REM also sets STRIDE_D
  670 ?BLIT_BLITCON=BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_2BPP
  680 ENDPROC
  690 :
  700 DEFPROCSELDMAC:?&EE=&D1:?&FCFF=&D1:?&FCFE=&FE:?&FCFD=&FE:ENDPROC:REM Select JIM device and set page to chipset
  710 :
  720 DEFFNshr(V%,N%):LOCALI%:FORI%=1TON%:V%=V%DIV2:NEXT:=V%
