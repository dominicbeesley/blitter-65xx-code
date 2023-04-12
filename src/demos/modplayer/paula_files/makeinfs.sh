#!/usr/bin/env bash

for x in *.mod; do 
	y=${x^^}
	y=${y//_/}
	y=${y//[:space:]/}
	echo M.${y:0:7} > $x.inf
done
