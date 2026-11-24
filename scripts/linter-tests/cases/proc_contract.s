; jsr to a proc with ;.in / ;.out contracts.
                .p816
                .a16
                .i16
                .proc   needs8                  ;.in a8 ;.out a16
                rep     #$20
                rts
                .endproc

start:          jsr     needs8                  ; EXPECT: error
                lda     #$1234
                sep     #$20
                .a8
                jsr     needs8
                .a16
                lda     #$1234
                rts
