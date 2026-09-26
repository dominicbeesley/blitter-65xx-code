REM > make a Thomson MO5 test card
DIM BK% 20
*VNRESET
*VNVDU ON
MODE0
ON ERROR:?&FE22=&60:REPORT:P. "at "; ERL:STOP
?&FE22=&63:REM SELECT THOMSON MODE
:
RESTORE
REPEAT
    READ R%
    IFR%<>-1THENREADV%:VDU23,0,R%,V%,0;0;0;0;
UNTIL R%=-1
FOR I%=0TO15:READ  P%:?&FE23=P%DIV256:?&FE23=P%:NEXT

FOR F%=0TO15
    FOR B%=0TO15
        C%=(F%AND7)+8*(F%AND8)+8*(B%AND7)+16*(B%AND8)
        PROCprint(F%*2,B%,C%,(STR$~B%)+(STR$~F%))
    NEXT
NEXT
*FX9
A$=GET$
*FX9,100

:
END
:
DEFFNaddr(X%,Y%)=&3000+(X%+Y%*32)*16
DEFPROCprint(X%,Y%,C%,S$)
LOCAL I%,J%,A%,P%:P%=FNaddr(X%,Y%)
FORI%=1TOLEN(S$)
    BK%?0=ASC(MID$(S$,I%,1))
    A%=&A:X%=BK%:Y%=BK%DIV256:CALL&FFF1
    FOR J%=1TO8
        P%?(J%+7)=BK%?J%
    NEXT
    FOR J%=0TO7
        P%?J%=C%
    NEXT
    P%=P%+16
NEXT
ENDPROC
:
DATA 1, &40:REM 1 Horizontal Displayed =64
DATA 2, &5A:REM 2 Horizontal Sync  =&5A
DATA 5, &00:REM 5 Vertial Adjust   =0
DATA 6, &18:REM 6 Vertical Displayed   =24
DATA 7, &1E:REM 7 VSync Position   =&1E
DATA -1
DATA &0000, &1F66, &20F0, &3FF0, &466F, &5F6F, &66FF, &7FFF
DATA &8888, &9F88, &A8F8, &BFF8, &C68F, &DF8F, &E8FF, &FF86
: