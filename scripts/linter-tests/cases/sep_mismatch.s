; sep without the matching .a8: immediate assembled 16-bit, CPU 8-bit.
                .p816
                .a16
                .i16
start:          sep     #$20
                lda     #1                      ; EXPECT: error
                ldx     #2
                rts
