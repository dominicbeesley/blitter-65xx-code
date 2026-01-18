
	.export _KEYBOARD_TRANS_TABLE
	
	.segment "keyrodata"
_KEYBOARD_TRANS_TABLE:
		.byte	$71,$33,$34,$35,$84,$38,$87,$2d,$5e,$8c	; q ,3 ,4 ,5 ,f4,8 ,f7,- ,^ ,rt
		.res 6
		.byte	$80,$77,$65,$74,$37,$69,$39,$30,$5f,$8e	; f0,w ,e ,t ,7 ,i ,9 ,0 ,_ ,lft
		.res 6
		.byte	$31,$32,$64,$72,$36,$75,$6f,$70,$5b,$8f	; 1 ,2 ,d ,r ,6 ,u ,o ,p ,[ ,dn
		.res 6
		.byte	$01,$61,$78,$66,$79,$6a,$6b,$40,$3a,$0d	; CL,a ,x ,f ,y ,j ,k ,@ ,: ,RETN  N.B CL=CAPS LOCK
		.res 6	
		.byte	$02,$73,$63,$67,$68,$6e,$6c,$3b,$5d,$7f	; SL,s ,c ,g ,h ,n ,l ,; ,] ,DEL N.B. SL=SHIFT LOCK
		.res 6
		.byte	$00,$7a,$20,$76,$62,$6d,$2c,$2e,$2f,$8b	; TAB,Z ,SPACE,V ,b ,m ,, ,. ,/ ,copy
		.res 6
		.byte	$1b,$81,$82,$83,$85,$86,$88,$89,$5c,$8d	; ESC,f1,f2,f3,f5,f6,f8,f9,\ ,								