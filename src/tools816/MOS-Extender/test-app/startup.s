 zpage r0
 zpage r1
 zpage r2
 zpage r3
 global ___exit
 section DONTMERGE_text.startup
_start:
 clc
 xce
 rep #48
 a16
 lda #r0
 and #0xff00
 tcd

; TODO - we assume that the passed in stack from the MOS-Extender is sufficient

 ;lda #0xfff0
 ;tcs
 lda #0
 jsl ___main
___exit:
 lda #0
 rtl				;; TODO - OSEXIT palaver?
 section zpage,"adrwz"
r0: reserve 2
r1: reserve 2
r2: reserve 2
r3: reserve 2
r4: reserve 2
r5: reserve 2
r6: reserve 2
r7: reserve 2
r8: reserve 2
r9: reserve 2
r10: reserve 2
r11: reserve 2
r12: reserve 2
r13: reserve 2
r14: reserve 2
r15: reserve 2
r16: reserve 2
r17: reserve 2
r18: reserve 2
r19: reserve 2
r20: reserve 2
r21: reserve 2
r22: reserve 2
r23: reserve 2
r24: reserve 2
r25: reserve 2
r26: reserve 2
r27: reserve 2
r28: reserve 2
r29: reserve 2
r30: reserve 2
r31: reserve 2

 global r0
 global r1
 global r2
 global r3
 global r4
 global r5
 global r6
 global r7
 global r8
 global r9
 global r10
 global r11
 global r12
 global r13
 global r14
 global r15
 global r16
 global r17
 global r18
 global r19
 global r20
 global r21
 global r22
 global r23
 global r24
 global r25
 global r26
 global r27
 global r28
 global r29
 global r30
 global r31






