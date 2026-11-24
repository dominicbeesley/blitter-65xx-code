; A macro that needs 16-bit A, called with 8-bit A.
                .p816
                .macro  NEEDS16                 ;.in a16
                lda     #$1234
                .endmacro
                .a8
start:          NEEDS16                         ; EXPECT: error
                rep     #$20
                .a16
                NEEDS16
                rts
