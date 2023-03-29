#!/usr/bin/perl

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

use Image::PNG::Libpng;
use Image::PNG::Const ':all';
use strict;

my $fn = shift;
my $ofn = shift;


use Image::PNG::Libpng ':all';
my $png = create_read_struct ();
open my $file, '<:raw', $fn or die $!;
$png->init_io ($file);
$png->read_png ();
close $file;

# Get all valid chunks
my $valid = $png->get_valid ();
my @valid_chunks = sort grep {$valid->{$_}} keys %$valid;
print "Valid chunks are ", join (", ", @valid_chunks), "\n";
# Print image information
my $header = $png->get_IHDR ();
for my $k (keys %$header) {
    print "$k: $header->{$k}\n";
}

($header->{width} == 640 && $header->{height} == 400) || die "Image must be 640x400";

($png->get_IHDR->{color_type} == PNG_COLOR_TYPE_PALETTE) || die "Image must be palette";

my $colours = $png->get_PLTE ();

scalar @{$colours} == 2 || die "Must have 2 colour palette";


open my $out_file, ">:raw", $ofn or die $!;

for (my $i = 0; $i <= 1; $i++) {
	for (my $cr = 0; $cr < 25; $cr++) {
		my @char_row_bytes;
		for (my $ra = 0; $ra < 8; $ra++) {
			my $r = $png->get_rows()->[$i + $ra * 2 + $cr * 16];
			for (my $x = 0; $x < 80; $x++) {
				@char_row_bytes[$ra + $x*8] = ord(substr($r,$x,1));	
			}
		}
		print $out_file pack("C*", @char_row_bytes);
	}

	#padding
	print $out_file chr(0)x(768/2);
}



close $out_file;