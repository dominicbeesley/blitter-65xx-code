#!/usr/bin/env perl

# f16totext - convert an 8x16 .F16 font to a text file of character cells that
# can be edited by hand and rebuilt with text2f16.pl
#
# Set pixels with no set pixel on the row above or below, at the same column or
# one to the left or right, are shown as '!' as they dazzle when interlaced.
#

use strict;
use warnings;

use File::Basename;

use constant GLYPHS => 256;
use constant ROWS   => 16;

sub Usage {
	my ($msg, $exit) = @_;

	my $fh = ($exit)?*STDERR:*STDOUT;

	print $fh "
f16totext.pl <font file>

The text is written to stdout. Each glyph is a CHAR header and 16 rows of:
	#   pixel on
	!   pixel on, with no neighbour above or below (dazzles when interlaced)
	.   pixel off
";

	if ($msg) {
		print $fh "$msg\n";
	}

	if ($exit) {
		exit $exit;
	}
}

# Mask of the columns that a pixel in a row above or below would match, which
# is its own column and one either side
sub Spread {
	my ($row) = @_;

	return ($row | ($row << 1) | ($row >> 1)) & 0xFF;
}

sub RowText {
	my ($row, $above, $below) = @_;

	my $matches = Spread($above) | Spread($below);

	my $s = "";
	for (my $bit = 0x80; $bit; $bit >>= 1) {
		$s .= !($row & $bit) ? "." : ($matches & $bit) ? "#" : "!";
	}

	return $s;
}

##############################################################################
#################################### main ####################################
##############################################################################

while (scalar @ARGV && $ARGV[0] =~ /^-/) {

	my $sw = shift;

	if ($sw =~ /^-(-?)h/)
	{
		Usage();
		exit 0;
	}
	else {
		Usage("unknown switch $sw", 1);
	}

}

if (scalar @ARGV != 1) {
	Usage("incorrect number of arguments", 1);
}

my $fn_in = shift;

open(my $fh_in, "<:raw", $fn_in) or die "Cannot open input file \"$fn_in\" : $!\n";
my $buf = do { local $/; <$fh_in> };
close $fh_in;

$buf //= "";

my $expected = GLYPHS * ROWS;
my $l = length($buf);
$l == $expected or die "\"$fn_in\" is $l bytes, expected $expected\n";

my @bin = unpack("C*", $buf);

print "; " . basename($fn_in) . " - 256 glyphs, 8x16.\n";
print "; '#' = pixel on, '.' = pixel off, '!' = pixel on with no neighbour above or below (dazzles when interlaced).\n";

for (my $c = 0; $c < GLYPHS; $c++) {

	printf "\nCHAR 0x%02X", $c;
	printf " ; '%c'", $c if ($c >= 0x20 && $c <= 0x7E);
	print "\n";

	my @rows = @bin[$c * ROWS .. $c * ROWS + ROWS - 1];

	for (my $y = 0; $y < ROWS; $y++) {
		my $above = ($y > 0) ? $rows[$y - 1] : 0;
		my $below = ($y < ROWS - 1) ? $rows[$y + 1] : 0;

		print RowText($rows[$y], $above, $below) . "\n";
	}
}
