#!/usr/bin/env perl

use strict;
use Getopt::Long;
use XML::LibXML;

# convert beebspriter XML to binary in Blitter linear form

my $mask;
my $symbols;
GetOptions(
	"mask" => \$mask,
	"symbols" => \$symbols
	) or Usage("Bad options $!");

my $fn_in = shift;
my $fn_out = shift;
my %fn_syms = ($symbols)?shift:undef;

($fn_in and -e $fn_in) or Usage "Missing input filename";
$fn_out or Usage "Missing output filename";
$fn_symbols or !$symbols or die "Missing symbols filename";

my $dom = XML::LibXML->load_xml(location => $fn_in);


sub Usage($) {
	my ($msg) = @_;

	print STDERR "ERROR: $msg\n";

print STDERR "Usage: beebspriter2blit.pl [..options..] <input> <output> [<symbols>]

Options:
	--mask	Output masks after the 
";

	exit 10;
}