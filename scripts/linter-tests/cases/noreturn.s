; An error macro that never returns: the bytes after it are not code, so
; the conflicting sizes at the label don't flow on into the next routine.
                .p816
                .macro  ERR n                   ;.noreturn
                .byte   0, n
                .endmacro
                .a16
first:          bcs     bad
                sep     #$20
                .a8
                bcs     bad
                rts
bad:            ERR     $0a
                .byte   "Bad", 0
next:           lda     #1
                brk
                .byte   1, "x", 0
after:          lda     #1
                rts
