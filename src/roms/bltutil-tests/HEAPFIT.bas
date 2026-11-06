   10 REM HEAPFIT - tests of the OSWORD &99 heap: best-fit allocation,
   20 REM and that freeing everything gives back all the space
   30 REM Press BREAK first: the heap is cleared on every break
   35 MODE 7
   40 DIM B% 20,blk%(4),name$(4),res$(10)
   50 name$(1)="got":name$(2)="guard1":name$(3)="guard2":name$(4)="guard3"
   60 fails%=0:nres%=0:pass%=0
   70 PROCheapstate:startfree%=free%:startused%=used%
   80 PRINT "At start: ";startfree%;" pages free, ";startused%;" blocks in use"
   90 :
  100 REM Pass 1 frees got, guard1, guard2, guard3: each free merges
  110 REM with the hole above it, and below it for guard1/guard2
  120 PROCpass("1234")
  130 REM Pass 2 frees guard2, got, guard3, guard1: freeing got merges
  140 REM with holes above and below in one call, and the last two
  150 REM frees each hand space back to the heap bottom
  160 PROCpass("3142")
  170 :
  175 PRINT '"Summary:":FOR I%=1 TO nres%:PRINT res$(I%):NEXT
  180 IF fails%=0 THEN PRINT "ALL PASSED" ELSE PRINT fails%;" FAILED"
  190 END
  200 :
  210 REM One pass: make holes, test best fit, free all in order$,
  220 REM then check the heap is back as it was at the start
  230 DEF PROCpass(order$):LOCAL hole8%,hole2%,hole4%,got%,I%
  235 pass%=pass%+1
  240 PRINT '"Pass ";pass%;", freeing in order:";
  250 FOR I%=1 TO 4:PRINT " ";name$(VAL MID$(order$,I%,1));:NEXT:PRINT
  260 REM Set up: three free holes of 8, 2 and 4 pages, with a used
  270 REM 1-page guard after each so the holes cannot merge
  280 hole8%=FNalloc(8):blk%(2)=FNalloc(1)
  290 hole2%=FNalloc(2):blk%(3)=FNalloc(1)
  300 hole4%=FNalloc(4):blk%(4)=FNalloc(1)
  310 PROCfree(hole8%):PROCfree(hole2%):PROCfree(hole4%)
  320 PRINT "Holes: 8 pages at &";~hole8%;", 2 at &";~hole2%;", 4 at &";~hole4%
  330 REM Test: 1 page fits all three holes, but should come from the
  340 REM smallest (the 2-page hole). Bug: first or last hole is used.
  350 got%=FNalloc(1):blk%(1)=got%
  360 PRINT "1 page allocated at &";~got%;
  370 IF got%=hole8% THEN PRINT " (8-page hole)"
  380 IF got%=hole2% THEN PRINT " (2-page hole)"
  390 IF got%=hole4% THEN PRINT " (4-page hole)"
  400 IF got%<>hole2% AND got%<>hole8% AND got%<>hole4% THEN PRINT " (not a hole)"
  410 PROCresult(got%=hole2%,"pass "+STR$pass%+" best fit")
  420 *BLHINF V
  430 REM Free the four used blocks in the order given
  440 FOR I%=1 TO 4:PROCfree(blk%(VAL MID$(order$,I%,1))):NEXT
  450 REM Test: same free space and blocks in use as at the start
  460 PROCheapstate
  470 PRINT "After freeing: ";free%;" pages free, ";used%;" blocks in use"
  480 PROCresult(free%=startfree% AND used%=startused%,"pass "+STR$pass%+" all space returned")
  490 ENDPROC
  500 :
  502 REM Print a result now and keep it for the summary at the end
  505 REM Teletext: CHR$130 green, CHR$129 red, CHR$135 back to white
  510 DEF PROCresult(ok%,test$):LOCAL r$
  515 IF ok% THEN r$=CHR$130+"PASS"+CHR$135+test$ ELSE r$=CHR$129+"FAIL"+CHR$135+test$:fails%=fails%+1
  520 PRINT r$:nres%=nres%+1:res$(nres%)=r$
  530 ENDPROC
  540 :
 1000 REM OSWORD &99 op &10: allocate pages% pages of ChipRAM
 1010 REM Returns the first page number; stops on failure
 1020 DEF FNalloc(pages%):LOCAL page%
 1030 B%?2=&10:B%?3=pages%:B%?4=pages% DIV 256:PROCosword99
 1040 page%=B%?3+256*B%?4
 1050 IF page%>=&FF00 THEN PRINT "Alloc of ";pages%;" pages failed, code ";B%?3:END
 1060 =page%
 1070 :
 1080 REM OSWORD &99 op &11: free the block starting at page%
 1090 DEF PROCfree(page%)
 1100 B%?2=&11:B%?3=page%:B%?4=page% DIV 256:PROCosword99
 1110 ENDPROC
 1120 :
 1130 REM Call OSWORD &99 with the block at B% (5 bytes in, 5 out)
 1140 DEF PROCosword99:LOCAL A%,X%,Y%
 1150 A%=&99:X%=B%:Y%=B% DIV 256:B%?0=5:B%?1=5
 1160 CALL &FFF1
 1170 ENDPROC
 1180 :
 1190 REM Sets free% (pages free, as *BLHINF "Total free") and used%
 1200 REM (blocks in use). There is no API for this yet, so it reads
 1210 REM BLTUTIL's heap workspace (ChipRAM page &0080) through JIM:
 1220 REM +4 HEAPTOP, +6 HEAPBOT, +8 HEAPLIM; the allocation table is
 1230 REM the page below HEAPTOP, 64 entries of base(2), flags+len(2)
 1240 DEF PROCheapstate:LOCAL tbl%,E%,f%
 1250 tbl%=FNjim16(&80,4)-1
 1260 free%=FNjim16(&80,6)-FNjim16(&80,8):used%=0
 1270 FOR E%=0 TO 252 STEP 4
 1280 f%=FNjim(tbl%,E%+3)
 1290 IF (f% AND &C0)=&C0 THEN free%=free%+FNjim(tbl%,E%+2)+256*(f% AND &3F)
 1300 IF (f% AND &C0)=&80 THEN used%=used%+1
 1310 NEXT
 1320 ENDPROC
 1330 :
 1340 REM Read byte off% of ChipRAM page page% through JIM (Blitter &D1)
 1350 DEF FNjim(page%,off%)
 1360 ?&EE=&D1:?&FCFF=&D1:?&FCFD=page% DIV 256:?&FCFE=page% AND 255
 1370 =?(&FD00+off%)
 1380 DEF FNjim16(page%,off%)=FNjim(page%,off%)+256*FNjim(page%,off%+1)
