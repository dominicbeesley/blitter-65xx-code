; ;.a8 on a line tells the linter what the CPU size is (here after a
; trick it can't follow).
                .p816
                .a16
start:          pea     $3000
                plp                             ;.a8
                .a8
                lda     #1
                rts
; Prose in a comment is not an annotation:
other:          lda     #1              ; TODO: could be .a16 here
                rts
