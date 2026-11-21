
                .export errFileNotFound

		.export	errOPWRAinv
                .export errNotImpl
                .export errNotImplOp
                .export errNotOpened



ernFileNotFound	:= $0D6

ernOPWRAinv	:= $100
ernNotImpl	:= $101
ernNotOpened	:= $102
ernNotImplOp	:= $103

                .segment        "NATHANDLER"
errFileNotFound:.dword	ernFileNotFound
                .byte   "File not found", 0

errOPWRAinv:    .dword	ernOPWRAinv
                .byte "OPWRA: invalid termination option",0

errNotImpl:     .dword	ernNotImpl
                .byte "COP not Implemented",0

errNotOpened:   .dword	ernNotOpened
                .byte "File not opened",0

errNotImplOp:   .dword	ernNotImplOp
                .byte "COP reason code not Implemented",0

