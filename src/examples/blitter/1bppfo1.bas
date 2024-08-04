   10 REM >1BPPFONT An example of blitting a solid colour through 1bpp mask to an 
   20 REM arbitrary character cell aligned screen address
   30 MODE 1:BPP%=2:SCRX%=320:SCRY%=256
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
  400 PROCSELDMAC:REM page the Blitter hardware into JIM
  410 REPEAT:
  420   PROCBlitCharCell(32+RND(50),RND(4)-1,RND(40)-1, RND(30)-1)
  430   UNTILFALSE
  440 :
  450 DEFPROCBlitCharCell(A%,C%,X%,Y%):LOCAL CC%,SA%
  460 CC%=(C% AND 2)*&78 + (C% AND 1)*&0F:REM make screen colour
  470 SA%=&FF3000+X%*16+Y%*640
  480 REM plot a solid colour through a mask read from the font data in MOS ROM at FF C000
  490 REM the character is aligned to a cell (not shifted)
  500 ?BLIT_BLITCON=BLITCON_EXEC_A+BLITCON_EXEC_C+BLITCON_EXEC_D: REM mask from A, original screen C, write screen D
  510 ?BLIT_FUNCGEN=&CA:REM (A AND B) OR (NOT A AND C)
  520 ?BLIT_WIDTH=1
  530 ?BLIT_HEIGHT=7
  540 ?BLIT_SHIFT_A=0
  550 ?BLIT_MASK_FIRST=&FF
  560 ?BLIT_MASK_LAST=&FF
  570 !BLIT_ADDR_A = &FFC000 + (A%-32)*8
  580 ?BLIT_DATA_B=CC%
  590 !BLIT_ADDR_C = SA%
  600 !BLIT_STRIDE_A = 1
  610 ?BLIT_STRIDE_C = SCR_CHAR_ROW%: REM also sets STRIDE_D
  620 BLIT_STRIDE_C?1 = SCR_CHAR_ROW% DIV 256: REM also sets STRIDE_D
  630 ?BLIT_BLITCON=BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_2BPP
  640 ENDPROC
  650 :
  660 DEFPROCSELDMAC:?&EE=&D1:?&FCFF=&D1:?&FCFE=&FE:?&FCFD=&FE:ENDPROC:REM Select JIM device and set page to chipset
