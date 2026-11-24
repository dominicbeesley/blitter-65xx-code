; rep with a non-constant operand: sizes unknown.
                .p816
                .a16
MASK = $20
start:          rep     #MASK
                lda     #1                      ; EXPECT: warning
                rts
