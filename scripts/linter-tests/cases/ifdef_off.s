; Same as ifdef.s with no defines: no error.
                .p816
                .a16
start:
        .IFDEF BUGGY
                sep     #$20
        .ENDIF
        .IF .defined(BUGGY) || .defined(OTHER)
                sep     #$20
        .ENDIF
                lda     #$1234
                rts
