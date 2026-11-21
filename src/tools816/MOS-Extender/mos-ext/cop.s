; COP.S - this file contains the handler to translate the
; native mode COP API into the emu mode MOS API

        .include "oslib.inc"
        .include "oslib-nat.inc"
        .include "emu_zp.inc"
        .include "errors.inc"

        .export handle_nat_cop
        .export handle_emu_cop
        .import callmos
        .import COP_07
        .import COP_06
        .import buf
        .import gbpb_blk
        .import file_blk


        .exportzp DPCOP_Y
        .exportzp DPCOP_X
        .exportzp DPCOP_AH
        .exportzp DPCOP_B
        .exportzp DPCOP_DP
        .exportzp DPCOP_P
        .exportzp DPCOP_PC
        .exportzp DPCOP_K
        .exportzp DPCOP_XHA

DPCOP_Y         :=  1   ; offset of Y in COP entry/exit frame
DPCOP_AH        :=  3   ; offset of AH in COP entry/exit frame
DPCOP_X         :=  5   ; offset of X in COP entry/exit frame
DPCOP_B         :=  7   ; offset of B(ank) in COP entry/exit frame
DPCOP_DP        :=  8   ; offset of DP in COP entry/exit frame
DPCOP_P         := 10   ; offset of P in COP entry/exit frame
DPCOP_PC        := 11   ; offset of PC in COP entry/exit frame
DPCOP_K         := 13   ; offset of K (program bank) in COP entry/exit frame
DPCOP_XHA       :=      DPCOP_AH

LOGBPBBLK       := $FF0000 + gbpb_blk
LOFILEBLK       := $FF0000 + file_blk
EMUBUF          := $FF0000 + buf

;==================================================================
; EMU mode code
;==================================================================

                .code
handle_emu_cop: rti


                .segment        "NATHANDLER"
handle_nat_cop: plp
                php                   ;reestablish interrupts
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
                jsr     cop_dispatch_int
        ; Stack
        ;       +13     PBR
        ;       +11..12 PC-1    (dispatch code makes PC ready for an RTL instead of RTI!)
        ;       +10     P
        ;       +8..9   DP
        ;       +7      B
        ;       +5..6   X
        ;       +3..4   A
        ;       +1..2   Y


                ply
                pla
                plx
                plb
                pld
                plp
                rtl

cop_dispatch_int:
                tsc
                inc     a
                inc     a
                tcd                             ; point DP at Stacked registers

                dec     DPCOP_PC                ;decrement 16 bit return pointer to point at the signature byte
                lda     [DPCOP_PC]              ;get signature byte
                asl     a                       ;multiply by 2 to get index
                clc
                adc     [DPCOP_PC]
                and     #$00ff                  ;mask off whatever we fetched in high byte
                cmp     #tblCopDispatchLen      ;compare to end of cop table
                bcs     @ret_unimplemented      ;jump forward for high COPs
                tax                             ;transfer index to X
                phk
                pea     @ret-1
; The callee stack will now look like this:
; 
; +16   PBR
; +14   PC
; +13   P
; +11   DP
; +10   B
; +8    X
; +6    A
; +4    Y
; +1    FE/B673 - return address of COP dispatcher
; 
; The DP register will point at byte below Y
; 
; +13   PBR
; +11   PC
; +10   P
; +8    DP
; +7    B
; +5    X
; +3    A
; +1    Y
                phk
                plb
                lda     tblCOPDispatch+1,X
                pha
                lda     tblCOPDispatch-1,X

                ; restore B
                eor     DPCOP_B
                and     #$00FF
                eor     tblCOPDispatch-1,X
                pha
                plb

                php
                ldx     DPCOP_X                 ;restore X from stack
                lda     DPCOP_AH                ;restore A from stack
                rti

;;;;;;;;;;;;;;;;;;;;;;;;;;;; enter COP_HANDLER ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; The cop_handler will be entered when the RTI is executed
; A cop handler should expect the following register values
;       Reg     Size    Value
;       A       16      Caller's        
;       X       16      Caller's        
;       Y       16      Caller's        
;       DP      16      points at registers on stack - see cop.inc for offsets
;       P       8       The I flag will be as caller, D,M,X clear, CZV unspecified
;       S       16      ready for an RTL 
;
;       DP = S + 5 on entry, this may be used to restore DP if stacking is inconvenient
;
;       The cop handler may return with DP, register sizes changes and A,X,Y undefined
;
;       B,A,X,Y,DP,P are loaded back from the frame on the stack so to return values
;       to the caller the handler should update these.
                
                .a16
                .i16
@ret_unimplemented:
                ERRV    errNotImpl
                bra     @ret

                .a16
                .i16
@ret:           rep   #$30
                .a16
                .i16
                pha
                tsc
                inc     a
                inc     a
                inc     a
                inc     a
                tcd                             ; point DP at Stacked registers
                pla
                
                bvs     @err

                lda     #$0040
                trb     DPCOP_P

                rts

@err:           ; set V from caller
                sta     DPCOP_AH
                stx     DPCOP_X
                lda     #$0040
                tsb     DPCOP_P
                rts

                .a16
                .i16

tblCOPDispatch: .faraddr        COP_00          ;OPWRC  00 = OSWRCH
                .faraddr        COP_01          ;OPWRS  01 = Write String Immediate
                .faraddr        COP_02          ;OPWRA  02 = Write string at BHA
                .faraddr        COP_03          ;OPNLI  03 = OSNEWL - write CR/LF
                .faraddr        COP_NotImpl     ;OPRDC  04 = OSRDCH - read a char
                .faraddr        COP_NotImpl     ;OPCLI  05 = OPCLI - execute command at BYX [deprecated]
                .faraddr        COP_06          ;OPOSB  06 = OSBYTE
                .faraddr        COP_07          ;OPOSW  07 = OSWORD
                .faraddr        COP_NotImpl     ;OPCAV  08 = Call A Vector **NEW**
                .faraddr        COP_NotImpl     ;OPCAV  08 = Add to Vector **NEW**
                .faraddr        COP_0A          ;A      BGET
                .faraddr        COP_0B          ;B      BPUT
                .faraddr        COP_0C          ;OPFILE         0C = OSFILE **NEW**
                .faraddr        COP_NotImpl     ;D
                .faraddr        COP_NotImpl     ;OPCOM  0E = OPCOM - execute command at BHA
                .faraddr        COP_NotImpl     ;F

                .faraddr        COP_NotImpl     ;10
                .faraddr        COP_NotImpl     ;11
                .faraddr        COP_NotImpl     ;12
                .faraddr        COP_NotImpl     ;13
                .faraddr        COP_NotImpl     ;14
                .faraddr        COP_15          ;OPASC = OSASCI - write and expand <CR> to <LF><CR>
                .faraddr        COP_NotImpl     ;16
                .faraddr        COP_NotImpl     ;17
                .faraddr        COP_NotImpl     ;18
                .faraddr        COP_NotImpl     ;19
                .faraddr        COP_NotImpl     ;1A
                .faraddr        COP_NotImpl     ;1B
                .faraddr        COP_NotImpl     ;1C
                .faraddr        COP_NotImpl     ;1D
                .faraddr        COP_NotImpl     ;1E
                .faraddr        COP_NotImpl     ;1F

                .faraddr        COP_NotImpl     ;20
                .faraddr        COP_NotImpl     ;21
                .faraddr        COP_NotImpl     ;22
                .faraddr        COP_NotImpl     ;23
                .faraddr        COP_NotImpl     ;24
                .faraddr        COP_NotImpl     ;24
                .faraddr        COP_26          ;OPBHA - return address of immediate string in BHA
                .faraddr        COP_27          ;OPBHI - return immediate far address in BHA ** NEW
                .faraddr        COP_NotImpl     ;28
                .faraddr        COP_NotImpl     ;29
                .faraddr        COP_NotImpl     ;2A
                .faraddr        COP_NotImpl     ;2B
                .faraddr        COP_NotImpl     ;2C
                .faraddr        COP_NotImpl     ;2D
                .faraddr        COP_NotImpl     ;2E
                .faraddr        COP_NotImpl     ;OPIIQ - insert interrupt handler

                .faraddr        COP_NotImpl     ;OPRIQ - remove interrupt handler
                .faraddr        COP_NotImpl     ;OPMIQ - modify interrupt handler
                .faraddr        COP_NotImpl     ;OPSUM - do carry-round checksum of memory area
                .faraddr        COP_NotImpl     ;33
                .faraddr        COP_NotImpl     ;OPMOD - module management functions
                .faraddr        COP_NotImpl     ;34
                .faraddr        COP_NotImpl     ;36
                .faraddr        COP_NotImpl     ;37
                .faraddr        COP_NotImpl     ;38
                .faraddr        COP_NotImpl     ;39
                .faraddr        COP_NotImpl     ;3A
                .faraddr        COP_NotImpl     ;3B
                .faraddr        COP_NotImpl     ;3C
                .faraddr        COP_NotImpl     ;3D
                .faraddr        COP_NotImpl     ;3E
                .faraddr        COP_NotImpl     ;OPBWV - OS Byte/Word Vector

                .faraddr        COP_NotImpl     ;40
                .faraddr        COP_NotImpl     ;41
                .faraddr        COP_NotImpl     ;42
                .faraddr        COP_NotImpl     ;43
                .faraddr        COP_44          ;44     OPOPN - OSFIND - open a file
                .faraddr        COP_45          ;45     OPCLS - OSFINE - close a file
                .faraddr        COP_NotImpl     ;46
                .faraddr        COP_NotImpl     ;47
                .faraddr        COP_NotImpl     ;48
                .faraddr        COP_NotImpl     ;49
                .faraddr        COP_NotImpl     ;4A
                .faraddr        COP_NotImpl     ;4B
                .faraddr        COP_4C          ;4C     OPBGB - OSGBPB get/put block
                .faraddr        COP_NotImpl     ;4D
                .faraddr        COP_NotImpl     ;4E
                .faraddr        COP_NotImpl     ;4F

tblCopDispatchLen = *-tblCOPDispatch


; ********************************************************************************
; * COP X - NotImpelmented                                                       *
; *                                                                              *
; * returns V/error for not implemented                                          *
; ********************************************************************************
COP_NotImpl:    ERRV errNotImpl
                rtl


; ********************************************************************************
; * COP 15 - OPASC - BBC OSASCI                                                  *
; *                                                                              *
; * Action: Send the byte in A to the VDU drivers. If the byte is &0D            *
; * (carriage return) send &0A, &0D (line feed, carriage return) instead.        *
; *                                                                              *
; * On entry: A = character code (low byte)                                      *
; * On exit:  -                                                                  *
; ********************************************************************************
        .proc COP_15:far
                and   #$00ff
                cmp   #$000d
                bne   COP_00
                ; fall thru!
        .endproc
; ********************************************************************************
; * COP 03 - OPNLI - BBC OSNEWL                                                  *
; *                                                                              *
; * Action: Send LF CR (&0A, &0D) to the VDU drivers.                            *
; *                                                                              *
; * On entry: -                                                                  *
; * On exit:  -                                                                  *
; ********************************************************************************
        .proc COP_03:far
                lda   #$000a
                jsl   COP_00
                lda   #$000d
        .endproc

; ********************************************************************************
; * COP 00 - OPWRC - write character                                             *
; *                                                                              *
; * Action: Send the byte in A to the VDU drivers (OSWRCH).                      *
; *                                                                              *
; * On entry: A = character code (low byte)                                      *
; * On exit:  -                                                                  *
; ********************************************************************************
        .proc COP_00:far
                pea     OSWRCH
                jsl     callmos
                clv
                rtl
        .endproc

; ********************************************************************************
; * COP 01 - OPWRS - write string immediate                                      *
; *                                                                              *
; * Action: Write the zero-terminated string that follows the COP signature      *
; * byte. Execution continues after the terminating zero.                        *
; *                                                                              *
; * On entry: inline string, terminated by &00                                   *
; * On exit:  -                                                                  *
; *                                                                              *
; * Example:  cop COP_01_OPWRS                                                   *
; *           .byte "Hello", 13, 10, 0                                           *
; ********************************************************************************
COP_01:         inc     DPCOP_PC
                lda     [DPCOP_PC]
                and     #$00FF
                beq     @ret
                jsl     COP_00
                bra     COP_01
@ret:           clv
                rtl

; ********************************************************************************
; * COP 02 - OPWRA - write string at X:A                                         *
; *                                                                              *
; * Action: Write the string at X:A to the VDU drivers.                          *
; *                                                                              *
; * On entry: X:A = pointer to the string                                        *
; *           Y   = terminator option:                                           *
; *                 0 = terminated by &00                                        *
; *                 2 = terminated by &00 or any control character (< &20)       *
; * On exit:  -                                                                  *
; *                                                                              *
; * Errors:   invalid terminator option                                          *
; ********************************************************************************
COP_02:         lda     DPCOP_Y         ;get passed X and check is < 2 and use to determine type of terminator
                lsr     a
                cmp     #$0002
                bcc     @skok

                ERRV errOPWRAinv
                rtl

                ; TODO: change to .i8, .a8 to save a few bytes
@skok:          tax
                ldy     #$0000
@lp:            lda     [DPCOP_XHA],y   ;use XHA at 05 as pointer
                and     #$00ff
                beq     @ret            ;check for 0 terminator
                cpx     #$0001
                bne     @sknocc         ;if X<>1 skip forwards
                cmp     #$0020
                bcc     @ret            ;else exit on control character
@sknocc:        cop     COP_00_OPWRC
                iny
                bra   @lp

@ret:           clv
                rtl



; ********************************************************************************
; * COP 26 - OPXHA - address of immediate string                                 *
; *                                                                              *
; * Action: Return the address of the zero-terminated string that follows        *
; * the COP signature byte. Execution continues after the terminating zero.      *
; *                                                                              *
; * On entry: inline string, terminated by &00                                   *
; * On exit:  X:A = pointer to the string                                        *
; ********************************************************************************
                .a16
                .i16
COP_26:         lda     DPCOP_PC+2
                and     #$00FF
                sta     DPCOP_XHA+2
                lda     DPCOP_PC
                inc     A
                sta     DPCOP_XHA
; This skips over any string following the cop call
@copExitImmedStr:
                inc     DPCOP_PC
                lda     [DPCOP_PC]
                and     #$00ff
                bne     @copExitImmedStr
                clv
                rtl

; ********************************************************************************
; * COP 27 - OPBHI - immediate far address                                       *
; *                                                                              *
; * Action: Return the 3-byte address that follows the COP signature byte.       *
; * Execution continues after it.                                                *
; *                                                                              *
; * On entry: inline 24-bit address (low byte first)                             *
; * On exit:  X:A = the address (top byte 0)                                     *
; ********************************************************************************
                .a16
                .i16
COP_27:         inc     DPCOP_PC
                lda     [DPCOP_PC]
                sta     DPCOP_XHA
                inc     DPCOP_PC
                inc     DPCOP_PC
                lda     [DPCOP_PC]
                and     #$0FF
                sta     DPCOP_XHA+2
                clv
                rtl



                ; copies filename (control terminated) from [BHA],Y
                ; to EMUBUF - max 255 chars and adds a <CR>

                .proc   filename2emubuf:near
                php
                sep     #$30
                .a8
                .i8
                ldx     #1
@lp:            lda     [DPCOP_XHA], Y
                sta     f:EMUBUF-1,X
                cmp     #32+1
                bcc     @s
                iny
                inx
                bne     @lp

                ; force a CR terminator in our buffer
@s:             lda     #13
                sta     f:EMUBUF-1,X
                plp
                rts

                .endproc

; ********************************************************************************
; * COP 44 - OPOPN - open file                                                   *
; *                                                                              *
; * Action: Open a file (OSFIND).                                                *
; *                                                                              *
; * On entry: X:A = pointer to the filename, terminated by CR, control           *
; *                 character or space                                           *
; *           Y   = mode: &40 = input, &80 = output, &C0 = update                *
; * On exit:  Y   = handle (16 bits)                                             *
; *                                                                              *
; * Errors:   filing system errors; the file could not be opened                 *
; ********************************************************************************

                .a16
                .i16
                .proc   COP_44:far

                sep     #$30
                .a8
                .i8

                ; copy filename at BHA to safe emu-mode buffer
                ldy     #0
                jsr     filename2emubuf

                lda     DPCOP_Y
                beq     @ok                    ;ignore Y=0 silently
                ldx     #<buf
                ldy     #>buf
                pea     OSFIND
                jsl     callmos
                bvs     @notok
@ok1:           tay                             ; set Z
                bne     @ok2                    ; V is still clear from callmos
                ERRV    errNotOpened
@notok:         rtl
@ok2:           sty     DPCOP_Y
@ok:            clv
                rtl                             
        .endproc



; ********************************************************************************
; * COP 45 - OPCLS - close file                                                  *
; *                                                                              *
; * Action: Close a file opened with OPOPN (OSFIND 0).                           *
; *                                                                              *
; * On entry: Y = handle; Y = 0 closes all open files                            *
; * On exit:  -                                                                  *
; ********************************************************************************

                .a16
                .i16
                .proc COP_45:far

                lda     #0
                pea     OSFIND
                jsl     callmos
@notok:         rtl

                .endproc

; ********************************************************************************
; * COP 0A - OPBGT - BGET                                                        *
; *                                                                              *
; * Action: Read one byte from an open file.                                     *
; *                                                                              *
; * On entry: Y = handle (from OPOPN)                                            *
; * On exit:  A = byte read (zero-extended)                                      *
; *           C = 1 if end of file was reached; A is then undefined              *
; *                                                                              *
; * End of file is an indication, not an error (V stays clear).                  *
; ********************************************************************************

                .a16
                .i16
                .proc COP_0A:far

                pea     OSBGET
                jsl     callmos
                bvs     @notok
                sta     DPCOP_AH
                php
                ror     DPCOP_P
                plp
                rol     DPCOP_P
                ; V cleared by callmos         
@notok:         rtl

                .endproc

; ********************************************************************************
; * COP 0B - OPBPT - BPUT                                                        *
; *                                                                              *
; * Action: Write one byte to an open file.                                      *
; *                                                                              *
; * On entry: Y = handle (from OPOPN)                                            *
; *           A = byte to write (low byte)                                       *
; * On exit:  -                                                                  *
; ********************************************************************************

                .a16
                .i16
                .proc COP_0B:far

                pea     OSBPUT
                jsl     callmos
                rtl

                .endproc

; ********************************************************************************
; * COP 4C - OPGBPB - multiple byte get/put (OSGBPB)                             *
; *                                                                              *
; * Action: Read or write a block of bytes from/to an open file, as the          *
; * 8-bit MOS OSGBPB but with a 16-bit handle and 32-bit fields. Transfers       *
; * are bounced through a MOS-side buffer in chunks.                             *
; *                                                                              *
; * On entry: X:A = pointer to the control block                                 *
; *           Y   = reason code:                                                 *
; *                 1 = put bytes at the pointer given in the block              *
; *                 2 = put bytes at the current file pointer                    *
; *                 3 = get bytes from the pointer given in the block            *
; *                 4 = get bytes from the current file pointer                  *
; *                                                                              *
; * Control block:                                                               *
; *    +0   handle (16 bits)                                                     *
; *    +2   data address (32 bits)                                               *
; *    +6   number of bytes to transfer (32 bits)                                *
; *    +10  file pointer (32 bits, reasons 1 and 3)                              *
; *                                                                              *
; * On exit:  +2  advanced by the number of bytes transferred                    *
; *           +6  = number of bytes NOT transferred                              *
; *           +10 = the new file pointer                                         *
; *                                                                              *
; * End of file (reasons 3, 4) is not an error: it shows as a non-zero           *
; * count at +6 on exit.                                                         *
; *                                                                              *
; * Errors:   unsupported reason code (0, 5-8): Not implemented                  *
; ********************************************************************************

; TODO: optimise - use B=FF to eliminate far addressing?


        .proc   COP_4C:far
                
                cpy     #0
                beq     @errNotImpl
                cpy     #5
                bcc     @lt4

@errNotImpl:    ERRV    errNotImplOp       
                rtl


                ; we have a file-transfer we'll bounce this up through the low memory
                ; buffer

                ; TODO: at present this is 256 bytes long which we may want to increase

@lt4:
@tloop:         ; setup emu memory block

                ; count first
                ldy     #6
                lda     [DPCOP_XHA],Y
                and     #$FF00
                iny
                iny
                ora     [DPCOP_XHA],Y
                beq     @lt256
                lda     #$100           ; do 256 bytes max
                bra     @sk1
@lt256:         dey
                dey
                lda     [DPCOP_XHA],Y   ; get low length
@sk1:           sta     f:LOGBPBBLK+5

                clv
                bne     @not0
                jmp     @done0
@not0:          pha                     ; push the count - we need this later

                lda     #0
                sta     f:LOGBPBBLK+7

                ; data address
                sta     f:LOGBPBBLK+3
                lda     #buf
                sta     f:LOGBPBBLK+1

                ; offset
                ldy     #10
                lda     [DPCOP_XHA],Y
                sta     f:LOGBPBBLK+9
                iny
                iny
                lda     [DPCOP_XHA],Y
                sta     f:LOGBPBBLK+11

                sep     #$20
                .a8
                ; handle - note as we're calling nat2emu - we truncate the handle
                ; in model-c-mos we'd check and do something else here to pass to 16-bit FS?
                lda     [DPCOP_XHA]
                sta     f:LOGBPBBLK+0
                rep     #$20
                .a16

                lda     DPCOP_Y
                cmp     #3
                bcs     @notwrite

                ; it's a write use mvp to copy a block of data to buffer

                lda     #$FF54                  ; A contains dest bank in MSB, MVP in 
                sta     f:zp_mvn

                ldy     #4
                lda     [DPCOP_XHA],Y           ; A contains src bank in LSB
                and     #$00FF
                ora     #$6B00                  ; A contains src bank, RTL
                sta     f:zp_mvn+2

                ldy     #1
                lda     [DPCOP_XHA],Y           
                tax                             ; X contains src

                lda     f:LOGBPBBLK+5           ; A contains number to copy
                beq     @notwrite               ; nowt to do
                dec     A

                ldy     #buf            ; Y contains dest

                jsl     zp_mvn                  ; Note: messes up B

@notwrite:
                sep     #$30
                .a8
                .i8

                lda     DPCOP_Y
                ldx     #<gbpb_blk
                ldy     #>gbpb_blk
                
                pea     OSGBPB
                jsl     callmos
                bvs     @okk
; it looks like we can't rely on A=0 as an indicator of FS that supports
; the function code.
;;;                cmp     #0
;;;                beq     @okk
;;;                pla                             
;;;                pla                             ; discard stacked length
;;;                ERRV    errNotImplOp
;;;                jmp     @done0
@okk:           rep     #$30
                .a16
                .i16

                phx                             ; and save any X/A returned in case of errors
                pha
                php                             ; save return for later

                lda     DPCOP_Y
                cmp     #3
                bcc     @notread

                ; we need to copy the byte transferred from buf to 
                ; nat-mode memory


                ldy     #3
                lda     [DPCOP_XHA],Y           ; A contains dest bank in MSB
                and     #$FF00
                ora     #$0054                  ; A contains dest bank in MSB, MVP in           
                sta     f:zp_mvn

                lda     #$6BFF                  ; A contains src bank, RTL
                sta     f:zp_mvn+2

                dey
                lda     [DPCOP_XHA],Y           
                tay                             ; Y contains dest

                lda     6,S                     ; get length
                sec
                sbc     f:LOGBPBBLK+5           ; subtract remainder reported by OSGBPB - assume not wrapped!
                beq     @notread                ; nowt to do
                dec     A

                ldx     #buf            ; X contains src

                jsl     zp_mvn                  ; Note: messes up B


@notread:
                ; we transferred all bytes. Update the caller block and loop if
                ; there's more left

                ; copy back file pointer
                ldy     #10
                lda     f:LOGBPBBLK+9
                sta     [DPCOP_XHA],Y
                iny
                iny
                lda     f:LOGBPBBLK+11
                sta     [DPCOP_XHA],Y

                ; move the data pointer on
                ldy     #2
                lda     6,S                     ; get length
                sec
                sbc     f:LOGBPBBLK+5           ; subtract remainder
                clc
                adc     [DPCOP_XHA],Y
                sta     [DPCOP_XHA],Y
                iny
                iny
                lda     #0
                adc     [DPCOP_XHA],Y
                sta     [DPCOP_XHA],Y

                ; decrement the length
                lda     6,S                     ; get back length
                sec
                sbc     f:LOGBPBBLK+5           ; subtract remainder
                eor     #$FFFF
                sec                             ; negate (EOR+1)
                ldy     #6
                adc     [DPCOP_XHA],Y
                sta     [DPCOP_XHA],Y
                iny
                iny
                lda     #$FFFF
                adc     [DPCOP_XHA],Y
                sta     [DPCOP_XHA],Y

                plp
                php
                bvs     @done

                lda     f:LOGBPBBLK+5
                bne     @done                   ; keep going if we got 0 as the remainder (ignore Cy)
                                                ; from OSGBPB as it's unreliable

                plp                             ; discard error return from callmos
                pla
                pla
                pla                             ; discard saved length


                lda     [DPCOP_XHA],Y
                dey
                dey
                ora     [DPCOP_XHA],Y
                beq     @done0
                jmp     @tloop

@done:          plp
                pla
                plx                             ; assume callmos has set this correctly for errors!
                ply                             ; discard stacked count

@done0:                 
                rtl


        .endproc


; ********************************************************************************
; * COP 0C - OPFILE - whole-file operations (OSFILE)                             *
; *                                                                              *
; * Action: Whole-file operations, as the 8-bit MOS OSFILE but with 32-bit       *
; * fields. With an 8-bit filing system a load is carried out as                 *
; * OPEN / GBPB / CLOSE operations.                                              *
; *                                                                              *
; * On entry: X:A = pointer to the control block                                 *
; *           Y   = reason code:                                                 *
; *                  - see 8-bit MOS for reasons                                 *
; *                                                                              *
; * Control block:                                                               *
; *    +0   pointer to filename (32 bits), terminated by CR, control             *
; *         character or space                                                   *
; *    +4   load address (32 bits)                                               *
; *    +8   exec address (32 bits)                                               *
; *    +12  length (32 bits)                                                     *
; *    +16  attributes (32 bits)                                                 *
; *                                                                              *
; * On exit:  Y = object type: 0 = not found, 1 = file, 2 = directory            *
; *           block +4..+19 = the object's catalogue information                 *
; *                                                                              *
; * Load (&FF): if the low byte of the exec address (+8) is 0 the file is        *
; * loaded to the address at +4, otherwise to the file's own load address.       *
; * The address is used as a native 32-bit address (bank = byte +6); there       *
; * is no Tube/I/O processor address mapping.                                    *
; *                                                                              *
; * Errors:   &FF on an object that is not a file: &D6 File not found            *
; *           unsupported reason code: Not implemented                           *
; ********************************************************************************
                .a16
                .i16
        .proc   COP_0C:far
                

                cpy     #$FF
                beq     @load
                cpy     #$5
                beq     @load
                ERRV    errNotImplOp
                rtl
@load:          
                sep     #$30
                .a8
                .i8
                ; code is FF = load or 05 read file attributes

                ; copy filename pointer to zp_mvn 
                ldy     #0
                lda     [DPCOP_XHA],Y
                sta     f:zp_mvn
                iny
                lda     [DPCOP_XHA],Y
                sta     f:zp_mvn+1
                iny
                lda     [DPCOP_XHA],Y
                sta     f:zp_mvn+2
                
                phd
                lda     #0
                xba
                lda     #zp_mvn-DPCOP_XHA       ; this will setup the DP register such that the pointer
                tcd                             ; we've just copied is at the right offset - TODO: call filename copy with XA instead?

                ; copy filename to buf
                ldy     #0
                jsr     filename2emubuf

                pld

                lda     #<buf
                sta     f:LOFILEBLK
                lda     #>buf
                sta     f:LOFILEBLK+1

                lda     #$05                    ; get catalogue information
                ldx     #<file_blk
                ldy     #>file_blk
     
                pea     OSFILE
                jsl     callmos

                                                ; save the returned file type
                bvs     @e1                     ; got an error from OSFILE return straight away
                ldy     DPCOP_Y
                iny
                beq     @skFF
                tay
                rep     #$30
                .a16
                .i16
                sty     DPCOP_Y                 ; return file type
@e1:            jmp     @op5_exit

                .a8
                .i8
@skFF:          tay
                sty     DPCOP_Y                 ; store file type
                cmp     #1
                beq     @skFNF
@brkFilenotFound:
                ERRV    errFileNotFound
                rtl

@skFNF:         ; emu file block now contains the file's info
                ; work out which pointer to use in gbpb block
                ; depending on LSB of exec address in passed in block
                ldy     #8
                lda     [DPCOP_XHA],Y

                rep     #$30
                .a16
                .i16

                beq     @sknold
                ; copy loaded load address back up to here
                
                ldy     #4
                lda     f:LOFILEBLK+2
                sta     [DPCOP_XHA],Y
                lda     f:LOFILEBLK+4
                iny
                iny
                sta     [DPCOP_XHA],Y

@sknold:
                ;make GBPB block on stack
                tsc
                sec
                sbc     #14
                tcs

                ; gbpb block data pointer
                ldy     #4
                lda     [DPCOP_XHA],Y
                sta     3,S
                iny
                iny
                lda     [DPCOP_XHA],Y
                sta     5,S

                ; gbgp length from file info
                lda     f:LOFILEBLK+10
                sta     7,S
                lda     f:LOFILEBLK+12
                sta     9,S


                ; open file using COP call
                ldy     #2
                lda     [DPCOP_XHA],Y
                tax
                lda     [DPCOP_XHA]
                ldy     #$40
                cop     COP_44_OPOPN
                bvs     @nok2
                tya
                sta     1,S             ; set file handle in gbpb lo block

                ldx     #0
                tsc
                inc     A
                ldy     #4
                cop     COP_4C_OPGBPB
                php
                phx
                pha

                ; TODO: check for errors and do something here but what?

                lda     6,S
                tay
                cop     COP_45_OPCLS

                pla
                plx
                plp                     ; keep GPBPB errors, ignore CLOSE errors

@nok2:
                ; restore stack
                php                     ; keep possible V flag

                ; stack
                ;       +2..15  rubbish OSGBPB block (14 bytes)
                ;       +1      P above

                sta     14,S            ; keep possible A error
                lda     0,S             ; 0,S (rubbish) the P from 1,S
                sta     12,S            ; move P up
                             
                ; stack
                ;       +14..15 A
                ;       +13     P above
                ;       +1..12  rubbish

                tsc
                clc
                adc     #14-2           ; minus 2 for the extra A we saved
                tcs

                plp
                pla


@op5_exit:      rep     #$30
                .a16
                .i16
                phx
                pha
                ; now copy file info back to caller's block
                ldx     #18-2
                ldy     #20-2
@llp:           lda     f:LOFILEBLK,X
                sta     [DPCOP_XHA],Y
                dey
                dey
                dex
                dex
                bne     @llp
                pla
                plx
                rtl

        .endproc