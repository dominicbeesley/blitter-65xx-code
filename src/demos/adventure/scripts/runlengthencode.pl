#!/usr/bin/env perl

use strict;

sub Usage {

	while (my $x = shift) {
		print STDERR "$x\n";
	}

	die "
runlengthencode.pl <in.bin> <out.rle>\n
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

open(my $fh_in, "<:raw:", $fn_in) or die "Cannot open input file $fn_in";

my $bin = '';

while (1) {
	my $err = read($fh_in, $bin, 256, length($bin));
	die $! if not defined $err;
	last if not $err;
}

close $fh_in;

print "Input length = ${\ length($bin) }\n";

my $ptr = 0;
my @stack = ();
while ($ptr < length($bin)) {

	my $b = substr($bin, $ptr++, 1);
#	print "Byte read ${\ ord($b) }\n";

	my $p = pop(@stack);
	if (!$p) {		
		push(@stack, { type => 'lit', value => $b });
#		print "FIRST\n";
	} else {
		my $n;

#		print "Prev: $p->{type}\n";

		if ($p->{type} eq 'lit') {
			#check if last byte same as this
			my $pv = substr($p->{value}, -1);
#			print "PREV tail= ${\ ord($pv) }\n";
			if (length($p->{value}) >= 128) {
				push @stack, $p;
				push @stack, { type => 'lit', value => $b };
			} elsif ($pv eq $b) {
#				print "SAME\n";
				if (length($p->{value}) == 1)
				{
#					print "discard lit\n";
					push @stack, { type=>'rle', value=> $b, len => 2};
#					print "new RLE\n";
				} else {
#					print "Removing last literal byte from prev\n";
					push @stack, { type=> 'lit', value=> substr($p->{value}, 0, length($p->{value})-1) };
					push @stack, { type=>'rle', value=> $b, len => 2};
#					print "new RLE\n";
				}
			} else {
#				print "DIFF\n";
				push @stack, { type => 'lit', value => $p->{value} . $b };
			}
		} else {
			if ($p->{value} eq $b && $p->{len} < 128) {
#				print "Increase run length\n";
				$p->{len}++;
				push @stack, $p;
			} else {
				push @stack, $p;
#				print "new lit\n";
				push @stack, { type => 'lit', value => $b };
			}
		}
	}

}

# remove rle of length 2 sandwiched betweem two lits
my $i = 1;
while ($i+1 < scalar @stack)
{
	my $a = @stack[$i-1];
	my $b = @stack[$i];
	my $c = @stack[$i+1];
	if (
		($b->{type} eq 'rle')
		and ($b->{len} == 2)
		and ($a->{type} eq 'lit')
		and ($c->{type} eq 'lit')
		and (2+length($a->{value})+length($c->{value})) <= 128
		) 
	{
		print "TRIM $i\n";
		splice @stack, $i-1, 3, { type=> 'lit', value => $a->{value} . $b->{value} . $b->{value} . $c->{value} };
	} else {
		$i++;
	}
}

for my $k (@stack) {
	print "$k->{type}";	
	if ( $k->{type} eq 'lit' )
	{
		print " ${\ length($k->{value}) }\n";
	} else {
		print " $k->{len}\n";
	}
}


open (my $fh_out, ">:raw:", $fn_out) or die $!;

print $fh_out pack("L", length($bin));

for my $k (@stack) {
	if ( $k->{type} eq 'lit' )
	{
		print $fh_out chr(128+length($k->{value})-1);
		print $fh_out $k->{value};
	} else {
		print $fh_out chr($k->{len}-1);
		print $fh_out $k->{value};
	}
}

