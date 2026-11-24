; X is 8-bit after sep #$10 but the file says .i16.
                .p816
                .a16
                .i16
start:          sep     #$10
                ldx     #0                      ; EXPECT: error
                cpy     #3                      ; same .i16: grouped with the ldx
                lda     #$1234
                rts
