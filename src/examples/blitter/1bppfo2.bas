   10REM >1BPPFO2 An example of blitting a solid colour through 1bpp mask to an 
   20REM arbitrary screen address. The screen adddress is not aligned to a cell
   30REM vertically but is horizontally
   40MODE 1:BPP%=2:SCRX%=320:SCRY%=256
   50SCR_CHAR_ROW%=SCRX%*BPP%
   60REM BLTCON is written in two passes with top bit clear i.e. not BLTCON_ACT_ACT
   70REM the exec flags are first set
   80REM then with top bit set the active flag, bit mode and cell flags are set
   90REM BLTCON/ACT byte flags
  100BLITCON_ACT_ACT=&80:REM always set when setting act constants/execing  
  110BLITCON_ACT_CELL=&40:REM cell addressing used i.e. move one byte left adds 8 to address moving one line down either adds 1 byte or STRIDE depending on whether line crosses an 8 line boundary
  120BLITCON_ACT_MODE_1BPP=&00:REM 1 bit per pixel mapping 2 colours
  130BLITCON_ACT_MODE_2BPP=&10:REM 2 bit per pixel mapping 4 colours
  140BLITCON_ACT_MODE_4BPP=&20:REM 4 bit per pixel mapping 16 colours
  150BLITCON_ACT_MODE_8BPP=&30:REM 8 bit per pixel mapping 256 colours
  160BLITCON_ACT_LINE=&08:REM draw a line
  170BLITCON_ACT_COLLISION=&04:REM gets reset for any non-zero D data (even in EXEC_D is clear)
  180BLITCON_ACT_WRAP=&02:REM wrap C/D addresses to fit between min/max
  190BLITCON_EXEC_A=&01
  200BLITCON_EXEC_B=&02
  210BLITCON_EXEC_C=&04
  220BLITCON_EXEC_D=&08
  230BLITCON_EXEC_E=&10
  240BLIT_BLITCON=&FD00
  250BLIT_FUNCGEN=&FD01
  260BLIT_MASK_FIRST=&FD02
  270BLIT_MASK_LAST=&FD03
  280BLIT_WIDTH=&FD04
  290BLIT_HEIGHT=&FD05
  300BLIT_SHIFT_A=&FD06
  310BLIT_STRIDE_A=&FD08
  320BLIT_STRIDE_B=&FD0A
  330BLIT_STRIDE_C=&FD0C
  340BLIT_ADDR_A=&FD10
  350BLIT_DATA_A=&FD13
  360BLIT_ADDR_B=&FD14
  370BLIT_DATA_B=&FD17
  380BLIT_ADDR_C=&FD18
  390BLIT_DATA_C=&FD1B
  400BLIT_ADDR_E=&FD1C
  410PROCSELDMAC:REM page the Blitter hardware into JIM
  420REPEAT:
  430PROCBlitCharCell(32+RND(50),RND(4)-1,RND(312)-1, RND(240)-1)
  440UNTILFALSE
  450:
  460DEFPROCBlitCharCell(A%,C%,X%,Y%):LOCAL CC%,SA%
  470CC%=(C% AND 2)*&78 + (C% AND 1)*&0F:REM make screen colour
  480SA%=&FF3000+(X% DIV 4)*8+(Y% DIV 8)*640 + (Y% MOD 8)
  490REM plot a solid colour through a mask read from the font data in MOS ROM at 
  500REM FF C000 the character is aligned to a cell horizontally (not shifted) but 
  510REM is placed on an arbitrary scan line within a cell using the CELL mode
  520REM address generator
  530?BLIT_BLITCON=BLITCON_EXEC_A+BLITCON_EXEC_C+BLITCON_EXEC_D: REM mask from A, original screen C, write screen D
  540?BLIT_FUNCGEN=&CA:REM (A AND B) OR (NOT A AND C)
  550?BLIT_WIDTH=1
  560?BLIT_HEIGHT=7
  570?BLIT_SHIFT_A=0
  580?BLIT_MASK_FIRST=&FF
  590?BLIT_MASK_LAST=&FF
  600!BLIT_ADDR_A = &FFC000 + (A%-32)*8
  610?BLIT_DATA_B=CC%
  620!BLIT_ADDR_C = SA%
  630!BLIT_STRIDE_A = 1
  640!BLIT_STRIDE_C = SCR_CHAR_ROW%: REM also sets STRIDE_D
  650?BLIT_BLITCON=BLITCON_ACT_ACT+BLITCON_ACT_CELL+BLITCON_ACT_MODE_2BPP
  660ENDPROC
  670:
  680DEFPROCSELDMAC:?&EE=&D1:?&FCFF=&D1:?&FCFE=&FE:?&FCFD=&FE:ENDPROC:REM Select JIM device and set page to chipset
