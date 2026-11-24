; clc/xce enters native mode with 8-bit registers.
                .p816
                .a16
                .i16
start:          clc
                xce
                lda     #1                      ; EXPECT: error
                .a8
                .i8
                ldx     #1
                rts
