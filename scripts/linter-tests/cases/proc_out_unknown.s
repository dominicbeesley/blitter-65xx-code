; ;.out a? : the caller must set the size before using it.
                .p816
                .a16
                .proc   messy                   ;.out a?
                rts
                .endproc
start:          jsr     messy
                lda     #1                      ; EXPECT: warning
                rep     #$20
                lda     #$1234
                rts
