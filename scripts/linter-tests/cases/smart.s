; Under .smart, ca65 follows rep/sep itself: no .a16 needed.
                .p816
                .smart
                .a8
                .i8
start:          rep     #$30
                lda     #$1234
                ldx     #$1234
                sep     #$20
                lda     #1
                rts
