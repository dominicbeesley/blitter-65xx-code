    0REM >attributes type 3 test mode 4-ish with 3 bit attributes
*VNRESET
*VNVDU ON
MODE 104
*FX 9 20
*FX 10 60
DIM PAL%(16), AUXPAL%(16), NAM$(16), F%(16)
FOR I%=0TO15:F%(I%)=FALSE:NEXT
AFC$="1234QWERASDFZXCV"
FC$="7890UIOPHJKLNM,."
REM default MODE2 palette
FOR I%=0TO15:READ NAM$(I%):NEXT
FOR I%=0TO15:READ P%:PROCSETLP(P%):NEXT
REM aux palette
FOR I%=0 TO 15:READ N%:?&FE23=N%DIV256:?&FE23=N%:AUXPAL%(N% DIV &1000)=N%:NEXT
VDU 23,240,&A0,&58,&A0,&58,&A0,&58,&A0,&58
VDU 23,241,&E0,&E0,&E0,&E0,&18,&18,&18,&18
VDU 23,242,&F8,&F8,&F8,&F8,&F8,&F8,&F8,&F8
REPEAT
    READ T$
    COLOUR 3:COLOUR 128:CLS:PRINT T$
    IF T$="END" THEN END
    PRINT "      ix OR EO FP BP"
    
    REM PALETTE
    REPEAT
        READ P%
        IF P%<>-1 THEN PROCSETLP(P%)
    UNTIL P%=-1
    I%=0
    REPEAT
        READ C%
        IF C%<0 AND C%<>-1 THEN PROCPOKE(C%)
    UNTIL C%=-1
    
    FOR C%=0TO15
        PROCmycol(C%):or%=?&D2:eo%=?&D3
        VDU 241,242,&41,&42,&43
        COLOUR 3:PRINT " ";STR$~(C%);" ";FNhex(or%);" ";FNhex(eo%);" ";FNhex(PAL%(C%));" ";FNhex(PAL%(C%AND&C));" ";FNname(C%)
    NEXT C%

    
    REPEAT
    A$=GET$
        CC%=INSTR(AFC$,A$)-1
        IF CC%>=0 THEN PROCauxflash(CC%)
        CC%=INSTR(FC$,A$)-1
        IF CC%>=0 THEN PROCflash(CC%)
    UNTIL A$=" "

UNTILFALSE
DEFPROCPOKE(C%)
    ?(&FE00+((C% AND &FF00) DIV 256))=(C%AND255)
    IF (C% AND &FFE0)=&2280 THENFORI%=0TO3:F%(8+I%+((C%AND&10)DIV4))=(C%AND(2^(3-I%)))<>0:NEXT
ENDPROC
REM translate our own colour index C% to a logical colour i.e. index in PAL%
DEFFNc2l(C%)=C%
DEFFNl2n(C%,M%):LOCALP%:P%=PAL%(FNc2l(C%))AND&F
    IF F%(P%EOR7)=0 THEN =NAM$((P% AND &F)EOR7) ELSE IF M%=0 THEN =NAM$((P% AND &7)EOR8) ELSE =NAM$((P% AND &7)EOR&F)
DEFFNname(C%)
LOCALN$,N2$,FF%,FB%
REM FLASH is separate for fore/back
FF%=F%((PAL%(FNc2l(C%))AND&F)EOR7)<>0:FB%=F%((PAL%(FNc2l(C%AND&E))AND&F)EOR7)<>0
N$=FNl2n(C%,TRUE)+"/"+FNl2n(C%AND&E,TRUE)
N2$=FNl2n(C%,NOTFF%)+"/"+FNl2n(C%AND&E,NOTFB%)
IFN2$<>N$THENN$=N$+"!"+N2$
=N$
DEFPROCSETLP(P%):PAL%(P% DIV 16)=P%:?&FE21=P%:ENDPROC
DEFFNhex(A%):LOCALA$:A$="0"+STR$~A%:=MID$(A$,LEN(A$)-1,2)
DEFFNdec(A%):LOCALA$:A$="0"+STR$A%:=MID$(A$,LEN(A$)-1,2)
DEFPROCAP(C%,P%):LOCALI%:FORI%=0TO1:A%=19:CALL&FFF4:NEXT:?&FE23=C%*16 OR (P% DIV 256):?&FE23=P%:ENDPROC
DEFPROCauxflash(C%)
    LOCAL I%:FOR I%=0TO15
        PROCAP(C%, I%*&111)
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
DEFPROCmycol(A%):?&D2=(((A%AND1)=0)AND&F8)+(((A%AND8)<>0)AND&04)+(((A%AND4)<>0)AND&02)+(((A%AND2)<>0)AND&01):?&D3=(((A%AND1)=0)AND&F8):ENDPROC
REM DATA FOR NAMES
DATA "blk ", "dkbl", "dkgn", "dkcy", "dkrd", "dkmg", "brwn", "ltgy"
DATA "dkgy", "brbl", "brgn", "brcy", "brrd", "brmg", "yllw", "whit"
REM DATA FOR ULA PALETTE
DATA &F8, &E9, &DA, &CB, &BC, &AD, &9E, &8F, &70, &61, &52, &43, &34, &25, &16, &07
REM DATA FOR NULA PALETTE
DATA &0000, &100A, &20A0, &30AA, &4A00, &5A0A, &6A50, &7AAA
DATA &8555, &955F, &A5F5, &B5FF, &CF55, &DF5F, &EFF5, &FFFF
REM TEST 1
DATA "Test default palette"
DATA -1
DATA -1
DATA "Test default palette Flash"
DATA -1
DATA &FFFF228F,&FFFF229F
DATA -1
DATA "Test palette2 Flash"
DATA &09,&2E,&CF,&D8,-1:REM REMAP LOG->PHYS PALLETTE
DATA &FFFF228F,&FFFF229F
DATA -1
DATA "Test palette3 Flash"
DATA -1
DATA &FFFF2280,&FFFF229F
DATA -1
DATA "END"
