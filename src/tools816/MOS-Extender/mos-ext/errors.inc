

                .import errFileNotFound

		.import	errOPWRAinv
                .import errNotImpl
                .import errNotImplOp
                .import errNotOpened

		.macro ERRV addr
		ldx	#^addr
                .if .asize = 8
                lda     #>addr
                xba
                lda     #<addr
                .else
                lda     #.loword(addr)
                .endif
                sep     #$40
                .endmacro