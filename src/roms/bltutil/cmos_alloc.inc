.ifndef __CMOS_ALLOC_INC__
.define __CMOS_ALLOC_INC__

DEV_BLTUTIL_CMOS_EEPROM		= $A0	; device number for CMOS/EEPROM
BLTUTIL_CMOS_PAGE_FIRMWARE 	= $11	; page in CMOS / Flash EEPROM for BLTUTIL's config

BLTUTIL_CMOS_FW_ROM_THROT	= $00	; offset to per-rom-throttle arranged as map 0 0..7, map 0 8..15, map 1 0..7, map 1 8..15
BLTUTIL_CMOS_FW_CPU_THROT   	= $04   ; offset to two bytes for map 0,1
CMOSBITS_CPU_THROT		= $80	
.endif