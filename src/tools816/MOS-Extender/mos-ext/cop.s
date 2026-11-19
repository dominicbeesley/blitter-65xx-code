; COP.S - this file contains the handler to translate the
; native mode COP API into the emu mode MOS API

        .include "oslib.inc"
        .include "oslib-nat.inc"
        .include "emu_zp.inc"

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
        .exportzp DPCOP_BHA

DPCOP_Y         :=  1   ; offset of Y in COP entry/exit frame
DPCOP_X         :=  3   ; offset of X in COP entry/exit frame
DPCOP_AH        :=  5   ; offset of AH in COP entry/exit frame
DPCOP_B         :=  7   ; offset of B(ank) in COP entry/exit frame
DPCOP_DP        :=  8   ; offset of DP in COP entry/exit frame
DPCOP_P         := 10   ; offset of P in COP entry/exit frame
DPCOP_PC        := 11   ; offset of PC in COP entry/exit frame
DPCOP_K         := 13   ; offset of K (program bank) in COP entry/exit frame
DPCOP_BHA       :=      DPCOP_AH

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
                pha                   ;5
                phx                   ;3
                phy                   ;1
        ; Stack
        ;       +13     PBR
        ;       +11..12 PC
        ;       +10     P
        ;       +8..9   DP
        ;       +7      B
        ;       +5..6   A
        ;       +3..4   X
        ;       +1..2   Y
                jsr     cop_dispatch_int
        ; Stack
        ;       +13     PBR
        ;       +11..12 PC-1    (dispatch code makes PC ready for an RTL instead of RTI!)
        ;       +10     P
        ;       +8..9   DP
        ;       +7      B
        ;       +5..6   A
        ;       +3..4   X
        ;       +1..2   Y


                ply
                plx
                pla
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
; +8    A
; +6    X
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
; +5    A
; +3    X
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
                
@ret:           rep   #$30
                .a16
                .i16
                tsc
                inc     a
                inc     a
                tcd                             ; point DP at Stacked registers
        ; internal API Change cop handlers must set DPCOP_P explicitly
        ; TODO: use V as error flag here !?
;;              php
;;              ror     DPCOP_P
;;              plp
;;              rol     DPCOP_P                 ; get returned Cy into flags
                rts

                .a16
                .i16
@ret_unimplemented:
                stz     DPCOP_X                 ;clear saved X
                lda     #$41
                tsb     DPCOP_P                 ;return error/V/Cy
                bra     @ret

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


;               ********************************************************************************
;               * COP 15 - OPASC - BBC OPASCI                                                  *
;               *                                                                              *
;               * Action: Send the byte in A to the VDU drivers. If the byte is &0D (carriage  *
;               * return) then send &0A, &0D to the VDU drivers (line feed+ carriage return).  *
;               *                                                                              *
;               * On entry: A = character code.                                                *
;               * On exit:  DBAXY preserved                                                    *
;               ********************************************************************************
COP_15:         and   #$00ff
                cmp   #$000d
                bne   COP_00
;               ********************************************************************************
;               * COP 03 - OSNLI - BBC OSNEWL                                                  *
;               *                                                                              *
;               * Action: Send LF CR to the VDU drivers. Line feed is ASCII 10 (decimal),      *
;               * carriage return is ASCII 13 (decimal).                                       *
;               *                                                                              *
;               * On entry: No requirement                                                     *
;               * On exit:  DBAXY preserved                                                    *
;               ********************************************************************************
COP_03:         lda   #$000a
                jsl   COP_00
                lda   #$000d

;               ********************************************************************************
;               * COP 00 - OPWRC - Write Char in A                                             *
;               *                                                                              *
;               * Action: Send the byte in A to the VDU drivers.                               *
;               *                                                                              *
;               * On entry: A = character code                                                 *
;               * On exit:  DBAXY preserved                                                    *
;               *                                                                              *
;               ********************************************************************************

COP_00:         pea     OSWRCH
                jsl     callmos
                rtl

;               ********************************************************************************
;               * COP 01 - OPWRS - write string immediate                                      *
;               *                                                                              *
;               * read characters from bytes following cop, check for 0 and pass on to write   *
;               * character routine                                                            *
;               ********************************************************************************
COP_01:         inc     DPCOP_PC
                sep     #$20
                .a8
                lda     [DPCOP_PC]
                sta     DPCOP_AH
                rep     #$20
                .a16
                beq     @ret
                phd
                jsl     COP_00
                pld
                bra     COP_01

@ret:           rtl

;               ********************************************************************************
;               * COP 02 - OPWRA - write string at BHA                                         *
;               *                                                                              *
;               * TODO: DOCO: NOTE: This seems to imply that X is set to 0,1 for 0 terminated  *
;               * 2,3 for control terminated string - not in systems manual                    *
;               *                                                                              *
;               ********************************************************************************
COP_02:         lda     DPCOP_X         ;get passed X and check is < 2 and use to determine type of terminator
                lsr     a
                cmp     #$0002
                bcc     @skok
                brk     $00

                .byte "COP `OPWRA: invalid termination option",0

@skok:          tax
                ldy     #$0000
@lp:            lda     [DPCOP_AH],y    ;use BHA at 05 as pointer
                and     #$00ff
                beq     @ret            ;check for 0 terminator
                cpx     #$0001
                bne     @sknocc         ;if X<>1 skip forwards
                cmp     #$0020
                bcc     @ret            ;else exit on control character
@sknocc:        cop     COP_00_OPWRC
                iny
                bra   @lp

@ret:           rtl


COP_NotImpl:    sec
                stz     DPCOP_X
                rtl

; ********************************************************************************
; * COP 26 - OPBHA                                                               *
; *                                                                              *
; * returns the immediate string following the COP call as BHA                   *
; ********************************************************************************
                .a16
                .i16
COP_26:         lda   DPCOP_PC+1
                sta   DPCOP_AH+1
                lda   DPCOP_PC
                inc   A
                sta   DPCOP_AH
; This skips over any string following the cop call
@copExitImmedStr:
                inc  DPCOP_PC
                lda   [DPCOP_PC]
                and   #$00ff
                bne   @copExitImmedStr
                rtl

; ********************************************************************************
; * COP 27 - OPBHI                                                               *
; *                                                                              *
; * returns the immediate far address following the cop call as BHA              *
; ********************************************************************************
                .a16
                .i16
COP_27:         inc     DPCOP_PC
                lda     [DPCOP_PC]
                sta     DPCOP_AH
                inc     DPCOP_PC
                lda     [DPCOP_PC]
                sta     DPCOP_AH+1
                inc     DPCOP_PC
                rtl



                ; copies filename (control terminated) from [BHA],Y
                ; to EMUBUF - max 255 chars and adds a <CR>

                .proc   filename2emubuf:near
                php
                sep     #$30
                .a8
                .i8
                ldx     #1
@lp:            lda     [DPCOP_BHA], Y
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
; * COP 44 - OPOPN - open file (or device driver)                                *
; * Action: This call opens a device driver.                                     *
; * On entry: BHA points to the name (with colon). terminated by CR(&0D).        *
; *           Y = &40 for input                                                  *
; *           Y = &80 for output                                                 *
; *           Y = &C0 for update                                                 *
; * On exit:  C = 0 means that the device driver is open and Y = handle.         *
; *           If C= I then the device failed to open, the error code is in X     *
; *           and BHA points to a zeroterminated error message.                  *
; *           D preserved                                                        *
; *                                                                              *
; * This translates to OSFIND                                                    *
; *                                                                              *
; *                                                                              *
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
                beq     @ign                    ;ignore Y=0
                ldx     #<buf
                ldy     #>buf
                pea     OSFIND
                jsl     callmos

                cmp     #0
                bne     @clcretA

                cop     COP_26_OPBHA
                .byte   "File not opened", 0
                phb
                plx
                stx     DPCOP_B
                rep     #$30
                .a16
                .i16
                sta     DPCOP_AH
                ; return error
                lda     #1
                sta     DPCOP_X
                ror     DPCOP_P
                sec
                rol     DPCOP_P
                rtl


@clcretA:       .a8
                .i8
                sta     DPCOP_Y
                stz     DPCOP_Y+1
                lda     DPCOP_P
                and     #$FE
                sta     DPCOP_P
@ign:           rtl

        .endproc



; ********************************************************************************
; * COP 45 - OPCLS - close device driver                                         *
; * Action: This call closes a device driver which has been opened using OPOPN.  *
; *                                                                              *
; * On entry: Y = handle allocated by OPOPN.                                     *
; * On exit:  If C = 0 then driver is closed.                                    *
; *           If C = 1 then the driver close failed, X = error code and BHA      *
; *           points to a zero-terminated error message.                         *
; *           D preserved                                                        *
; ********************************************************************************

                .a16
                .i16
                .proc COP_45:far

                lda     #0
                pea     OSFIND
                jsl     callmos

                ; I don't think it can fail?

                lda     DPCOP_P
                and     #$FFFE
                sta     DPCOP_P
                
                rtl

                .endproc

; ********************************************************************************
; * COP 0A - OPBGT - BGET                                                        *
; *                                                                              *
; * Action: Read one byte from an open device or file. The channel must          *
; * previously have been opened using OPOPN.                                     *
; *                                                                              *
; * On entry: Y contains the handle from OPOPN.                                  *
; * On exit:  A contains the byte read from the file.                            *
; *           if C = I then an error (EOF) has occurred, and A is invalid.       *
; *           No registers preserved                                             *
; ********************************************************************************

                .a16
                .i16
                .proc COP_0A:far

                pea     OSBGET
                jsl     callmos
                sep     #$20
                .a8
                sta     DPCOP_AH
                php
                ror     DPCOP_P
                plp
                rol     DPCOP_P
                
                rtl

                .endproc

; ********************************************************************************
; * COP 0B - OPBPT - BPUT                                                        *
; *                                                                              *
; * Action: Write one byte to an open file or device. The channel must           *
; * previously have been opened using OPOPN.                                     *
; *                                                                              *
; * On entry: Y contains the file handle from OPOPN.                             *
; *           A contains the byte to be written.                                 *
; * On exit:  No registers preserved                                             *
; ********************************************************************************

                .a16
                .i16
                .proc COP_0B:far

                pea     OSBPUT
                jsl     callmos
                
                ; assume success?

                rtl

                .endproc

; ********************************************************************************
; * COP 4C - OPGBPB - Get/Put bytes/Read directories                             *
; *                                                                              *
; * Action: Depending on the function code may read/write bytes in blocks to/    *
; * from an open file or read directory entries. See original MOS OSGBPB for     *
; * details.                                                                     *
; *                                                                              *
; * On entry: Y contains the function code                                       *
; *           BHA contains a pointer to the control block                        *
; * On exit:  Y=0 if handled                                                     *
; *           Other information is returned in control block                     *
; * TODO: Cy for EOF?
; ********************************************************************************
;
; TODO: optimise - use B=FF to eliminate far addressing?


        .proc   COP_4C:far
                
                cpy     #0
                beq     @rtl
                cpy     #5
                bcc     @lt4

@rtl:           rtl


                ; we have a file-transfer we'll bounce this up through the low memory
                ; buffer

                ; TODO: at present this is 256 bytes long which we may want to increase

@lt4:
@tloop:         ; setup emu memory block

                ; count first
                ldy     #5
                lda     [DPCOP_BHA],Y
                and     #$FF00
                iny
                iny
                ora     [DPCOP_BHA],Y
                beq     @lt256
                lda     #$100           ; do 256 bytes max
                bra     @sk1
@lt256:         dey
                dey
                lda     [DPCOP_BHA],Y   ; get low length
@sk1:           sta     f:LOGBPBBLK+5

                pha                     ; push the count - we need this later

                lda     #0
                sta     f:LOGBPBBLK+7

                ; data address
                sta     f:LOGBPBBLK+3
                lda     #buf
                sta     f:LOGBPBBLK+1

                ; offset
                ldy     #9
                lda     [DPCOP_BHA],Y
                sta     f:LOGBPBBLK+9
                iny
                iny
                lda     [DPCOP_BHA],Y
                sta     f:LOGBPBBLK+11

                sep     #$20
                .a8
                ; handle
                lda     [DPCOP_BHA]
                sta     f:LOGBPBBLK+0
                rep     #$20
                .a16

                lda     DPCOP_Y
                cmp     #3
                bcs     @notwrite

                ; it's a write use mvp to copy a block of data to buffer

                lda     #$FF54                  ; A contains dest bank in MSB, MVP in 
                sta     f:zp_mvn

                ldy     #3
                lda     [DPCOP_BHA],Y           ; A contains src bank in LSB
                and     #$00FF
                ora     #$6B00                  ; A contains src bank, RTL
                sta     f:zp_mvn+2

                ldy     #1
                lda     [DPCOP_BHA],Y           
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

                lda     DPCOP_Y
                cmp     #3
                
                rep     #$30
                .a16
                .i16

                bcc     @notread

                ; we need to copy the byte transferred from buf to 
                ; nat-mode memory


                ldy     #2
                lda     [DPCOP_BHA],Y           ; A contains src bank in LSB
                and     #$FF00
                ora     #$0054                  ; A contains dest bank in MSB, MVP in           
                sta     f:zp_mvn

                lda     #$6BFF                  ; A contains src bank, RTL
                sta     f:zp_mvn+2

                dey
                lda     [DPCOP_BHA],Y           
                tay                             ; Y contains dest

                pla                             ; get length
                pha
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
                ldy     #9
                lda     f:LOGBPBBLK+9
                sta     [DPCOP_BHA],Y
                iny
                iny
                lda     f:LOGBPBBLK+11
                sta     [DPCOP_BHA],Y

                ; move the data pointer on
                ldy     #1
                pla
                pha
                sec
                sbc     f:LOGBPBBLK+5           ; subtract remainder
                clc
                adc     [DPCOP_BHA],Y
                sta     [DPCOP_BHA],Y
                iny
                iny
                lda     #0
                adc     [DPCOP_BHA],Y
                sta     [DPCOP_BHA],Y

                ; decrement the length
                pla                             ; get back length
                sec
                sbc     f:LOGBPBBLK+5           ; subtract remainder
                eor     #$FFFF
                sec                             ; negate (EOR+1)
                ldy     #5
                adc     [DPCOP_BHA],Y
                sta     [DPCOP_BHA],Y
                iny
                iny
                lda     #$FFFF
                adc     [DPCOP_BHA],Y
                sta     [DPCOP_BHA],Y

                lda     f:LOGBPBBLK+5
                bne     @done                   ; keep going if we got 0 as the remainder (ignore Cy)
                                                ; from OSGBPB as it's unreliable

                lda     [DPCOP_BHA],Y
                dey
                dey
                ora     [DPCOP_BHA],Y
                beq     @done
                jmp     @tloop

@done:          ldy     #0
                sty     DPCOP_Y
                rtl


@eof:


        .endproc



; ********************************************************************************
; * COP 0C OPFILE - call filing system's OSFILE entry                            *
; *                                                                              *
; * On Entry                                                                     *
; *     Y       Function code (as for 8-bit MOS)                                 *
; *     BHA     Points to a **NEW** OSFILE block:                                *
; *               0     32-bit address of filename                               *
; *               4     load address                                             *
; *               8     exec address                                             *
; *               12    start address                                            *
; *               16    end address                                              *
; *                                                                              *
; * On exit                                                                      *
; *     block is updated                                                         *
; *     Y       Object type or preserved if unsupported                          *
; *                                                                              *
; *                                                                              *
; * This call may be translated into an OPEN/GBPB*/CLOSE operations when an      *
; * 8-bit filing system is in operation.                                         *
; *                                                                              *
; *                                                                              *
; ********************************************************************************
                .a16
                .i16
        .proc   COP_0C:far
                
                sep     #$30
                .a8
                .i8

                cpy     #$FF
                beq     @load
                cpy     #$5
                beq     @load
                rtl

@load:          ; code is FF = load or 05 read file attributes

                ; copy filename pointer to zp_mvn 
                ldy     #0
                lda     [DPCOP_BHA],Y
                sta     f:zp_mvn
                iny
                lda     [DPCOP_BHA],Y
                sta     f:zp_mvn+1
                iny
                lda     [DPCOP_BHA],Y
                sta     f:zp_mvn+2
                
                phd
                lda     #0
                xba
                lda     #zp_mvn-DPCOP_BHA
                tcd

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

                ldy     DPCOP_Y
                iny
                beq     @skFF
                ; op 5 exit
                ldy     #0
                sty     DPCOP_Y                 ; mark as supported/done
                rtl                             ; exit from fn 5
@skFF:          
                sty     DPCOP_Y                 ; mark as supported/done
                cmp     #0
                bne     @skFNF
@brkFilenotFound:
                brk     214
                .byte   "File not found", 0
@skFNF:         ; emu file block now contains the file's info
                ; work out which pointer to use in gbpb block
                ; depending on LSB of exec address in passed in block
                ldy     #8
                lda     [DPCOP_BHA],Y

                rep     #$30
                .a16
                .i16

                beq     @sknold
                ; copy loaded load address back up to here
                
                ldy     #4
                lda     f:LOFILEBLK+2
                sta     [DPCOP_BHA],Y
                lda     f:LOFILEBLK+4
                iny
                iny
                sta     [DPCOP_BHA],Y

@sknold:
                ;make GBPB block on stack
                tsc
                sec
                sbc     #13
                tcs

                ; gbpb block data pointer
                ldy     #4
                lda     [DPCOP_BHA],Y
                sta     2,S
                iny
                iny
                lda     [DPCOP_BHA],Y
                sta     4,S

                ; gbgp length from file info
                lda     f:LOFILEBLK+10
                sta     6,S
                lda     f:LOFILEBLK+12
                sta     8,S


                ; open file using COP call
                ldy     #1
                lda     [DPCOP_BHA],Y
                pha
                plb
                plb
                lda     [DPCOP_BHA]
                ldy     #$40
                cop     COP_44_OPOPN
                bcs     @brkFilenotFound
                tya
                sep     #$20
                .a8
                sta     1,S             ; set file handle in gbpb lo block
                rep     #$20
                .a16

                lda     #0
                pha
                plb
                plb
                tsc
                inc     A
                ldy     #4
                cop     COP_4C_OPGBPB

                ; TODO: check for errors and do something here but what?

                lda     1,S
                and     #$00FF
                tay
                cop     COP_45_OPCLS


                ; restore stack
                tsc
                clc
                adc     #13
                tcs

                ; now copy file info back to caller's block
                ldx     #18-2
                ldy     #20-2
@llp:           lda     f:LOFILEBLK,X
                sta     [DPCOP_BHA],Y
                dey
                dey
                dex
                dex
                bne     @llp

                rtl

        .endproc