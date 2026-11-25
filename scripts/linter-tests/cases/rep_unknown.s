; rep with a non-constant operand: sizes unknown.
                .p816
                .a16
                .importzp MASK          ; value unknown here
start:          rep     #MASK
                lda     #1                      ; EXPECT: warning
                rts
