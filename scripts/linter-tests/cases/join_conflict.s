; Like cop.s @clcretA: a label reached with 8-bit A from one path and
; 16-bit A from another.
                .p816
                .a16
                .i16
start:          bcs     @err
                sep     #$20
                .a8
                bra     @ret
@err:           clc
@ret:           and     #$FE                    ; EXPECT: error
                rts
