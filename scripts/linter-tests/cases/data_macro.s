; A macro that only emits data is data, not code: no "falls through data"
; hint, and it isn't traced as an entry point.
                .p816
.macro          HiAscii Arg
                .repeat .strlen(Arg), I
                .byte   .strat(Arg, I) | $80
                .endrep
.endmacro
                HiAscii "***&"
table:          .byte   1, 2, 3
                .a8
start:          lda     #1
                rts
