#!/usr/bin/env bash

#fail on first error
set -Exe
#fail on all items in pipes
set -o pipefail

tmp=$('mktemp')

trap "tidyup" ERR

function tidyup {
	if [[ -e "$tmp" ]]; then
		rm "$tmp"
	fi
	exit 1;
}

if [[ $# != 5 ]]; then 
	echo "Incorrect number of arguments" 1>2& 
	exit 1 
fi

pal="$1"
charcuts="$2"
backcuts="$3"
frontcuts="$4"
outfile="$5"

if [[ ! -e "$pal" ]]; then 
	echo "Missing palette file : \"$pal\"" 1>2&
	exit 1
fi
if [[ ! -e "$charcuts" ]]; then
	echo "Missing charcuts file : \"$charcuts\"" 1>2&
	exit 1
fi
if [[ ! -e "$backcuts" ]]; then 
	echo "Missing backcuts file : \"$backcuts\"" 1>2&
	 exit 1
fi
if [[ ! -e "$frontcuts" ]]; then
	echo "Missing frontcuts file : \"$frontcuts\"" 1>2&
	exit 1
fi



echo '<?xml version="1.0" ?>' > "$tmp"
echo '<tile-cutter>' >> "$tmp"

cat "$pal" >> "$tmp"

cat "$charcuts" >> "$tmp"

echo '<dest file="over-back.til" size-x="16" size-y="24" mask="n">' >> "$tmp"
echo '<source file="src-graphics/Overworld16x24.png" />' >> "$tmp"
cat "$backcuts" >> "$tmp"
echo '</dest>' >> "$tmp"

echo '<dest file="over-front.til" size-x="16" size-y="24" mask="y">' >> "$tmp"
echo '<source file="src-graphics/Overworld16x24.png" />' >> "$tmp"
cat "$frontcuts" >> "$tmp"
echo '</dest>' >> "$tmp"


echo '</tile-cutter>' >> "$tmp"

mv "$tmp" "$outfile"
