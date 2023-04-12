#!/usr/bin/env perl

# MIT License
# 
# Copyright (c) 2023 Dossytronics
# https://github.com/dominicbeesley/blitter-65xx-code
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# 



use strict;

use Convert::Color;
use Math::Trig;

print "\t\t.export _pal_rainbow\n";
print "_pal_rainbow:\n";

for (my $i = 0; $i < 360; $i+= 360/32) {
	my $rgb = Convert::Color->new(sprintf("hsv:%f,%f,%f", $i, 1, 1))->as_rgb;
	printf "\t\t.word\t\$%03X\n", 
		((15*$rgb->green) << 12) |
		((15*$rgb->blue) << 8) |
		(15*$rgb->red);
}

print "\t\t.export _sintab\n";
print "_sintab:\n";

for (my $i = 0; $i < 128; $i++) {
	printf "\t\t.byte\t\$%02X\n", (127*sin(2*pi()*$i/128)) & 0xFF;
}