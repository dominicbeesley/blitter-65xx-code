#!/usr/bin/env perl

use strict;
use Text::ParseWords;
use Data::Dumper;
use File::Spec::Functions;
use File::Basename;

# Attempt to update the relative addresses in a set of
# ca65 listing files with data from an ld65 --dbgfile
# and fill in "rr" bytes from the linked output file(s)


sub usage($$) {
	my ($fh, $msg) = @_;

	print "ca65lstupdate.pl <debug file> <listings directory>\n";


	$msg && die $msg;
}

sub additem($$) {
	my ($hr, $txt) = @_;
	my %r = ();
	foreach my $i (parse_line(q{,}, 0, $txt)) {
		if ($i =~ /^(\w+)=(.*)/) {
			$r{$1} = $2;
		}
	}
	if (exists $r{"id"}) {
		$hr->{$r{"id"}} = \%r;
	}
}

my %bins = ();

sub getbin($) {
	my ($fn) = @_;
	if (!exists $bins{$fn}) {
		my $data = undef;
		if (open(my $fh, "<:raw", $fn)) {
			local $/;
			$data = <$fh>;
			close($fh);
		} else {
			print STDERR "Cannot open output file \"$fn\" : $!\n";
		}
		$bins{$fn} = $data;
	}
	return $bins{$fn};
}

my $mismatches = 0;

# replace "rr" in the byte columns of a listing line with bytes from the output file
# $rest is the text after "r 1", $base is the file offset of the first byte shown,
# $end is the file offset just past the span
sub fillbytes($$$$) {
	my ($rest, $bin, $base, $end) = @_;

	defined $bin or return $rest;

	for (my $i = 0; $i < 4; $i++) {
		my $p = 2 + $i * 3;
		last if length($rest) < $p + 2;
		my $tok = substr($rest, $p, 2);
		last if $tok eq "  ";
		my $o = $base + $i;
		last if $o >= $end || $o >= length($bin);
		my $b = sprintf("%02X", ord(substr($bin, $o, 1)));
		if ($tok eq "rr") {
			substr($rest, $p, 2) = $b;
		} elsif ($tok =~ /^[0-9A-F]{2}$/i && uc($tok) ne $b) {
			$mismatches++;
		}
	}
	return $rest;
}

my $fn_dbg = shift or usage(*STDERR, "Missing debug file parameter");
my $dirlst = shift or usage(*STDERR, "Missing listings directory");

-d $dirlst or usage(*STDERR, "\"$dirlst\" is not a directory");

my %files = ();
my %lines = ();
my %mods = ();
my %segs = ();
my %spans = ();
my %syms = ();


open(my $fh_dbg, "<", $fn_dbg) or usage(*STDERR, "Cannot open \"$fn_dbg\" for input : $!");

while (<$fh_dbg>) {

	s/[\s\n\t]+$//;

	if (/^file\s+(.*)/) {
		additem(\%files, $1);
	} elsif (/^line\s+(.*)/) {
		additem(\%lines, $1);
	} elsif (/^mod\s+(.*)/) {
		additem(\%mods, $1);
	} elsif (/^seg\s+(.*)/) {
		additem(\%segs, $1);
	} elsif (/^span\s+(.*)/) {
		additem(\%spans, $1);
	} elsif (/^sym\s+(.*)/) {
		additem(\%syms, $1);
	}



}
close ($fh_dbg);

for my $f (values %files) {
	if ($f->{name} =~ /.(asm|s)$/) {
		my $fnlst = $f->{name};
		$fnlst =~ s/.(asm|s)$/.lst/;
		my $pfnlst = catfile($dirlst, $fnlst);
		if (!-e $pfnlst) {
			# not found try flattening directory
			$pfnlst = catfile($dirlst, basename($fnlst));
		}
		if (-e $pfnlst) {

#			print "PROCESSING $pfnlst\n";

			my $pfnlstrel = "$pfnlst.rel";
			open (my $fh_in, "<", $pfnlst) or die "Cannot open $pfnlst for input : $!";
			open (my $fh_out, ">", $pfnlstrel) or die "Cannot open $pfnlstrel for output : $!";

			# spans by line number
			my %myspans = ();

			print "$f->{name} : $f->{id}\n";
			for my $l (grep { $_->{file} eq $f->{id} && defined $_->{span}} values(%lines)) {
				my ($sid) = split(/\+/, $l->{span});
				$myspans{$l->{line}} = $spans{$sid};
			}

			# last line with a span, for continuation lines
			my $lastaddr = undef;
			my $lastreladdr = 0;
			my $lastbin = undef;
			my $lastbase = 0;
			my $lastend = 0;

			my $lno = 1;
			while (<$fh_in>) {
				if ($_ =~ /^([0-9a-f]+)r 1(\s\s(([0-9A-F]{2}|xx|rr)\s)+\s*)$/i) {
					# data continuations: don't count these lines
					if (defined $lastaddr) {
						my $delta = hex($1) - $lastreladdr;
						my $rest = $2;
						$rest =~ s/[\r\n]+$//;
						$rest = fillbytes($rest, $lastbin, $lastbase + $delta, $lastend);
						printf $fh_out "%06X   ", $lastaddr + $delta;
						print $fh_out "$rest\n";
					}
				} elsif ($_ =~ /^([0-9a-f]+)r 1(.*)/i) {
					my $reladdr = hex($1);
					my $rest = $2;
					$lastaddr = undef;
					if (exists $myspans{$lno}) {
						my $s = $myspans{$lno};
						#print $fh_out Dumper($myspans{$lno});
						my $seg = $segs{$s->{seg}};
						my $addr = hex($seg->{start}) + $s->{start};
						if (exists $seg->{oname} && exists $seg->{ooffs}) {
							my $bin = getbin($seg->{oname});
							my $base = $seg->{ooffs} + $s->{start};
							my $end = $base + $s->{size};
							$rest = fillbytes($rest, $bin, $base, $end);
							$lastbin = $bin;
							$lastbase = $base;
							$lastend = $end;
						} else {
							$lastbin = undef;
						}
						$lastaddr = $addr;
						$lastreladdr = $reladdr;
						printf $fh_out "%06X   ", $addr;
					} else {
						printf $fh_out "         ";
					}
					print $fh_out "$rest\n";
					$lno++;
				} else {
					print $fh_out $_;
				}
			}
		} else {
			print STDERR "Missing listing file $pfnlst\n";
		}
	}

}

$mismatches && print STDERR "Warning: $mismatches listed bytes differ from the output file\n";

#print Dumper(%files);
