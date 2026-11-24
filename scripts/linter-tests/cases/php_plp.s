; php/plp restores the sizes, so the .a16 after plp is right.
                .p816
                .a16
                .i16
start:          php
                sep     #$30
                .a8
                .i8
                lda     #1
                plp
                .a16
                .i16
                lda     #$1234
                rts
