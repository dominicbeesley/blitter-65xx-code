    0REM >SCRTES2 move left/right with 
    1REM z/x as the screen scrolls the 
    2REM point near the bottom should
    3REM appear to be stationary
    4MODE 4
    5PRINT "PRESS Z <> X to scroll"
    6S%=0
    7NS%=0
    8GCOL 3,7
    9PROCplot
   10REPEAT
   11A$=INKEY$(10)
   12IF (A$="X" OR A$="x") AND S%<7THENNS%=S%+1
   13IF (A$="Z" OR A$="z") AND S%>0THENNS%=S%-1
   14*FX19
   15?&FE22=NS%OR&20:PROCplot:S%=NS%:PROCplot
   16UNTILFALSE
   17DEFPROCplot:PLOT &45,100-S%*4,100:ENDPROC
