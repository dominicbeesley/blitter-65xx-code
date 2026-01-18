; startup code for a BBC MOS ROM running "bare metal"

        .export         crt0_startup
        .export         _exit
        .export         __STARTUP__ : absolute = 1      ; Mark as startup

        .import         initlib, donelib
        .import         zerobss, callmain
        .import         __MAIN_START__, __MAIN_SIZE__   ; Linker generated
        .import         __STACK_START__, __STACK_SIZE__ ; from segment

        .importzp       sp

        .include        "zeropage.inc"


; ------------------------------------------------------------------------
; Startup code

.segment        "STARTUP"
crt0_startup:
        
        lda     #<(__STACK_START__ + __STACK_SIZE__)
        sta     sp
        lda     #>(__STACK_START__ + __STACK_SIZE__)
        sta     sp+1

; Copy data

        jsr     copydata

; Clear the BSS data.

        jsr     zerobss

; Save space by putting some of the start-up code in the ONCE segment,
; which can be re-used by the BSS segment, the heap and the C stack.

        jsr     initlib



; Push the command-line arguments; and, call main().

        jsr     callmain

; Back from main() [this is also the exit() entry]. Run the module destructors.

_exit:  pha                     ; Save the return code on stack
        jsr     donelib

        sei
HERE:   jmp     HERE

        ;TODO: force reset and ROM switch here
        ;TODO: restore memory?
        ;TODO: restore SYS VIA IER for hard/cold/warm reset

        rts

