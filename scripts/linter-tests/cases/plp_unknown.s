; plp with nothing pushed in this routine: P came from the caller, so the
; source's .aX/.iX are trusted (no message) until the next rep/sep.
                .p816
                .a16
start:          plp
                lda     #1
                sep     #$20
                lda     #1                      ; EXPECT: error
                rts
