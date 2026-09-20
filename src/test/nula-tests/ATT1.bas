    0REM >attributes type 1 test
*VNRESET
*VNVDU ON
MODE 99
REM default MODE2 palette
FOR I%=0TO15:READ P%:?&FE21=P%:NEXT
REM aux palette
FOR I%=0 TO 15:READ N%:?&FE23=N%DIV256:?&FE23=N%:NEXT
VDU 23,240,&A4,&58,&A4,&58,&A4,&58,&A4,&58
VDU 23,241,&F0,&F0,&F0,&F0,&F0,&F0,&F0,&F0
VDU 23,242,&FC,&FC,&FC,&FC,&FC,&FC,&FC,&FC
REPEAT
    READ T$
    COLOUR 3:COLOUR 128:CLS:PRINT T$
    IF T$="END" THEN END
    
    REM PALETTE
    REPEAT
        READ P%
        IF P%<>-1 THEN ?&FE21=P%
    UNTIL P%=-1
    I%=0
    REPEAT
        READ C%
        IF C%>=0THEN READ S$:PROCmycol(C%):VDU 240,241,242,&41,&42,&43:COLOUR 3:PRINT " ";I%; " "; S$:I%=I%+1
        IF C%<0 AND C%<>-1 THEN ?(&FE00+((C% AND &FF00) DIV 256))=(C%AND255)
    UNTIL C%=-1
    
    A$=GET$
UNTILFALSE
DEFPROCmycol(A%):?&D2=0:?&D3=A%AND3:ENDPROC
REM DATA FOR ULA PALETTE
DATA &F8, &E9, &DA, &CB, &BC, &AD, &9E, &8F, &70, &61, &52, &43, &34, &25, &16, &07
REM DATA FOR NULA PALETTE
DATA &0036, &1007, &2070, &3077, &4700, &5707, &6770, &7777
DATA &8333, &9FFF, &A00F, &B0F0, &C0FF, &DF00, &EF0F, &FFF0
REM TEST 1
DATA "Test default palette"
DATA -1
DATA 0,"Navy on Teal"
DATA 1,"Ppl on Claret"
DATA 2,"Wt on Gry"
DATA 3,"Bt.R on Cya"
DATA -1
DATA "Test default palette Flash"
DATA -1
DATA 0,"Navy on Teal"
DATA 1,"Ppl on Claret"
DATA 2,"Wt on Gry / Pk on Y"
DATA 3,"Bt.R on Cya / Bt.B on Bt.G"
DATA &FFFF228F,&FFFF229F
DATA -1
DATA "Test palette2 Flash"
DATA &09,&2E,&CF,&D8,-1
DATA 0,"Navy on Pink"
DATA 1,"Ppl on Claret"
DATA 2,"Wt on Gry / Pk on Y"
DATA 3,"Y on Gry / Gry on Y"
DATA &FFFF228F,&FFFF229F
DATA -1
DATA "Test palette3 Flash"
DATA &09,&2E,&CF,&D8,-1
DATA 0,"Navy on Pink"
DATA 1,"Ppl on Claret"
DATA 2,"Wt on Gry / Pk on Y"
DATA 3,"Y on Gry / Gry on Y"
DATA &FFFF2280,&FFFF229F
DATA -1
DATA "END"
