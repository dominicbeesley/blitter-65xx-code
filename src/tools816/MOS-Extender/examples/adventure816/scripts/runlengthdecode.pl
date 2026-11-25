#!/usr/bin/env perl

use strict;

sub Usage {

	while (my $x = shift) {
		print STDERR "$x\n";
	}

	die "
runlengthdecode.pl <in.rle> <out.bin>\n
		";

}


while (scalar @ARGV && $ARGV[0] =~ /^-/) {

	my $sw = shift;

	if ($sw =~ /^-(-?)h/)
	{
		Usage;
	}
	else {
		die "unknown switch $sw";
	}
	
}

if (scalar @ARGV != 2) {
	Usage "Too few arguments"
}

my $fn_in=$ARGV[0];
my $fn_out=$ARGV[1];

open(my $fh_in, "<:raw:", $fn_in) or die $!;

my $ll;
my $err = read($fh_in, $ll, 4, 0);
die $! if not defined $err;
die "Zero length file!" if $err < 4;
$ll = unpack("L", $ll);

print "Unpack to length $ll\n";

open (my $fh_out, ">:raw:", $fn_out) or die $!;

my $ctr = 0;

while(1) {
	my $cmd;
	my $err = read($fh_in, $cmd, 1, 0);
	die $! if not defined $err;
	last if not $err;

	$cmd = ord($cmd);

	if ($cmd > 127) {
		$cmd = $cmd & 0x7F;
		my $buf;
		my $err = read($fh_in, $buf, $cmd+1, 0);
		die $! if not defined $err;
		die "Unexpected end of file" if $err != $cmd+1;

		print $fh_out $buf;
		$ctr+=$cmd+1;
	} else {		
		$cmd = $cmd & 0x7F;
		my $buf;
		my $err = read($fh_in, $buf, 1, 0);
		die $! if not defined $err;
		die "Unexpected end of file" if $err != 1;

		print $fh_out $buf x ($cmd + 1);
		$ctr+=$cmd+1;
	}

}

 
die "unexpected result" if ($ctr != $ll);
