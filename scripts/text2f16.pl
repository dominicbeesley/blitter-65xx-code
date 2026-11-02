#!/usr/bin/env perl

# text2f16 - rebuild an 8x16 .F16 font from a text file made by f16totext.pl
#
# '#' and '!' both mean pixel on. Nothing is written unless the whole text file
# is valid.
#

use strict;
use warnings;

use constant GLYPHS => 256;
use constant ROWS   => 16;
use constant COLS   => 8;

sub Usage {
	my ($msg, $exit) = @_;

	my $fh = ($exit)?*STDERR:*STDOUT;

	print $fh "
text2f16.pl <text file> <font file>

Reads text in the format written by f16totext.pl and writes a 4096 byte font.
An existing font file is overwritten, but only if the text file is valid.
";

	if ($msg) {
		print $fh "$msg\n";
	}

	if ($exit) {
		exit $exit;
	}
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

if (scalar @ARGV != 2) {
	Usage("incorrect number of arguments", 1);
}

my ($fn_in, $fn_out) = @ARGV;

open(my $fh_in, "<", $fn_in) or die "Cannot open input file \"$fn_in\" : $!\n";

my @errors;
my @font;		# glyph code => array of row bytes
my %seen_at;		# glyph code => line number of its header

my $in_glyph = 0;	# a header has been read
my $code;		# code of the current glyph, undef if its header was bad
my $header_line;
my $row_count = 0;

sub EndGlyph {
	if ($in_glyph && $row_count < ROWS) {
		push @errors, sprintf("line %d: glyph has %d rows, expected %d", $header_line, $row_count, ROWS);
	}
}

while (my $line = <$fh_in>) {

	my $n = $.;

	$line =~ s/^\xEF\xBB\xBF// if $n == 1;	# BOM from a Windows editor
	$line =~ s/;.*//s;
	$line =~ s/^\s+|\s+$//g;

	next if $line eq "";

	if ($line =~ /^CHAR\b/i) {

		EndGlyph();

		$in_glyph = 1;
		$code = undef;
		$header_line = $n;
		$row_count = 0;

		my ($digits) = $line =~ /^CHAR\s+0x([0-9A-Fa-f]+)$/i;

		if (!defined $digits) {
			push @errors, "line $n: malformed header \"$line\", expected CHAR 0xNN";
		}
		elsif ($digits !~ /^0*[0-9A-Fa-f]{1,2}$/) {
			push @errors, "line $n: code in \"$line\" is outside 0x00-0xFF";
		}
		else {
			my $c = hex($digits);

			if (exists $seen_at{$c}) {
				push @errors, sprintf("line %d: duplicate glyph 0x%02X, first defined on line %d", $n, $c, $seen_at{$c});
			}
			else {
				$seen_at{$c} = $n;
				$code = $c;
				$font[$c] = [ (0) x ROWS ];
			}
		}

		next;
	}

	if (!$in_glyph) {
		push @errors, "line $n: \"$line\" is before the first CHAR header";
		next;
	}

	$row_count++;

	if ($row_count > ROWS) {
		push @errors, sprintf("line %d: too many rows in the glyph starting on line %d, expected %d", $n, $header_line, ROWS);
		next;
	}

	if (length($line) != COLS) {
		push @errors, sprintf("line %d: row \"%s\" is %d characters, expected %d", $n, $line, length($line), COLS);
		next;
	}

	if ($line =~ /([^#!.])/) {
		push @errors, "line $n: row \"$line\" has invalid character '$1', expected '#', '!' or '.'";
		next;
	}

	if (defined $code) {
		(my $bits = $line) =~ tr/#!./110/;
		$font[$code][$row_count - 1] = oct("0b$bits");
	}
}

EndGlyph();

close $fh_in;

my @missing = grep { !exists $seen_at{$_} } 0 .. GLYPHS - 1;

if (@missing) {
	push @errors, sprintf("%d missing glyph(s): %s", scalar @missing, join(" ", map { sprintf("0x%02X", $_) } @missing));
}

if (@errors) {
	print STDERR "$fn_in: $_\n" for @errors;
	print STDERR "$fn_in: " . scalar(@errors) . " error(s), \"$fn_out\" not written\n";
	exit 1;
}

open(my $fh_out, ">:raw", $fn_out) or die "Cannot open output file \"$fn_out\" : $!\n";
print $fh_out pack("C*", map { @$_ } @font) or die "Cannot write \"$fn_out\" : $!\n";
close $fh_out or die "Cannot write \"$fn_out\" : $!\n";
