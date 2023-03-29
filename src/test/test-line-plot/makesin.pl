#!/bin/perl

use strict;
use Math::Trig;

my $j = 0;
for (my $i=0; $i<256; $i++) {
	if ($j++ % 16 == 0) {
		print "\n\t";
	} else {
		print ", ";
	}
	printf "\$%02X", (128 + 127*sin(2*pi*$i/256)) & 255;
}

print "\n";