; Cheap local (@) and anonymous (:) labels are followed.
                .p816
                .a8
                .i8
first:          bne     @skip
                rep     #$20
                .a16
                bra     :+
@skip:          rep     #$20
:               lda     #$1234
                rts
second:         beq     @skip                   ; different @skip
                rts
@skip:          lda     #1
                rts
