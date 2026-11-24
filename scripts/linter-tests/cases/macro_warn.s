; Macros that change sizes must say so with ;.out.
                .p816
                .macro  A16ONLY                 ; EXPECT: warning
                rep     #$20
                .a16
                .endmacro
                .macro  A16OK                   ;.out a16
                rep     #$20
                .a16
                .endmacro
                .macro  SAFE
                php
                lda     #0
                .endmacro
                .a8
start:          A16OK
                lda     #$1234                  ; the macro's .a16 applies
                SAFE
                rts
