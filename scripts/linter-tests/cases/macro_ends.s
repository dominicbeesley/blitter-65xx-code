; A macro whose body ends with rts/rtl/jmp ends the path, like the
; instruction itself.
                .p816
                .macro  RET
                rts
                .endmacro
                .a16
first:          sep     #$20
                RET
                .byte   "data"
                .a16
second:         lda     #$1234
                rts
