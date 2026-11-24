; The macro contract comes from an included file.
                .p816
                .include "include_macros.inc"
                .a8
start:          TO16
                .a16
                lda     #$1234
                rts
