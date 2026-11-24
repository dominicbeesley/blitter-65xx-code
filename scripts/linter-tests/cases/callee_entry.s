; A routine reached only by jsr is checked with the callers' sizes, not
; the size declared at that point in the file.
                .p816
                .a16
                .i16
start:          sep     #$20
                .a8
                jsr     helper
                rep     #$20
                .a16
                rts

                .a16
helper:         lda     #$1234                  ; EXPECT: error
                rts
