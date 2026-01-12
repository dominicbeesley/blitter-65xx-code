; startup code for a BBC MOS ROM running "bare metal"

        .export         crt0_startup
        .export         _exit
        .export         __STARTUP__ : absolute = 1      ; Mark as startup

        .import         initlib, donelib
        .import         zerobss, callmain
        .import         __MAIN_START__, __MAIN_SIZE__   ; Linker generated
        .import         __STACKSIZE__                   ; from configure file

        .include        "zeropage.inc"


; ------------------------------------------------------------------------
; Startup code

.segment        "STARTUP"
crt0_startup:

; Save space by putting some of the start-up code in the ONCE segment,
; which can be re-used by the BSS segment, the heap and the C stack.

        jsr     initlib

; Clear the BSS data.

        jsr     zerobss

; Copy data

        jsr     copydata

; Push the command-line arguments; and, call main().

        jsr     callmain

; Back from main() [this is also the exit() entry]. Run the module destructors.

_exit:  pha                     ; Save the return code on stack
        jsr     donelib

        sei
HERE:   jmp     HERE

        rts

