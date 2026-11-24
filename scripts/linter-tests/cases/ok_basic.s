; Consistent sizes: rep/sep matched by .a16/.a8 etc. No messages.
                .p816
                .a8
                .i8
start:          lda     #1
                rep     #$30
                .a16
                .i16
                lda     #$1234
                ldx     #$1234
                sep     #$20
                .a8
                lda     #1
                ldy     #$1234
                rts
