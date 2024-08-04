#!/usr/bin/env perl

use strict;
use Getopt::Long;
use XML::LibXML;
use MIME::Base64;

# convert beebspriter XML to binary in Blitter linear form

my $mask;
my $symbols;
my $help;
GetOptions(
	"mask" => \$mask,
	"symbols=s" => \$symbols,
	"help" => \$help
	) or Usage("Bad options $!");

if ($help) {
	Usage(*STDOUT, undef, 0);
}

my $fn_in = shift;
my $fn_out = shift;

($fn_in and -e $fn_in) or Usage(*STDERR, "Missing input filename", 10);
$fn_out or Usage(*STDERR, "Missing output filename", 10);

my $dom = XML::LibXML->load_xml(location => $fn_in) or die "Cannot open $fn_in : $!";

open(my $fh_out, ">:raw:", $fn_out) or die "Cannot open \"$fn_out\" for output : $!";

$dom->documentElement->nodeName eq "SpriteSheet" or die "That doesn't look like a SpriteSheet";

my $fh_sym;

my $mode = $dom->documentElement->getAttribute("Mode");
my $bpp;
if ($mode eq "0") {
	$bpp = 1;
} elsif ($mode eq "1") {
	$bpp = 2;
} elsif ($mode eq "2") {
	$bpp = 4;
} elsif ($mode eq "4") {
	$bpp = 1;
} elsif ($mode eq "5") {
	$bpp = 2;
} else {
	die "Bad mode attribute : $mode";
}

my $bpp_mas = (1 << $bpp)-1;
my $ppb = int(8 / $bpp);

my @names=();
my %info=();
my $offs=0;

foreach my $sprite ($dom->findnodes('/SpriteSheet/SpriteList/Sprite')) {
    my $s_name = $sprite->getAttribute("Name");
    my @s_bmp = unpack("C*", decode_base64($sprite->findvalue("Bitmap")));
    my $s_w = $sprite->getAttribute("Width");
    my $s_h = $sprite->getAttribute("Height");    
    my $bytes_w = int(($s_w + $ppb - 1) / $ppb);
    my $bytes_wm = int(($s_w + 8 - 1) / 8);
    my $mask_w = int(($s_w + 7) / 8);

	push @names, $s_name;
	$info{$s_name} = {
		name => $s_name,
		width => $bytes_w,
		height => $s_h,
		offset => $offs,				
	};


    my @bin = (0) x $bytes_w * $s_h;
    for (my $y = 0; $y < $s_h; $y++) {
    	for (my $x = 0; $x < $s_w; $x++) {
			my $c = pixelformat($s_bmp[$x + $y * $s_w], $bpp);
			my $sh = $ppb - ($x % $ppb) - 1;
			my $bx = int($x / $ppb);

			$bin[$bx + ($y * $bytes_w)] |= ($c << $sh);
    	}
    }
	print $fh_out pack("C*", @bin);
	$offs += scalar @bin;

	# append sprite mask
	if ($mask) {
		$info{$s_name}->{offset_mask} = $offs;
		$info{$s_name}->{width_mask} = $bytes_wm;
	    my @binm = (0) x $bytes_wm * $s_h;
	    for (my $y = 0; $y < $s_h; $y++) {
	    	for (my $x = 0; $x < $s_w; $x++) {
				my $c = ($s_bmp[$x + $y * $s_w] == 255)?0:1;
				my $sh = 8 - ($x % 8) - 1;
				my $bx = int($x / 8);

				$binm[$bx + ($y * $bytes_wm)] |= ($c << $sh);
	    	}
	    }
		print $fh_out pack("C*", @binm);
		$offs += scalar @binm;
	}    

}


close $fh_out;


if ($symbols) {
	open($fh_sym, ">", $symbols) or die "cannot open symbols file \"$symbols\" : $!";

	foreach my $k (@names) {
		my $i = $info{$k};
		print $fh_sym "; $i->{name}\n";
		l("SPR_W_", $i->{name}, $i->{width});
		if ($mask) {
			l("SPR_WM_", $i->{name}, $i->{width_mask});
		}
		l("SPR_H_", $i->{name}, $i->{height});
		l("SPR_OFFS_", $i->{name}, $i->{offset});
		if ($mask) {
			l("SPR_OFFS_M_", $i->{name},$i->{offset_mask});
		}
	}

	close $fh_sym;
}

sub l($$$) {
	my ($p, $n, $v) = @_;
	printf $fh_sym "%-40s =\$%02X\n", $p.uc($n), $v;
}


sub Usage($$$) {
	my ($fh,$msg,$ex) = @_;

	if ($msg) {
		print $fh "ERROR: $msg\n";
	}

	print $fh "Usage: beebspriter2blit.pl [..options..] <input> <output> [<symbols>]

Options:
	--mask	Output masks after the sprites
	--symbols <file> Make a ca65 include file
";

	exit $ex;
}

sub pixelformat($$) {
	my ($c, $bpp) = @_;

	if ($c == 255) {
		return 0;
	} elsif ($bpp == 1) {
		return $c & 1;
	} elsif ($bpp == 2) {
		return ($c & 1) | (($c & 2) << 3);
	} elsif ($bpp == 4) {
		return ($c & 1) | (($c & 2) << 1) | (($c & 4) << 2) | (($c & 8) << 3);
	}

}