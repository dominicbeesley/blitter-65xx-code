#!/usr/bin/env bash

cat <<EOF >"$1"
.MACRO		VERSION_DATE	
		.byte	"$(date +%Y-%m-%d,%H%M)"
.ENDMACRO
EOF