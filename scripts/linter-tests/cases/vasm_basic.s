; SYNTAX: vasm
; vasm oldstyle: column-1 labels without colons, a16/x8, locals, equates.
FLAG    = $20
count   equ 4
        a8
        x8
start   rep     #FLAG
        a16
        lda     #$1234
.loop   dex
        bne     .loop
        sep     #$20
        lda     #1234           ; EXPECT: error
        bra     done$
done$   rts
