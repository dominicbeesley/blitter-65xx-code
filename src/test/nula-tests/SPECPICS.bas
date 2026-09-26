REM >Speccy attributes test pics
*VNRESET
*VNVDU ON
MODE0
?&FE22=&62:REM SELECT SPECCY MODE
:
REPEAT
RESTORE
    REPEAT
        READ R%
        IFR%<>-1THENREADV%:VDU23,0,R%,V%,0;0;0;0;
    UNTIL R%=-1
    FOR I%=0TO15:READ  P%:?&FE23=P%DIV256:?&FE23=P%:NEXT
    REPEAT
        READ S$
        IF S$<>"END" THEN OSCLI("LOAD Z."+S$+" 3000"):A$=GET$    
    UNTIL S$="END"
UNTIL FALSE
:
DATA 1, &40:REM 1 Horizontal Displayed =64
DATA 2, &5A:REM 2 Horizontal Sync  =&5A
DATA 5, &00:REM 5 Vertial Adjust   =0
DATA 6, &18:REM 6 Vertical Displayed   =24
DATA 7, &1E:REM 7 VSync Position   =&1E
DATA -1
DATA &0000, &1C00, &20C0, &3CC0, &400C, &5C0C, &60CC, &7CCC
DATA &8000, &9F00, &A0F0, &BFF0, &C00F, &DF0F, &E0FF, &FFFF
DATA "CAT"
DATA "TC"
DATA "END"
