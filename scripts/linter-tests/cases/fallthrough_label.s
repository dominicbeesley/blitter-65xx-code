; An untargeted label that code falls into takes the size of that code,
; not the declared size (its only branch is in a skipped .ifdef).
        .p816
        .a8
start:  sep     #$20
        lda     #1
        .ifdef  NOTSET
        beq     later
        .endif
        rep     #$20
        .a16
        nop
        .a8                     ; wrong: CPU is still 16-bit here
later:  lda     #1              ; EXPECT: error
        rts
