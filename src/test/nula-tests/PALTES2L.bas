    0REM >test palette flash and phys colour 
    1REM mapping to nula palette
    2MODE 1:?&FE22=&40:?&FE22=&11
    3FOR I%=0 TO 15:READ N%:?&FE23=N%DIV256:?&FE23=N%:NEXT
    4:
    5REPEAT
    6    READ T$
    7    COLOUR 3:COLOUR 128:CLS:PRINT T$:VDU 20
    8    IF T$="END" THEN END
    9    
   10    REM PALETTE
   11    REPEAT
   12        READ P%
   13        IF P%<>-1 THEN ?&FE21=P%
   14    UNTIL P%=-1
   16    REPEAT
   17        READ C%
   18        IF C%>=0THEN READ B%,S$:COLOUR C%:COLOUR B%:PRINT S$
   19        IF C%<0 AND C%<>-1 THEN ?(&FE00+((C% AND &FF00) DIV 256))=(C%AND255)
   20    UNTIL C%=-1
   21    
   22    A$=GET$
   23UNTILFALSE
   25:
   26END
   27:
   29REM DATA FOR NULA PALETTE
   30DATA &0036, &1007, &2070, &3077, &4700, &5707, &6770, &7777
   31DATA &8333, &900F, &A0F0, &B0FF, &CF00, &DF0F, &EFF0, &FFFF
   33REM TEST 1
   34DATA "Test default palette"
   35DATA -1
   36DATA 0,129,"Teal on Navy"
   37DATA 1,128,"Navy on Teal"
   38DATA 2,131,"Dk.G on Dk. Cyan"
   39DATA -1
   41DATA "Test high palette palette"
   42DATA &A8,&B8,&E8,&F8,&8C,&9C,&CC,&DC,&2E,&3E,&6E,&7E,&0F,&1F,&4F,&5F,-1
   43DATA 0,129,"Teal on Navy"
   44DATA 1,128,"Navy on Teal"
   45DATA 2,131,"Dk.G on Dk. Cyan"
   46DATA -1
   48DATA "Test high palette Flash"
   49DATA &A8,&B8,&E8,&F8,&8C,&9C,&CC,&DC,&2E,&3E,&6E,&7E,&0F,&1F,&4F,&5F,-1
   50DATA 0,129,"Teal on Navy"
   51DATA 1,128,"Navy on Teal"
   52DATA 2,131,"Dk.G on Dk. Cyan"
   53DATA &FFFF228F,&FFFF229F
   54DATA -1
   56DATA "Test high palette Flash 2"
   57DATA &A8,&B8,&E8,&F8,&8C,&9C,&CC,&DC,&2E,&3E,&6E,&7E,&0F,&1F,&4F,&5F,-1
   58DATA 0,129,"Teal on Navy"
   59DATA 1,128,"Navy on Teal"
   60DATA 2,131,"Dk.G on Dk. Cyan"
   61DATA &FFFF23F0,&FFFF2300
   62DATA &FFFF2380,&FFFF2300
   63DATA -1
   66DATA "END"
