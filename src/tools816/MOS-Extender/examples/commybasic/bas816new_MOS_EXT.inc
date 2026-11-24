
		.import	__SHIMS_SIZE__, __SHIMS_RUN__, __SHIMS_LOAD__
		.import	__NATVEC_SIZE__, __NATVEC_RUN__, __NATVEC_LOAD__

OPTIMIZE_SIZE := 1
BUGFIX := 1

;=========================================================================
; MOS-EXT specifics
;=========================================================================

MOS_ZP_ESC_FLAG			:=  $0000FF

MOS_DP_SAVE				:=  $01FBFC		; stash original DP so we can recover!
MOS_ERROR_BUF			:=  $01FC00		; room for a copy of most recent error in 32-bit err no format
MOS_ARITH_WKSPC			:=	$01FD00		; just below page
MOS_BASIC_MEMBASE		:=	$020000		; next bank after basic TODO: allocate/calculate
MOS_BASIC_MEMSZ			:=	$080000		; 8 banks



