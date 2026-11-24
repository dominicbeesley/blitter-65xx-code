
                .include "defs.inc"
                .include "cop.inc"
                .include "oslib-nat.inc"


                .import enter_cont2:far

                .segment        "NATHANDLER"

                .export handle_nat_brk
		.proc handle_nat_brk:far

                jml     [NAT_BRKV]

                .endproc



                ; we arrive here if the native program has generated an unhandled brk
                ; print an error message and exit back to calling program
                .export default_nat_brk
                .proc   default_nat_brk:far

                rep   #$38
                .a16
                .i16
                phd                   ;8
                phb                   ;7
                phx                   ;5
                pha                   ;1
                phy                   ;1
        ; Stack
        ;       +13     PBR
        ;       +11..12 PC
        ;       +10     P
        ;       +8..9   DP
        ;       +7      B
        ;       +5..6   X
        ;       +3..4   A
        ;       +1..2   Y

                tsc
                tcd
                
                lda     DPCOP_PC+2
                and     #$00FF
                tax
                lda     DPCOP_PC
                clc
                adc     #3
                ldy     #0
                cop     COP_02_OPWRA

                ; TODO: reset emu_sp somehow - or maybe in main.s
                jml     enter_cont2                


                .endproc


                