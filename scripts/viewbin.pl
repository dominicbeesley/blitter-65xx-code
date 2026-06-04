#!/bin/env perl

use strict;

# A simple script to dump a binary file to screen as a bunch of characters to help diagnose bitmap files

binmode STDIN;

my $c;
while (sysread(STDIN, $c, 1) > 0) {
	my $buf;
	$buf = sprintf("%08b", ord($c));
	$buf =~ s/0/ /g;
	$buf =~ s/1/#/g;
	printf "$buf\n";
}