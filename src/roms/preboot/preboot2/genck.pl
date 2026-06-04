#!/usr/bin/env perl

# A script to add a 1 byte CHECKSUM and 3 BYTE TAG to preboot SPI images

# expects file to consist of a number of 16K roms with CKSUM at offset 0x3FF6

my $OFF = 0x3FF6;
my $TAG = "PB!";
my $BLOCKSIZE = 0x4000;

my $fn = shift or die("Missing filename");

(my $sz = -s $fn) or die "Cannot get size of file \"$fn\" : $!";

($sz % $BLOCKSIZE)==0 or die "Input file must be a multiple of $BLOCKSIZE bytes long";

my $blocks = int($sz / $BLOCKSIZE);

print "SIZE:$sz : $blocks\n";

open(my $fh, "+<:raw:", $fn) or die "Cannot open \"$fn\" for read/write : $!";

for (my $b = 0; $b < $blocks; $b++) {
	my $off = $b * $BLOCKSIZE;
	my $buf;
	seek($fh, $off, 0);
	read($fh, $buf, $BLOCKSIZE) == $BLOCKSIZE or die "Couldn't read $BLOCKSIZE bytes at offset $off : $!";

	substr($buf, $OFF, 3) = $TAG;
	substr($buf, $OFF + 3, 1) = chr(0);

	my $ck = 0;
	for (my $i = 0; $i < $BLOCKSIZE; $i++) {
		$ck += ord(substr($buf, $i, 1));
	}

	substr($buf, $OFF + 3, 1) = chr((-$ck) & 0xFF);

	seek($fh, $off, 0);
	print $fh $buf;
}


close $fh;
