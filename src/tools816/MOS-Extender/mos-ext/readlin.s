                .include "oslib-nat.inc"
                .include "cop.inc"


                .segment        "NATHANDLER"

; ********************************************************************************
; * COP 22 - OPRLN - read line from input                                        *
; *                                                                              *
; * Action: Read a line of characters from the current input stream into a       *
; * buffer, with the usual line editing (DELETE, CTRL-U). Characters outside     *
; * the low..high range are not stored; the bell sounds if the buffer is full.   *
; * The line ends with CR, which is stored in the buffer but not counted.        *
; * (Same purpose as Communicator OPRLN, but a different control block.)         *
; *                                                                              *
; * On entry: X:A = pointer to the control block:                                *
; *             +0  4 bytes  buffer address                                      *
; *             +4  2 bytes  buffer length - 1 = most characters accepted,       *
; *                          not counting the CR (as OS_ReadLine32 R1)           *
; *             +6  1 byte   lowest character accepted                           *
; *             +7  1 byte   highest character accepted                          *
; *             +8  1 byte   password character, echoed instead of each          *
; *                          accepted character when flags bit 6 is set          *
; *             +9  1 byte   flags:                                              *
; *                            bit 7 = don't echo characters that are not        *
; *                                    accepted into the buffer                  *
; *                            bit 6 = echo the password character (+10)         *
; *                            bits 0-5 reserved, 0                              *
; * On exit:  Y   = number of characters read, not counting the CR               *
; *           C   = 0: line read, terminated by CR                               *
; *           C   = 1: ESCape pressed; Y and the buffer hold the line so far.    *
; *                 The caller must acknowledge the escape (OSBYTE &7E)          *
; *           X:A = preserved (control block)                                    *
; *                                                                              *
; * Errors:   none raised by the call itself; V=1 only for errors from the       *
; *           input stream                                                       *
; ********************************************************************************

                .importzp       zp_wksp

ZP_RDLIN_TXTBAS         := zp_wksp
ZP_RDLIN_BUFLEN         := zp_wksp+4
ZP_RDLIN_LOCH           := zp_wksp+6
ZP_RDLIN_HICH           := zp_wksp+7
ZP_RDLIN_PASSCH         := zp_wksp+8
ZP_RDLIN_FLAGS          := zp_wksp+9

                .a16
                .i16
                .export COP_22
                .proc   COP_22:far
                phd

                ; copy block down to our workspace

                ; switch to bank FF so we can copy direct to a:

                lda     #$FFFF
                pha
                plb
                plb

                ldy     #8
@clp:           lda     [DPCOP_XHA],Y
                sta     a:zp_wksp,Y
                dey
                dey
                bpl     @clp

                lda     #0
                tcd

                sep     #$20
                .a8

                ldy     #0
@lp1:           cop     COP_04_OPRDC
                bvs     @reterr                         ; todo - should we swallow errors, not for now
                bcs     @esc
                cmp     #$7F
                bne     @char
@del:           cpy     #0
                beq     @lp1                            ; nothing to delete
                lda     #$7F
                cop     COP_00_OPWRC                    ; write out the 7F to delete
                bvs     @reterr                         ; todo - should we swallow errors, not for now
                dey
                bra     @lp1
@char:          cmp     #8
                beq     @del
                cmp     #$15                            ; CTRL-U
                bne     @ins
                cpy     #0
                beq     @lp1
                lda     #$7F                            ; ready delete char
@clearlp:       cop     COP_00_OPWRC                    ; loop over Y deleting chars
                bvs     @reterr                         ; todo - should we swallow errors, not for now
                dey
                bne     @clearlp
                bra     @lp1
@ins:           sta     [ZP_RDLIN_TXTBAS],Y
                cmp     #$D
                clc
                beq     @ret
                cpy     ZP_RDLIN_BUFLEN
                bcs     @ful
                cmp     ZP_RDLIN_LOCH
                bcc     @nok
                cmp     ZP_RDLIN_HICH
                beq     @ok
                bcs     @nok
@ok:            iny
                bit     ZP_RDLIN_FLAGS
                bvc     @nopass
                lda     ZP_RDLIN_PASSCH                 ; password in force, obscure
@nopass:        cop     COP_00_OPWRC
                bvs     @reterr
                bra     @lp1
@nok:           bit     ZP_RDLIN_FLAGS
                bmi     @lp1                            ; suppress out of range chars
                cop     COP_00_OPWRC
                bvs     @reterr
                bra     @lp1

@ful:           lda     #7
                cop     COP_00_OPWRC                    ; bell
                bvs     @reterr
                bra     @lp1

@esc:           pld
                lda     #1
                tsb     DPCOP_P                         ; set carry for caller
                bra     @ret2
@ret:           pld
                lda     #1
                trb     DPCOP_P
@ret2:          sty     DPCOP_Y
                cop     COP_03_OPNLI
                rtl
@reterr:        pld
                rtl

                .endproc