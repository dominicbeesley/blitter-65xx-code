#!/usr/bin/env perl

use strict;
use Data::Dumper;
use File::Spec::Functions 'catfile';
use File::Basename;

my $CPU_MAP = {
	"6502"	=> 0,
	"65C02" => 1,
	"65816" => 2,

	"6809"	=> 4,
	"6309"	=> 5,

	"Z80"	=> 8,

	"68000"	=> 12,

	"6800"	=> 16,

	"RiscV"	=> 20
};


sub Usage {
	my $ret = "";
	my $msg = @_[0];

	$ret .= "makeromset.pl <list file> <binary out>";

	if ($msg) {
		$ret .= "\n\n$msg\n\n";
	}

	return $ret;
}

sub mycrc(@) {
	my $crc = 0;			## should be FFFF but 0 matches BLTUTIL ROM
	my $poly = 0x1021;

	foreach my $b (@_) {
		$crc ^= $b << 8;

		for (my $i = 0; $i < 8; $i++)
        {
            if (($crc & 0x8000) != 0) {
                $crc = ($crc << 1) ^ $poly;
            } else {
                $crc <<= 1;
            }
        }		
	}

	return $crc;
}

sub cpu_type_no($) {
	my ($s) = @_;
	exists $CPU_MAP->{$s} or die "No such cpu: $s";
	return $CPU_MAP->{$s};
}

sub rom_slot_no($) {
	my ($s) = @_;

	if (lc($s) eq 'm') {
		return 0xFF;
	} else {
		return hex($s);
	}
}

sub ext_type_no($) {
	my ($s) = @_;

	$s = lc($s);

	if ($s eq "mos") {
		return 2;
	} elsif ($s eq "rom") {
		return 1;
	} else {
		die "Unrecognised ext type : $s";
	}
}

sub parse_rominf($$) {
	my ($filepath, $ret) = @_;

	open(my $fh, "<", $filepath) or die "Cannot open rominf file \"$filepath\": $!";

	while (<$fh>) {
		s/[\r\n]+$//;

		s/^\s+//;
		s/\s+$//;

		if ($_) {
			if (/^CPU=(.+)/) {
				$ret->{cpu} = cpu_type_no($1);
			} elsif (/^TYPE=(.+)/) {
				$ret->{ext_type} = ext_type_no($1);
			} elsif (/^TITLE=(.+)/) {
				$ret->{title} = cleantit($1);
			} else {
				die "Unrecognised line : $_";
			}

		}		
	}
	

	close($fh);
}

sub cleantit($) {
	my ($t) = @_;

	$t =~ s/[\r\n\t]/ /gi;
	$t =~ s/\s+/ /gi;
	$t =~ s/^\s+//gi;
	$t =~ s/\s+$//gi;

	return $t;
}

sub get_rom($$) {
	my ($slot, $romfilepath) = @_;

print "$slot\n";

	if (!-e $romfilepath || !$romfilepath) {
		die "Missing rom file \"$romfilepath\".";
	}

	my $s = -s $romfilepath;
	$s < 256 and print STDERR "WARNING: \"$romfilepath\" is small $s\n";
	$s > 16384 and print STDERR "WARNING: \"$romfilepath\" is larger than 16384 bytes ($s), it will be truncated\n";

	open (my $fh, "<:raw", $romfilepath) or die "Couldn't open file \"$romfilepath\".";

	my $buf;
	my $ss = read($fh, $buf, 16384);
	if ($ss < 16384) {
		$buf .= chr(0xff) x (16384 - $ss);
	}
	
	close($fh);

	my ($nm, $path, $suff) = fileparse($romfilepath, qr/\.[^.]*/);

	my $ret= {
		filename => $romfilepath,
		bytes => $buf,
		title => cleantit($nm),
		slot => rom_slot_no($slot), 
		crc => mycrc(unpack("C*",$buf))
	};

	# global rominf file
	my $gloinf = catfile($path, "_.rominf");
	if (-e $gloinf)
	{
		parse_rominf($gloinf, $ret);
	}

	# try and get details from ROM - if it is a ROM
	my $co = ord(substr($buf, 7, 1));
	if (substr($buf, $co, 4) eq chr(0)."(C)") {
		# looks like a ROM
		$ret->{rom_type} = ord(substr($buf, 6, 1));
		$ret->{ext_type} = 1;
		$ret->{title} = cleantit(join(" ", unpack("Z* Z*", substr($buf, 9, 31))));
	}

	# specific rominf file
	my $locinf = $romfilepath . ".rominf";
	if (-e $locinf) {
		parse_rominf($locinf, $ret);
	}
	

	return $ret;

}

sub read_list($) {
	my ($fh) = @_;

	my @ret = ();
	my %defines = ();
	my $curdisc;
	my $dir;

	while (<$fh>) {
		
		s/[\r\n]+$//;

		s/^\s+//;
		s/\s+$//;
		s/\/\/.*//;

		if ($_) {

			if (/^#define\s+(\w+)\s+(.*?)\s*$/)
			{
				$defines{$1}=$2;
			} else {

				#substitute defines
				while(s/\$\{(\w+)\}/$defines{$1}/ge) {
					#
				}			

				if (/^\[([^\]]+)\]\s*$/) {
					if ($curdisc) {
						push @ret, $curdisc;
					}
					$curdisc = {
						title => cleantit($1),
						cpu   => 0
					};
				} elsif (/^DIR\s*=\s*(.+?)\s*$/) {
					$dir=$1;
				} elsif (/^CPU\s*=\s*(.+?)\s*$/) {
					$curdisc->{cpu} = cpu_type_no($1);
				} elsif (/^([0-9A-FM])\s*=\s*(.+?)\s*$/) {
					$curdisc->{roms}->{$1} = get_rom($1, catfile($dir,$2));
				} else {
					die "Unrecognised line : $_";
				}
			}
		}

	}	

	if ($curdisc) {
		push @ret, $curdisc;
	}

	return \@ret;
}


my $fn_list = shift or die Usage("Missing list file");
my $fn_binout = shift or die Usage("Missing binary out file");


open(my $fh_list, "<", $fn_list) or die Usage("Cannot open file \"$fn_list\".");
my $romlist = read_list($fh_list);
close($fh_list);

#print Data::Dumper->Dump($romlist);

open(my $fh_o, ">:raw:", $fn_binout) or die "Cannot open binary file \"$fn_binout\" for output: $!";

foreach my $d (@$romlist) {
	print $fh_o pack("C C Z32 A4 x26", (scalar keys %{$d->{roms}}, $d->{cpu}, $d->{title}, "RoMs"));
	print "$d->{title}!\n";

	foreach my $s (sort keys %{$d->{roms}}) {
		my $r = $d->{roms}->{$s};
		my $cpu = $r->{cpu}?$r->{cpu}:$d->{cpu};
		print $fh_o pack("C C C C Z32 S x26", $r->{slot}, $r->{ext_type}, $r->{rom_type}, $cpu, $r->{title}, $r->{crc});
	}

	foreach my $s (sort keys %{$d->{roms}}) {
		my $r = $d->{roms}->{$s};
		print $fh_o pack("a16384", $r->{bytes});
	}

}

#mark end of list
print $fh_o pack("C", 0);

close $fh_o;