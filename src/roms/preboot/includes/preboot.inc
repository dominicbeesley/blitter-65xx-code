SPI_BOOT_BASE	:=	$700000
ROM_IMAGE_BASE	:=	$720000
JIM_BOOT_BASE	:=	$7F0000


	.struct pb_romset
		length		.byte
		cpu		.byte
		title		.byte	32
		res0		.byte	30
	.endstruct

	.struct pb_rom
		slot		.byte
		ext_type	.byte
		rom_type	.byte
		cpu_type	.byte
		crc		.word
		res0		.byte	28
	.endstruct

PB_EXT_UK	:=	0
PB_EXT_ROM	:=	1
PB_EXT_MOS	:=	2

PB_CPU_6502	:=	0
PB_CPU_65C02	:=	1
PB_CPU_65816	:=	2
PB_CPU_6809	:=	4
PB_CPU_6309	:=	5
PB_CPU_z80	:=	8
PB_CPU_68xxx	:=	12
PB_CPU_6800	:=	16
PB_CPU_RiscV	:=	20
