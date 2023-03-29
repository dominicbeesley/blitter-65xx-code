#!/bin/bash

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


echo '<?xml version="1.0" ?>' > "$tmp"
echo '<tile-cutter>' >> "$tmp"

cat src-graphics/palette.xml >> "$tmp"

cat src-graphics/character.cutdefs >> "$tmp"

echo '<dest file="over-back.til" size-x="16" size-y="24" mask="n">' >> "$tmp"
echo '<source file="../../src-graphics/overworld16x24.png" />' >> "$tmp"
cat build/tiles/over-back.cutdefs >> "$tmp"
echo '</dest>' >> "$tmp"

echo '<dest file="over-front.til" size-x="16" size-y="24" mask="y">' >> "$tmp"
echo '<source file="../../src-graphics/overworld16x24.png" />' >> "$tmp"
cat build/tiles/over-front.cutdefs >> "$tmp"
echo '</dest>' >> "$tmp"


echo '</tile-cutter>' >> "$tmp"

mv "$tmp" "build/tiles/tile-cutter.xml"