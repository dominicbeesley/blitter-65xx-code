

                .code

                .import callmos_brk
                .import callmos_active

; Handle EMU-mode BRK
; We are either in callmos, wrapping a call nat2emu of a MOS/ROM function
; in which case the callmos_xx variables will be set and we should exit via 
; them in native mode.
; Or else something funky is going on and the native program has somehow 
; entered emu mode or an interrupt has causes a BRK. In either case we
; will reset the emu mode stack and re-enter native mode then pass on to the
; native mode error handler 

; TODO: - not sure how a non-callmos emu BRK might happen, think of 
; reasonable scenarios to test.


                ;.emu
                .global emu_brk
                .proc emu_brk:near

                bit     callmos_active
                bpl     @nocallmos
                jmp     callmos_brk
@nocallmos:     
                ; TODO: return to native program via registered error handler
HERE:           jmp     HERE

                .endproc


                .bss

