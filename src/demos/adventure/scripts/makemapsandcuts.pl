#!/bin/perl
use strict;
use warnings;
use XML::LibXML;

sub Usage {

	while (my $x = shift) {
		print STDERR "$x\n";
	}

	die "
makemaps.pl <in map> <back cuts out> <front cuts out> <out map bin>\n
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

if (scalar @ARGV != 4) {
	Usage "Too few arguments"
}

my $fn_inmap=$ARGV[0];
my $fn_backcuts=$ARGV[1];
my $fn_frontcuts=$ARGV[2];
my $fn_out=$ARGV[3];

my $dom_inmap = XML::LibXML->new->parse_file($fn_inmap);

my $tilesets = $dom_inmap->findnodes("/map/tileset");
$tilesets->size == 1 or die "can only handle one tileset which must be embedded";
my $tileset = $tilesets->get_node(1);

my $tilesz_x = $tileset->getAttribute("tilewidth") // 0;
my $tilesz_y = $tileset->getAttribute("tileheight") // 0;
my $tile_spacing = $tileset->getAttribute("spacing") // 0;
my $tile_margin = $tileset->getAttribute("margin") // 0;
my $tile_count = $tileset->getAttribute("tilecount") // 0;
my $tile_columns = $tileset->getAttribute("columns") // 0;
my $tile_gid_first = $tileset->getAttribute("firstgid") // 0;

$tilesz_x && $tilesz_y && $tile_count && $tile_columns || die "Cannot get tile sizes, count or columns";

my %tileproperties = ();
foreach my $tile ($tileset->findnodes("tile")) {
	my $tile_id = $tile->getAttribute("id");
	my %props = ();
	foreach my $prop ($tile->findnodes("properties/property"))
	{
		$props{$prop->getAttribute("name")} = $prop->getAttribute("value");
	}
	$tileproperties{$tile_id} = \%props;
}

my $layers = $dom_inmap->findnodes("/map/layer");

my $layer_count = $layers->size;

$layer_count == 2 || Usage "Must have exactly 2 layers!";

my $bin='';

my $layerwidth = -1;
my $layerheight = -1;

for (my $layernum = 1; $layernum <= 2; $layernum++) {

	my $fh_cuts;
	if ($layernum == 1)
	{
		open($fh_cuts, ">", $fn_backcuts) or die "cannot open $fn_backcuts for output";
	} else {
		open($fh_cuts, ">", $fn_frontcuts) or die "cannot open $fn_frontcuts for output";		
	}

	my %tmx_index_to_cut_index = ();
	my $ix_ctr = 0;

	my $layer = $layers->get_node($layernum);

	if ($layernum == 1)
	{
		$layerwidth = $layer->getAttribute('width');
		$layerheight = $layer->getAttribute('height');
	} else {
		$layerwidth = $layer->getAttribute('width') || die "layer $layernum has a different width";
		$layerheight = $layer->getAttribute('height') || die "layer $layernum has a different width";
	}


	my $data = $layer->findvalue("data");

	# parse map into a 32 rows of 32 cols

	my @lines = split /\n/, $data;
	my $j = 0;
	my $lno = 0;
	foreach my $l (@lines) {
		chomp $l;
		$lno++;
		if ($l =~ /^\s*([0-9]+(,|\s*$))+/) {
			my @cols = split /\,/, $l;
			scalar @cols == $layerwidth || die "line $lno of layer $layernum has different width ${\scalar(@cols)} <> $layerwidth $l";
			my $i = 0;
			foreach my $ix (@cols) {
				my $b=0x00;
				if ($ix != 0) {
					if (exists $tmx_index_to_cut_index{$ix}) {
						$b = $tmx_index_to_cut_index{$ix}
					} else {
						$b = $tmx_index_to_cut_index{$ix} = ++$ix_ctr;
						my $x = $tile_margin + (($ix - $tile_gid_first) % $tile_columns) * ($tile_spacing + $tilesz_x);
						my $y = $tile_margin + int(($ix - $tile_gid_first) / $tile_columns) * ($tile_spacing + $tilesz_y);
						print $fh_cuts "<move x=\"$x\" y=\"$y\" /><cut x=\"1\" y=\"1\" dir=\"rd\" />\n";
					}

				}

				my $nocolide = $tileproperties{$ix-$tile_gid_first}->{nocollide};
				if ($nocolide && $nocolide eq "true") {
					$b |= 0x80;
					print "NOCOLLIDE: $ix @ $i x $j $b\n";
				}

				$bin .= chr($b);
				$i++;
			}
			$j++;
		} elsif ($l ne '') {
			Usage("Non-blank line contains bad data $l");
		}
	}

	$fh_cuts->close;
}

open(my $bin_out, '>:raw', $fn_out) or die "Unable to open: $!";
print $bin_out $bin;