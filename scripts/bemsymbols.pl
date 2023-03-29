#!/bin/perl

use strict;

my $ROMNO=@ARGV[0];


my @allsyms=();

while (<STDIN>) {
	my $l = $_;
	chomp $l;

	if ($l =~ /^al\s+([0-9A-F]{1,6})\s+\.(.*)$/i)
	{
		my $addr=$1;
		my $sym=$2;

		$addr =~ s/^00([0-9A-F]{4})$/$1/;

		if ($ROMNO && $ROMNO ne "" && $addr =~ /^[89AB][0-9A-F]{3}/i) {
			$addr = $ROMNO . ":" . $addr;
		}


		$sym =~ s/(\-)/_/g;

		push @allsyms, {
			sym => $sym,
			addr => $addr
		};

	}
}

my $parent;

foreach my $x (sort { $a->{addr} cmp $b->{addr} } @allsyms) 
{
	my $sym = $x->{sym};
	my $addr = $x->{addr};
	if ($sym =~ /^@(.*)/) {
		$sym = "$parent.$1";
	} else {
		$parent = $sym;
	}
	print "symbol $sym=$addr\n";

}