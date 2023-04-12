#!/usr/bin/env perl

# extracts map information into a noice symbols file

my $wait=0;

while(<>) {

	chomp;
	s/\r//;

	my $l = $_;

	if (!$wait && $l =~ /^Exports list by value:/)
	{	
		$wait = 1;
	} elsif ($wait && ($l =~ /^(\w+)\s+([0-9A-F]{6})\s+([A-Z]+)\s+((\w+)\s+([0-9A-F]{6})\s+([A-Z]+))?/)) {
		print "DEF $1 $2\n";
		if ($5) {
			print "DEF $5 $6\n";
		}
	} elsif ($l =~ /^---/ && $wait) {
		$wait++;
		if ($wait > 2)
		{
			exit;
		}
	}

}