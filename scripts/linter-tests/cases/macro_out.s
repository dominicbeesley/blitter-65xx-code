; A macro that changes sizes must say so with ;.out.
                .p816
                .macro  GO16                    ;.out a16 i16
                rep     #$30
                .endmacro
                .macro  QUIET                   ; EXPECT: warning
                rep     #$30
                .endmacro
                .a8
                .i8
start:          GO16
                .a16
                .i16
                lda     #$1234
                sep     #$30
                .a8
                .i8
                QUIET                           ; opaque: assumed unchanged
                .a16
                lda     #$1234                  ; EXPECT: error
                rts
