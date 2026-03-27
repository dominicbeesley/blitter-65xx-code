

	.export _main_head

	.segment "OVERLAY0_RO"



.ifdef C20K
_main_head:
	.incbin "main_head.mo7"
.endif

.ifdef MK2
_main_head:
	.incbin "main_head.mk2.mo7"
.endif
