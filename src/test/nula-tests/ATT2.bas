REM >attributes type 2 test mode 1-ish
*VNRESET
*VNVDU ON
MODE 97
*FX 9 20
*FX 10 60
DIM PAL%(16), AUXPAL%(16)
AFC$="1234QWERASDFZXCV"
FC$="7890UIOPHJKLNM,."
REM default MODE2 palette
FOR I%=0TO15:READ P%:PAL%(P% DIV 16)=P%:?&FE21=P%:NEXT
REM aux palette
FOR I%=0 TO 15:READ N%:?&FE23=N%DIV256:?&FE23=N%:AUXPAL%(N% DIV &1000)=N%:NEXT
VDU 23,240,&A4,&48,&A4,&48,&A4,&48,&A4,&48
VDU 23,241,&E0,&E0,&E0,&E0,&0E,&0E,&0E,&0E
VDU 23,242,&EE,&EE,&EE,&EE,&EE,&EE,&EE,&EE
REPEAT
    READ T$
    COLOUR 3:COLOUR 128:CLS:PRINT T$
    IF T$="END" THEN END
    PRINT "       ix OR EOR"
    
    REM PALETTE
    REPEAT
        READ P%
        IF P%<>-1 THEN ?&FE21=P%
    UNTIL P%=-1
    I%=0
    REPEAT
        READ C%
        IF C%>=0THEN READ S$:PROCmycol(C%):or%=?&D2:eo%=?&D3:VDU 240,241,242,&41,&42,&43:COLOUR 3:PRINT " ";FNdec(I%);" ";FNhex(or%);" ";FNhex(eo%);" ";S$;" ":I%=I%+1
        IF C%<0 AND C%<>-1 THEN ?(&FE00+((C% AND &FF00) DIV 256))=(C%AND255)
    UNTIL C%=-1
    
    REPEAT
        A$=GET$
        CC%=INSTR(AFC$,A$)-1
        IF CC%>=0 THEN PROCauxflash(CC%)
        CC%=INSTR(FC$,A$)-1
        IF CC%>=0 THEN PROCflash(CC%)
    UNTIL A$=" "

UNTILFALSE
DEFFNhex(A%):LOCALA$:A$="0"+STR$~A%:=MID$(A$,LEN(A$)-1,2)
DEFFNdec(A%):LOCALA$:A$="0"+STR$A%:=MID$(A$,LEN(A$)-1,2)
DEFPROCAP(C%,P%):LOCALI%:FORI%=0TO1:A%=19:CALL&FFF4:NEXT:?&FE23=C%*16 OR (P% DIV 256):?&FE23=P%:ENDPROC
DEFPROCauxflash(C%)
    LOCAL I%:FOR I%=0TO15
        PROCP(C%, I%*&111)
        PROCAP(C%, &FFF)
        PROCAP(C%, AUXPAL%(C%))
    NEXT
ENDPROC
DEFPROCP(C%,P%):LOCALI%:FORI%=0TO1:A%=19:CALL&FFF4:NEXT:?&FE21=C%*16 OR (P% AND &0F):ENDPROC
DEFPROCflash(C%)
    LOCAL I%:FOR I%=0TO15
        PROCP(C%, I%)
        PROCP(C%, &F)
        PROCP(C%, PAL%(C%))
    NEXT
ENDPROC
REMcol maps indexes to color as expressed in bitmap in bit 1,0 then attribute in 3,2 i.e. index 0 should map to 0/0
DEFPROCmycol(A%):?&D2=(((A%AND2)=0)AND&E0)+(((A%AND1)=0)AND&0E)+(((A%AND8)<>0)AND&10)+(((A%AND4)<>0)AND&01):?&D3=(((A%AND2)=0)AND&E0)+(((A%AND1)=0)AND&0E):ENDPROC
REM DATA FOR ULA PALETTE
DATA &F8, &E9, &DA, &CB, &BC, &AD, &9E, &8F, &70, &61, &52, &43, &34, &25, &16, &07
REM DATA FOR NULA PALETTE
DATA &0000, &1007, &2070, &3077, &4700, &5707, &6770, &7777
DATA &8333, &900F, &A0F0, &B0FF, &CF00, &DF0F, &EFF0, &FFFF
REM TEST 1
DATA "Test default palette"
DATA -1
DATA 0, "Bk  /Bk  "
DATA 1 ,"Dk B/Bk  "
DATA 2 ,"Dk G/Bk  "
DATA 3 ,"Teal/Bk  "
DATA 4 ,"Dk R/Dk R"
DATA 5 ,"Ppl /Dk R"
DATA 6 ,"Gold/Dk R"
DATA 7 ,"Teal/Dk R"
DATA 8 ,"DkGy/DkGy"
DATA 9 ,"Lt B/DkGy"
DATA 10,"Lt G/DkGy"
DATA 11,"Cyan/DkGy"
DATA 12,"Lt R/Lt R"
DATA 13,"Maga/Lt R"
DATA 14,"Yelw/Lt R"
DATA 15,"Whit/Lt R"
DATA -1
DATA "Test default palette Flash"
DATA -1
DATA 0,"Navy on Teal"
DATA 1 ,"Ppl on Claret"
DATA 2 ,"Wt on Gry"
DATA 3 ,"Bt.R on Cya"
DATA 4 ,"Bt.R on Cya"
DATA 5 ,"Bt.R on Cya"
DATA 6 ,"Bt.R on Cya"
DATA 7 ,"Bt.R on Cya"
DATA 8 ,"Bt.R on Cya"
DATA 9 ,"Bt.R on Cya"
DATA 10,"Bt.R on Cya"
DATA 11,"Bt.R on Cya"
DATA 12,"Bt.R on Cya"
DATA 13,"Bt.R on Cya"
DATA 14,"Bt.R on Cya"
DATA 15,"Bt.R on Cya"
DATA &FFFF228F,&FFFF229F
DATA -1
DATA "Test palette2 Flash"
DATA &09,&2E,&CF,&D8,-1:REM REMAP LOG->PHYS PALLETTE
DATA 0,"Dk B/Yllw"
DATA 1,"Ppl /Dk R"
DATA 2,"Lt B/DkGy | Yelw/Whit"
DATA 3,"Whit/DkGy | DkGy/Cyan"
DATA &FFFF228F,&FFFF229F
DATA -1
DATA "Test palette3 Flash"
DATA -1
DATA 0,"Navy on Teal"
DATA 1 ,"Ppl on Claret"
DATA 2 ,"Wt on Gry"
DATA 3 ,"Bt.R on Cya"
DATA 4 ,"Bt.R on Cya"
DATA 5 ,"Bt.R on Cya"
DATA 6 ,"Bt.R on Cya"
DATA 7 ,"Bt.R on Cya"
DATA 8 ,"Bt.R on Cya"
DATA 9 ,"Bt.R on Cya"
DATA 10,"Bt.R on Cya"
DATA 11,"Bt.R on Cya"
DATA 12,"Bt.R on Cya"
DATA 13,"Bt.R on Cya"
DATA 14,"Bt.R on Cya"
DATA 15,"Bt.R on Cya"
DATA &FFFF2280,&FFFF229F
DATA -1
DATA "END"
