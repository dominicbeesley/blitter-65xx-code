; SYNTAX: vasm
; "name macro" with a ;.out contract, ifd/ifnd, anonymous labels, dotdir.
setA16  macro                   ;.out a16
        rep     #$20
        a16
        endm
noout   macro                   ; EXPECT: warning
        sep     #$20
        endm                    ; (macro warning goes on the macro line)
        .a8
start:  setA16
        ifd     NOTDEF
        sep     #$20
        else
        nop
        endif
        lda     #$1234          ; still 16-bit: ok
:       dex
        bne     :-
        .a8
        lda     #1              ; EXPECT: error
        rts
