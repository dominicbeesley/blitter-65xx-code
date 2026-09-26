    0REM >test card grey scale / colour composite
    1MODE 2:?&FE22=&40
    3X%=0
    4FOR I%=0TO15:
    5    GCOL 0,I%
    6    XX%=X%+80
    7    MOVE X%,0:MOVE X%,1024:PLOT 85,XX%,1024:MOVE XX%,0:PLOT 85,X%,0
    8    X%=XX%
    9NEXT
   11REM GREYSCALE
   12FOR I%=0TO15:
   13    ?&FE23=I%+16*I%:?&FE23=I%+16*I%
   14NEXT
   16A$=GET$
   18REM PAL
   19FOR I%=0TO15:
   20    B%=((I%AND2)<>0)AND&0F
   21    G%=((I%AND8)<>0)AND&F0
   22    R%=((I%AND4)<>0)AND&0F
   23    IF I%AND1 THEN R%=R%AND7:G%=G%AND&70:B%=B%AND7
   24    ?&FE23=R%+16*I%:?&FE23=G%ORB%
   25NEXT
