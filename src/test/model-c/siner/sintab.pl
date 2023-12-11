#!/usr/bin/env perl
use Math::Trig;
use Math::Trig ":pi";

my $n = shift;

$n > 16 or die "Bad n";

print "\t\t.rodata\n";
print "\t\t.export sintab\n";

print "sintab:\n";

for (my $i=0; $i < $n; $i++) {
	if (($i % 8) == 0)
	{
		print "\n\t\t.word\t";
	} else {
		print ", ";
	}
	printf "\$%04X", (32767*sin((2.0*pi*$i)/$n)) & 0xFFFF;
}

print "\n";