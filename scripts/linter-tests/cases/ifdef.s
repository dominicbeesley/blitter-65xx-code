; DEFINES: BUGGY
; The mismatch is only assembled when BUGGY is defined.
                .p816
                .a16
start:
        .IFDEF BUGGY
                sep     #$20
        .ELSE
                nop
        .ENDIF
                lda     #$1234                  ; EXPECT: error
                rts
