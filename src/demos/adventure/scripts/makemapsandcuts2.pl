#!/bin/perl
use strict;
use warnings;
use XML::LibXML;
use File::Spec::Functions 'catfile';
use File::Basename;
use Data::Dumper;

# This script takes a set of "Tiled" maps (including layers) and tilesets and produces the following sets of files:
# CutDefs: XML definitions to feed to the tilecutter script to cut up the 
#		source graphics into Blitter compatible bitmaps there are two sets of
#		cutdefs produced, one for back (non-masked) layer and another for the
#		front (masked) layer   
# Binary maps: For each source map there are produced three binary game maps, 
#		one for each back/front layer and one for properties each has one
#		byte per location
#		The bytes in the front / back layers are the indices to the images
#       in the bitmaps produced by the tilecutter script
#
# Mapping tile ids
# ================
# The ids for tiles used require some explanation as they have differing bases
# depending on the context
# Tileset-id: "_tsid" - these are indexed by column then row from the top-left
# of a tileset's image. These are scoped only within a specific tileset. 
# Numbering (re)starts at 1 for each tileset
# Global-id: "_gid" - these are scoped to a map. Numbering starts at 1 for 
# tilese from the first tileset referenced by a map then at 
# 1+{1st tileset count} for the 2nd and so on. The numbering in source map 
# data is in global order
# Layer-id: "_lid" - these are scoped to a layer (front/back) and start at 1
# these are the ids that are used in the output binary maps - these ids are 
# shared between all maps when output in binary but not between layers!
# The _lid is effectively an index into the relevant bitmap


sub Usage {

	while (my $x = shift) {
		print STDERR "$x\n";
	}

	die "
makemaps.pl <output directory> <group name> <maps>...\n
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

if (scalar @ARGV < 2) {
	Usage "Too few arguments"
}

my $dir_out=shift or Usage "No output directory specified";

-d "$dir_out" or Usage  "Output directory \"$dir_out\" does not exist";

my $group_name=shift or Usage "No group namespecified";

my $fn_backcuts=catfile($dir_out, "back.cutdefs");
my $fn_frontcuts=catfile($dir_out, "front.cutdefs");

my $tilesz_x = -1;
my $tilesz_y = -1;
my %tilesets = ();		# hash of tilesets by source filename or #EMBED#{n}
my $embed = 0;			# highest {n} of embeded tilesets

my @maps = ();

foreach my $fn_inmap (@ARGV) {
	my $bn = fileparse($fn_inmap, qr/\.[^.]*/);

	print "===MAP: $bn\n";

	my ($x,$indir,$y) = fileparse($fn_inmap);

	$indir = File::Spec->rel2abs(File::Spec->canonpath($indir));

	print "INPUTDIR = $indir\n";

	my $dom_intmx = XML::LibXML->new->parse_file($fn_inmap);

	my $dom_inmap = $dom_intmx->documentElement;

	$dom_inmap->localname eq "map" or die "Missing map element in tmx $fn_inmap";

	my $map = do_map($dom_inmap, $indir);
	$map->{name} = $fn_inmap;
	$map->{base_name} = $bn;
	push @maps, $map;
}

# now we've got all the maps read in, for each layer make the layer id sets
for (my $layer = 0; $layer <2; $layer++) {
	
	foreach my $ts (values %tilesets) {
		$ts->{usages} = {};
	}


	# build up a list of used tiles in each tileset
	foreach my $map (@maps) {
		my $l = $map->{layers}[$layer];

		foreach my $t (@$l) {
			my $tsid = $t->{tsid};
			if ($tsid) {
				my $ts = $t->{ts};
				my $u = $ts->{usages};
				if (exists $u->{$tsid}) {
					$u->{$tsid}->{count} = $u->{$tsid}->{count} + 1;
				} else {
					$u->{$tsid} = {
						count => 1,
					};
				}
			}
		}
	}

	my $ix = 1;
	# assigned indices to the tiles these should be in tileset order
	# for sane cut definitions
	my @cuts = ();
	foreach my $ts (values %tilesets) {
		foreach my $tsid (sort { $a <=> $b } keys %{$ts->{usages}}) {
			$ts->{usages}->{$tsid}->{lid} = $ix++;
		}
	}

	$ix <= 255 or die "Layer $layer - too many different tiles ($ix)";

	print "LAYER $layer has " . ($ix - 1) . " tiles\n";

	# construct the final game map for each layer

	foreach my $map (@maps) {

		my $l = $map->{layers}[$layer];

		my @olayer = ();

		foreach my $t (@$l) {
			my $tsid = $t->{tsid};
			if ($tsid) {
				my $ts = $t->{ts};
				my $u = $ts->{usages};
				if (exists $u->{$tsid}) {
					push @olayer, $u->{$tsid}->{lid};
				} else {
					die "UNEX: missing usage item for $tsid in $layer of map ${$map->{name}}";
				}
			} else {
				push @olayer, 0;
			}
		}

		# save binary map layer
		push @{$map->{outlayers}}, \@olayer;

	}

}

my %propflags = (
	nocollide => 0x80
	);

foreach my $map (@maps) {
	# make header file
	my $fn_map_h = catfile($dir_out, $map->{base_name} . ".h");
	open(my $fh_map_h, ">", $fn_map_h) or die "Cannot open $fn_map_h for output : $!";
	my $map_h_pre = "MAP_" . uc($map->{base_name}) . "_";
	printf $fh_map_h "#define %s_width %s\n", $map_h_pre, $map->{width};
	printf $fh_map_h "#define %s_height %s\n", $map_h_pre, $map->{height};
	close $fh_map_h;

	# save binary map layer
	my $fn_map = catfile($dir_out, $map->{base_name} . ".map");
	open(my $fh_map, ">:raw:", $fn_map) or die "Cannot open $fn_map for output : $!";


	foreach my $l (@{$map->{outlayers}}) {			
		print $fh_map pack("C*", @$l);
	}

	# the properties layer
	my $ix = 0;
	for (my $row = 0; $row < $map->{height}; $row++) {
		for (my $col = 0; $col < $map->{width}; $col++) {
			my $v = 0;
			foreach my $l (@{$map->{layers}}) {
				my $x = $l->[$ix];
				my $tsid = $x->{tsid};
				if ($tsid) {
					my $props = $x->{ts}->{props}->{$tsid};
					foreach my $p (keys %{$props}) {
						if ($props->{$p} eq "true") {
							$v |= $propflags{$p};
						}
					}		
				}
				print $fh_map pack("C", $v);
				$ix++;
			}
		}
	}

	close $fh_map;
}

#print Dumper(@maps);

sub do_map {
	my ($dom_inmap, $indir) = @_;
	
	my $gid = 1;

	#look for and process tilesets
	my @tsmap = ();
	foreach my $dom_ts ($dom_inmap->findnodes("tileset")) {
		my $ts = get_tileset($dom_ts, $indir);	
		my %tsc = ( firstgid => $gid, lastgid => $gid + $ts->{tile_count} - 1, tileset => $ts );
		$gid+=$ts->{tile_count};
		push @tsmap, \%tsc;
	}

	my $width = $dom_inmap->getAttribute("width") // 0;
	my $height = $dom_inmap->getAttribute("height") // 0;


	my @maplayers = ();	# this will contain the layers, each layer contains an array of arrays of hashes

	#read in the map's layers

	my $dom_layers = $dom_inmap->findnodes("layer");
	
	my $layer_count = $dom_layers->size;
	
	$layer_count == 2 or Usage "Must have exactly 2 layers!";
		
	
	for (my $layernum = 1; $layernum <= 2; $layernum++) {
		my $dom_layer = $dom_layers->get_node($layernum);

		my @rawlayer = ();	# the layer's data as an array of arrays of gids
	 
 		my $layerwidth = $dom_layer->getAttribute('width');
		my $layerheight = $dom_layer->getAttribute('height');
 		$layerwidth == $width || die "layer $layernum has a different width to map";
 		$layerheight == $height || die "layer $layernum has a different height to map";
	  
	 	my $data = $dom_layer->findvalue("data");
	 
	 	# parse map into a 32 rows of 32 cols
	 
	 	my @lines = split /\n/, $data;
	 	my $j = 0;
	 	my $lno = 0;
	 	foreach my $l (@lines) {
			if ($l =~ /^\s*([0-9]+(,|\s*$))+/) {
		 		my @cols = split /\s*\,\s*/, $l;
		 		scalar @cols == $layerwidth || die "line $lno of layer $layernum has different width ${\scalar(@cols)} <> $layerwidth $l";
				push @rawlayer, \@cols;
		 	}
		}

		scalar @rawlayer == $layerheight or die "Layer $layernum has wrong number of rows in map data";

		# remap the raw layer to tileset pointer, tileset index

		my @maplayer = map { 
			my @x = map {
				# for each gid find a tileset 
				my $gid = $_;
				if (!$gid) {
					{ 
						gid => 0, 
						tsid => 0, 
						ts => undef
					};
				} else {
					my @tscs = grep { $gid >= $_->{firstgid} && $gid <= $_->{lastgid} } @tsmap;
					scalar @tscs == 1 or die "gid $gid out of range!";
					{ 
						gid => $gid, 
						tsid => 1 + $gid - $tscs[0]->{firstgid}, 
						ts => $tscs[0]->{tileset}
					};
				}
			} @$_;
			@x;
		} @rawlayer;

		push @maplayers, \@maplayer;

	}

	return {
		width => $width,
		height => $height,
		layers => \@maplayers		# a flat array of tiles in col, row order
	};

}

# reads in a tileset (or finds a cached one) and returns
sub get_tileset {
	my ($dom_ts, $indir) = @_;

	#is this a "source" or embedded type?
	my $source = $dom_ts->getAttribute("source");

	if ($source) {
		$source = catfile($indir, $source);
		if (exists($tilesets{$source})) {
			return $tilesets{$source};
		} else {
			my $doc_ts = XML::LibXML->new->parse_file($source) or die "Error parsing tileset \"$source\" : $!";
			my $dom_ts2 = $doc_ts->documentElement();
			$dom_ts2->localname eq "tileset" or die "External tileset \"$source\" doesn't contain a tileset : \"${dom_ts2->localname}\".";
			my $ts = parse_tileset($dom_ts2, $source);
			$tilesets{$source} = $ts;
			return $ts;
		}
	} else {
		print STDERR "WARNING: embedded tileset in map - won't be shared\n";
		my $tsk = "#EMBED#" . ++$embed;
		my $ts = parse_tileset($dom_ts, $tsk);
		$tilesets{$tsk} = $ts;
		return $ts;
	}

}

sub parse_tileset {
	my ($tileset, $key) = @_;

	my %ret = ();

	$ret{key} = $key;
	$ret{name} = $tileset->getAttribute("name") // 0;
	$ret{tilesz_x} = $tileset->getAttribute("tilewidth") // 0;
	$ret{tilesz_y} = $tileset->getAttribute("tileheight") // 0;
	$ret{tile_spacing} = $tileset->getAttribute("spacing") // 0;
	$ret{tile_margin} = $tileset->getAttribute("margin") // 0;
	$ret{tile_count} = $tileset->getAttribute("tilecount") // 0;
	$ret{tile_columns} = $tileset->getAttribute("columns") // 0;
	
	$ret{tilesz_x} && $ret{tilesz_y} && $ret{tile_count} && $ret{tile_columns} || die "Cannot get tile sizes, count or columns : $tileset";
	
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

	$ret{props} = \%tileproperties;

	if ($tilesz_x == -1) {
		$tilesz_x = $ret{tilesz_x};
		$tilesz_y = $ret{tilesz_y};
	} else {
		$tilesz_x == $ret{tilesz_x} and $tilesz_y == $ret{tilesz_y} or die "Mismatched tilesizes all must be $tilesz_x x $tilesz_y";
	}


	return \%ret;

}


exit;

### my $fn_out=$ARGV[3];
### 
### 
### my $tilesets = $dom_inmap->findnodes("/map/tileset");
### $tilesets->size == 1 or die "can only handle one tileset which must be embedded";
### my $tileset = $tilesets->get_node(1);
### 
### 
### my $layers = $dom_inmap->findnodes("/map/layer");
### 
### my $layer_count = $layers->size;
### 
### $layer_count == 2 || Usage "Must have exactly 2 layers!";
### 
### my $bin='';
### 
### my $layerwidth = -1;
### my $layerheight = -1;
### 
### for (my $layernum = 1; $layernum <= 2; $layernum++) {
### 
### 	my $fh_cuts;
### 	if ($layernum == 1)
### 	{
### 		open($fh_cuts, ">", $fn_backcuts) or die "cannot open $fn_backcuts for output";
### 	} else {
### 		open($fh_cuts, ">", $fn_frontcuts) or die "cannot open $fn_frontcuts for output";		
### 	}
### 
### 	my %tmx_index_to_cut_index = ();
### 	my $ix_ctr = 0;
### 
### 	my $layer = $layers->get_node($layernum);
### 
### 	if ($layernum == 1)
### 	{
### 		$layerwidth = $layer->getAttribute('width');
### 		$layerheight = $layer->getAttribute('height');
### 	} else {
### 		$layerwidth = $layer->getAttribute('width') || die "layer $layernum has a different width";
### 		$layerheight = $layer->getAttribute('height') || die "layer $layernum has a different width";
### 	}
### 
### 
### 	my $data = $layer->findvalue("data");
### 
### 	# parse map into a 32 rows of 32 cols
### 
### 	my @lines = split /\n/, $data;
### 	my $j = 0;
### 	my $lno = 0;
### 	foreach my $l (@lines) {
### 		chomp $l;
### 		$lno++;
### 		if ($l =~ /^\s*([0-9]+(,|\s*$))+/) {
### 			my @cols = split /\,/, $l;
### 			scalar @cols == $layerwidth || die "line $lno of layer $layernum has different width ${\scalar(@cols)} <> $layerwidth $l";
### 			my $i = 0;
### 			foreach my $ix (@cols) {
### 				my $b=0x00;
### 				if ($ix != 0) {
### 					if (exists $tmx_index_to_cut_index{$ix}) {
### 						$b = $tmx_index_to_cut_index{$ix}
### 					} else {
### 						$b = $tmx_index_to_cut_index{$ix} = ++$ix_ctr;
### 						my $x = $tile_margin + (($ix - $tile_gid_first) % $tile_columns) * ($tile_spacing + $tilesz_x);
### 						my $y = $tile_margin + int(($ix - $tile_gid_first) / $tile_columns) * ($tile_spacing + $tilesz_y);
### 						print $fh_cuts "<move x=\"$x\" y=\"$y\" /><cut x=\"1\" y=\"1\" dir=\"rd\" />\n";
### 					}
### 
### 				}
### 
### 				my $nocolide = $tileproperties{$ix-$tile_gid_first}->{nocollide};
### 				if ($nocolide && $nocolide eq "true") {
### 					$b |= 0x80;
### 					print "NOCOLLIDE: $ix @ $i x $j $b\n";
### 				}
### 
### 				$bin .= chr($b);
### 				$i++;
### 			}
### 			$j++;
### 		} elsif ($l ne '') {
### 			Usage("Non-blank line contains bad data $l");
### 		}
### 	}
### 
### 	$fh_cuts->close;
### }
### 
### open(my $bin_out, '>:raw', $fn_out) or die "Unable to open: $!";
### print $bin_out $bin;