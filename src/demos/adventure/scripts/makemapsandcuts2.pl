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
# Numbering (re)starts at 0! for each tileset (c.f. global ids which start at 1)
# Global-id: "_gid" - these are scoped to a map. Numbering starts at 1 for 
# tilese from the first tileset referenced by a map then at 
# 1+{1st tileset count} for the 2nd and so on. The numbering in source map 
# data is in global order
# Layer-id: "_lid" - these are scoped to a layer (front/back) and start at 1
# these are the ids that are used in the output binary maps - these ids are 
# shared between all maps when output in binary but not between layers!
# The _lid is effectively an index into the relevant bitmap. Like globals
# ids layer ids start at 1 with 0 meaning empty


sub Usage {

	while (my $x = shift) {
		print STDERR "$x\n";
	}

	die "
makemaps.pl <output directory> <group name> <map binary offset> <palette> <maps>...\n
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

my $map_bin_offs = shift;

my $fn_pal_in = shift or Usage "No palette file specified";
my $xel_pal = read_palette($fn_pal_in);

my $fn_backcuts=catfile($dir_out, "back.cutdefs");
my $fn_frontcuts=catfile($dir_out, "front.cutdefs");

my $tilesz_x = -1;
my $tilesz_y = -1;
my @tilesets = ();		
my $embed = 0;			# highest {n} of embeded tilesets

my @maps = ();

foreach my $fn_inmap (@ARGV) {
	my $bn = fileparse($fn_inmap, qr/\.[^.]*/);

	print "===MAP: $bn\n";

	my ($x,$indir,$y) = fileparse($fn_inmap);

	$indir = File::Spec->rel2abs(File::Spec->canonpath($indir));

	print "INPUTDIR = $indir\n";

	my $dom_intmx = XML::LibXML->new->parse_file($fn_inmap);

	my $xel_inmap = $dom_intmx->documentElement;

	$xel_inmap->localname eq "map" or die "Missing map element in tmx $fn_inmap";

	my $map = do_map($xel_inmap, $indir);
	$map->{name} = $fn_inmap;
	$map->{base_name} = $bn;
	push @maps, $map;
}

# now we've got all the maps read in, for each layer make the layer id sets
for (my $layer = 0; $layer <2; $layer++) {
	
	foreach my $ts (@tilesets) {
		my %empty = ();
		push @{$ts->{usages}}, \%empty;
	}


	# build up a list of used tiles in each tileset
	foreach my $map (@maps) {
		my $l = $map->{layers}[$layer];

		foreach my $t (@$l) {
			my $tsid = $t->{tsid};
			my $gid = $t->{gid};
			if ($gid) {
				my $ts = $t->{ts};
				my $u = $ts->{usages}->[$layer];
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


	# ASSUMPTION: that this will process in the same order as the 
	# loop that creates cuts
	my $ix = 1;
	# assigned indices to the tiles these should be in tileset order
	# for sane cut definitions
	my @cuts = ();
	foreach my $ts (@tilesets) {
		foreach my $tsid (sort { $a <=> $b } keys %{$ts->{usages}->[$layer]}) {
			$ts->{usages}->[$layer]->{$tsid}->{lid} = $ix++;
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
			my $gid = $t->{gid};
			if ($gid) {
				my $ts = $t->{ts};
				my $u = $ts->{usages}->[$layer];
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
	nocollide => 0x80,
	"border-north" => 0x01
	);

my $fn_map = catfile($dir_out, $group_name . ".map");
open(my $fh_map, ">:raw:", $fn_map) or die "Cannot open $fn_map for output : $!";

my $fn_map_c = catfile($dir_out, $group_name . ".c");
my $fn_map_h = catfile($dir_out, $group_name . ".h");
open(my $fh_map_h, ">", $fn_map_h) or die "Cannot open $fn_map_h for output : $!";
open(my $fh_map_c, ">", $fn_map_c) or die "Cannot open $fn_map_c for output : $!";
print $fh_map_h "#ifndef __MAP_${group_name}_H__\n";
print $fh_map_h "#define __MAP_${group_name}_H__\n";
print $fh_map_c "#include \"mapdef.h\"\n";
print $fh_map_c "#include \"$group_name.h\"\n";
print $fh_map_c "#include <stddef.h>\n";


my $bin_offs_rtot = 0;

foreach my $map (@maps) {
	# make header file


	print $fh_map_h "extern mapdef_t $map->{base_name}_def;\n";

	print $fh_map_c "mapdef_t $map->{base_name}_def = {\n";	
	printf $fh_map_c "\t(unsigned int)%s+%d,\n", $map_bin_offs, $bin_offs_rtot;
	print $fh_map_c "\t$map->{width}, //width\n";
	print $fh_map_c "\t$map->{height}, //height\n";
	print $fh_map_c "\t" . mapref($map, "north") . ",\n";
	print $fh_map_c "\t" . mapref($map, "south") . ",\n";
	print $fh_map_c "\t" . mapref($map, "east") . ",\n";
	print $fh_map_c "\t" . mapref($map, "west") . ",\n";
	print $fh_map_c "};\n";
	


	# save binary map layer

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
							print "$row $col $p $propflags{$p} $v\n";
						}
					}		
				}
			}
			print $fh_map pack("C", $v);
			$ix++;
		}
	}

	$bin_offs_rtot += 3 * $map->{height} * $map->{width};
}

printf $fh_map_h "#define MAP_GROUP_SIZE_%s %d\n", uc(${group_name}), $bin_offs_rtot;

print $fh_map_h "#endif\n";

close $fh_map_h;
close $fh_map_c;

close $fh_map;


# output tilecutter.xml

my $fn_tc = catfile($dir_out, $group_name . ".tilecuts.xml");

my $dom_tc =  XML::LibXML::Document->createDocument( "1.0", "UTF-8" );

my $xel_tc = $dom_tc->createElement("tile-cutter");
$dom_tc->setDocumentElement($xel_tc);
my $xel_pal2 = $xel_tc->appendChild($xel_pal);
$xel_pal2->setAttribute("file", "$group_name.pal");

my @layernames = ("back", "front");

# ASSUMPTION: that this will process in the same order as the 
# loop that assigns lids
for (my $layer = 0; $layer < 2; $layer++) {

	my $xel_dest = $dom_tc->createElement("dest");
	$xel_tc->appendChild($xel_dest);
	$xel_dest->setAttribute("file", "$group_name.$layernames[$layer].til");
	$xel_dest->setAttribute("size-x", $tilesz_x);
	$xel_dest->setAttribute("size-y", $tilesz_y);
	$xel_dest->setAttribute("mask", ($layer == 0)?"n":"y");

	my $lid = 1;
	foreach my $ts (@tilesets) {
		my $xel_src = $dom_tc->createElement("source");
		$xel_dest->appendChild($xel_src);
		$xel_src->setAttribute("file", $ts->{image});

		my $tile_spacing = $ts->{tile_spacing};
		my $tile_margin = $ts->{tile_margin};
		my $tile_count = $ts->{tile_count};
		my $tile_columns = $ts->{tile_columns};
		my $u = $ts->{usages}->[$layer];
		foreach my $tsid (sort { $a <=> $b } keys %{$ts->{usages}->[$layer]}) {
			my $x = $tile_margin + ($tsid % $tile_columns) * ($tile_spacing + $tilesz_x);
			my $y = $tile_margin + int($tsid / $tile_columns) * ($tile_spacing + $tilesz_y);

			$xel_dest->appendChild($dom_tc->createComment(sprintf("%d %X", $tsid, $lid)));			
			my $xel_move = $dom_tc->createElement("move");
			$xel_dest->appendChild($xel_move);			
			$xel_move->setAttribute("x", $x);
			$xel_move->setAttribute("y", $y);
			my $xel_cut = $dom_tc->createElement("cut");
			$xel_dest->appendChild($xel_cut);			
			$xel_cut->setAttribute("x", "1");
			$xel_cut->setAttribute("y", "1");
			$xel_cut->setAttribute("dir", "rd");
			$lid++;
		}
	}
}

$dom_tc->toFile($fn_tc, 2) or die "Error saving tile-cutter xml";


sub do_map {
	my ($xel_inmap, $indir) = @_;
	
	# map properties
	my %mapproperties = ();
	foreach my $prop ($xel_inmap->findnodes("properties/property"))
	{
		$mapproperties{$prop->getAttribute("name")} = $prop->getAttribute("value");
	}



	my $gid = 1;

	#look for and process tilesets
	my @tsmap = ();
	foreach my $xel_ts ($xel_inmap->findnodes("tileset")) {
		my $ts = get_tileset($xel_ts, $indir);	
		my %tsc = ( firstgid => $gid, lastgid => $gid + $ts->{tile_count} - 1, tileset => $ts );
		$gid+=$ts->{tile_count};
		push @tsmap, \%tsc;
	}

	my $width = $xel_inmap->getAttribute("width") // 0;
	my $height = $xel_inmap->getAttribute("height") // 0;


	my @maplayers = ();	# this will contain the layers, each layer contains an array of arrays of hashes

	#read in the map's layers

	my $xlst_layers = $xel_inmap->findnodes("layer");
	
	my $layer_count = $xlst_layers->size;
	
	$layer_count == 2 or Usage "Must have exactly 2 layers!";
		
	
	for (my $layernum = 1; $layernum <= 2; $layernum++) {
		my $xel_layer = $xlst_layers->get_node($layernum);

		my @rawlayer = ();	# the layer's data as an array of arrays of gids
	 
 		my $layerwidth = $xel_layer->getAttribute('width');
		my $layerheight = $xel_layer->getAttribute('height');
 		$layerwidth == $width || die "layer $layernum has a different width to map";
 		$layerheight == $height || die "layer $layernum has a different height to map";
	  
	 	my $data = $xel_layer->findvalue("data");
	 
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
						tsid => -1, 
						ts => undef
					};
				} else {
					my @tscs = grep { $gid >= $_->{firstgid} && $gid <= $_->{lastgid} } @tsmap;
					scalar @tscs == 1 or die "gid $gid out of range!";
					{ 
						gid => $gid, 
						tsid => $gid - $tscs[0]->{firstgid}, 
						ts => $tscs[0]->{tileset}
					};
				}
			} @$_;
			@x;
		} @rawlayer;

		push @maplayers, \@maplayer;

	}

	return {
		props => \%mapproperties,
		width => $width,
		height => $height,
		layers => \@maplayers		# a flat array of tiles in col, row order
	};

}

sub mapref {
	my ($map, $dir) = @_;

	my $ref = $map->{props}->{"map-$dir"};

	if ($ref) {
		return "\&${ref}_def";
	} else {
		return "NULL";
	}
}

# reads in a tileset (or finds a cached one) and returns
sub get_tileset {
	my ($xel_ts, $indir) = @_;

	#is this a "source" or embedded type?
	my $source = $xel_ts->getAttribute("source");

	if ($source) {
		$source = catfile($indir, $source);

		my ($basename, $directory, $ext) = fileparse($source);

		my ($ts) = grep { $_->{key} eq $source} @tilesets;

		if ($ts) {
			return $ts;
		} else {
			my $dom_ts = XML::LibXML->new->parse_file($source) or die "Error parsing tileset \"$source\" : $!";
			my $xel_ts2 = $dom_ts->documentElement();
			$xel_ts2->localname eq "tileset" or die "External tileset \"$source\" doesn't contain a tileset : \"${xel_ts2->localname}\".";
			$ts = parse_tileset($xel_ts2, $source, $directory);
			push @tilesets, $ts;
			return $ts;
		}
	} else {
		print STDERR "WARNING: embedded tileset in map - won't be shared\n";
		my $tsk = "#EMBED#" . ++$embed;
		my $ts = parse_tileset($xel_ts, $tsk, $indir);
		push @tilesets, $ts;
		return $ts;
	}

}

sub parse_tileset {
	my ($tileset, $key, $directory) = @_;

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
	
	my ($xel_img) = $tileset->findnodes("image");

	$xel_img or die "Missing image element";


	my $img_src = $xel_img->getAttribute("source");

	if (!File::Spec->file_name_is_absolute($img_src)) {
		$img_src = File::Spec->rel2abs(File::Spec->canonpath(catfile($directory, $img_src)));	
	}

	$ret{image} = $img_src;

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


#read in a pallette document and return as a palette element reference
sub read_palette {

	my ($fn_pal) = @_;

	my $dom_pal = XML::LibXML->new->parse_file($fn_pal) or die "Error parsing palette \"$fn_pal\" : $!";

	my $xel_ret = $dom_pal->documentElement;

	$xel_ret->localname eq "palette" or die "Unexpected element name \"${ \$xel_ret->localname} \" - exepecting \"palette\"";

	return $xel_ret;
}