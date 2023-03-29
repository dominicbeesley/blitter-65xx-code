#!/bin/perl

use strict;
use warnings;
use XML::LibXML;
use POSIX;

use Data::Dumper qw(Dumper);

# read in a tiled map of a font and make a set of maps for each char
my $CHAR_H = 6;
my $CHAR_W = 6;
my $TILES_W = 10;
my $TILES_H = 5;
my $TILE_SZ_W = 16;
my $TILE_SZ_H = 32;

sub Usage {

	while (my $x = shift) {
		print STDERR "$x\n";
	}

	die "
fontnmap2asm.pl <in map> <ascii map> <out asm>\n
		";

}



my $fn_inmap = $ARGV[0];
my $fn_ascmap = $ARGV[1];
my $fn_o = $ARGV[2];

open my $fh_asc, "<", $fn_ascmap || Usage "Cannot open $fn_ascmap for input";
my $ascmap = do { local $/; <$fh_asc> };
$ascmap =~ s/(\r|\n|\s)//gi;

my $dom_inmap = XML::LibXML->new->parse_file($fn_inmap);

open my $fh_o, ">", $fn_o || Usage "Cannot open $fn_o for output";

my $layers = $dom_inmap->findnodes("/map/layer");

my $layer_count = $layers->size;

$layer_count == 1 || Usage "Must have exactly 1 layers!";

my $layer = $layers->get_node(1);
my $data = $layer->findvalue("data");

$data =~ s/^(\s*\n)+//;
$data =~ s/(\s*\n)+$//;

my $width = $layer->getAttribute("width") // 0;
my $height = $layer->getAttribute("height") // 0;

($width % $CHAR_W == 0) and ($height % $CHAR_H == 0) or die "map width and height must be an exact multiple of char sizes";

my @matrix = ();
my @lines = split /\n/, $data;
for (my $j = 0; $j < $height; $j++) {	
	my @cols = split /\,/, ($lines[$j] // '');
	for (my $i = 0; $i < $width; $i++)
	{
		my $n = $cols[$i] // 0;
		if ($n > 0) {
			$n--;
		}
		$matrix[$j][$i]=$n;
	}
}

#output as unpacked binary in down then right order

print $fh_o "\t\t.export _fontmap, _asc2font, _font_tile_bases\n";

print $fh_o "_fontmap:\n";

my $ix = 0;
for (my $j = 0; $j < $height; $j += $CHAR_H) 
{
	for (my $i = 0; $i < $width; $i+= $CHAR_W)
	{
		print $fh_o "fontmap_$ix:\n";
		for (my $ii = 0; $ii < $CHAR_W; $ii++) 
		{
			print $fh_o "\t\t.byte\t";
			my @vals = ();
			for (my $jj = 0 ; $jj < $CHAR_H; $jj++)
			{
				push @vals, sprintf "\$%02X", $matrix[$jj+$j][$ii+$i];
			}
			print $fh_o join(',',@vals) . "\n";
		}
		$ix++;
	}
}


my @ascmap2=();
$ix=0;
foreach my $c (split //, $ascmap) {
	my $a = ord(uc($c));
#	print "$c <$a> $ix\n";
	$ascmap2[$a]=$ix++;
}

print $fh_o "\n\n";

print $fh_o "_asc2font:";

for (my $i = 32; $i < 96; $i++) {

	if ($i % 8 == 0)
	{
		print $fh_o "\n\t\t.word\t";
	}
	else
	{
		print $fh_o ",";
	}
	my $n = $ascmap2[$i];
	if (!defined($n)) {
		print $fh_o "0";
	} else {
		print $fh_o "fontmap_$n";
	}
}

print $fh_o "\n";

print $fh_o "\n\n_font_tile_bases:\n";
my $b = 0;
my $sz = ceil($TILE_SZ_W / 2) * $TILE_SZ_H;
print "SIZE=$sz\n";
for (my $i = 0; $i < $TILES_W * $TILES_H; $i++) {
	printf $fh_o "\t\t.word\t\$%04X\n", $b;
	$b+=$sz;
}

