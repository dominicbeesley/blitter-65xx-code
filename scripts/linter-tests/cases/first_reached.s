; A grouped error is reported where the CPU first meets it after the
; join, not at the lowest line (helper sits above the join).
; MAX-EXAMPLES: 1
        .p816
        .a8
        .i8
        bra     start
helper: lda     #1
        rts
start:  sep     #$20
        bcc     join
        rep     #$20
join:   lda     #2              ; EXPECT: error
        jsr     helper
        rts
