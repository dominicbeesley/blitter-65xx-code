#!/usr/bin/env perl

use strict;

#use Data::Dumper;
use List::Util qw/sum/;


sub usage($$) {
	my ($fh, $msg) = @_;

	print "ld65free.pl <linker cfg> <map file>\n";

	
	$msg && die $msg;
}

sub num($) { 
	my ($i) = @_;
	if ($i =~ /^\$([0-9a-f]+$)/i) {
		return hex($1);
	} elsif ($i =~ /^(\d+)/) {
		return 0 + $1;
	} else {
		return 0;
	}
}

my $fn_cfg = shift or usage(*STDERR, "Missing cfg parameter");
my $fn_map = shift or usage(*STDERR, "Missing map parameter");

-e $fn_cfg or usage(*STDERR, "No exist cfg file $fn_cfg");
-e $fn_map or usage(*STDERR, "No exist map file $fn_map");

open(my $fh_cfg, "<", $fn_cfg) or die "Cannot open $fn_cfg for input : $!";

my $STATE_SECTION = 0;
my $STATE_OBRACE = 1;
my $STATE_HEAD = 2;
my $STATE_HEADCOLON = 3;
my $STATE_NAME = 4;
my $STATE_NAMEEQ = 5;
my $STATE_VALUE = 6;
my $STATE_COMMAORSEMI = 7;
my $STATE_HEADORCBRACE = 8;

my $state = $STATE_SECTION;
my $hash_sections={};
my $cur_section_key;
my $arr_cur_section;
my $cur_head_key;
my $hash_cur_head;
my $cur_name;
while (<$fh_cfg>) {
	my $l = $_;
	$l =~ s/[\r\n]$//;
	my $col = 0;
	while ($l) {
		if ($l =~ /^(\s+)(.*)/ ) {
			$col += length($1);
			$l = $2;
		} elsif ($l =~ /^#.*/) {
			$l = undef;
		} else {
			# we are now expecting a token
			if ($state == $STATE_SECTION) {
				$l =~ /^(\w+)(.*)/ or die "Expecting section name at $.:$col";
				$col += length($1);
				$cur_section_key = $1;
				$arr_cur_section = ();
				$l = $2;
				$state = $STATE_OBRACE;
			} elsif ($state == $STATE_OBRACE) {
				$l =~ /^(\{)(.*)/ or die "Expecting \"{\" name at $.:$col";
				$col += length($1);
				$l = $2;
				$state = $STATE_HEADORCBRACE;
			} elsif ($state == $STATE_HEAD) {
				$l =~ /^(\w+)(.*)/ or die "Expecting head name at $.:$col";
				$col += length($1);
				$cur_head_key = $1;
				$hash_cur_head = {};
				$l = $2;
				$state = $STATE_HEADCOLON;
			} elsif ($state == $STATE_HEADCOLON) {
				$l =~ /^(\:)(.*)/ or die "Expecting \":\" at $.:$col";
				$col += length($1);
				$l = $2;
				$state = $STATE_NAME;
			} elsif ($state == $STATE_NAME) {
				$l =~ /^(\w+)(.*)/ or die "Expecting name at $.:$col";
				$col += length($1);
				$cur_name = $1;
				$l = $2;
				$state = $STATE_NAMEEQ;
			} elsif ($state == $STATE_NAMEEQ) {
				$l =~ /^(\=)(.*)/ or die "Expecting \"=\" at $.:$col";
				$col += length($1);
				$l = $2;
				$state = $STATE_VALUE;
			} elsif ($state == $STATE_VALUE) {
				$l =~ /^(\"[^\"]+\")(.*)/ or
				$l =~ /^([^,;]+)(.*)/ or die "Expecting value at $.:$col";
				$col += length($1);
				$l = $2;
				(exists $hash_cur_head->{$cur_name}) and die "$cur_section_key:$cur_head_key already contains a value of $cur_name";
				$hash_cur_head->{$cur_name} = $1;
				$state = $STATE_COMMAORSEMI;
			} elsif ($state == $STATE_COMMAORSEMI) {
				$l =~ /^([,;])(.*)/ or die "Expecting \",\" or \";\" at $.:$col";
				my $cors = $1;
				$col += length($1);
				$l = $2;
				if ($cors eq ",") {
					$state = $STATE_NAME;
				} else {
					# end of head, save values
					(grep {$_->{key} eq $cur_head_key} @$arr_cur_section) and die "Section $cur_section_key Already contains a heading $cur_head_key";
					push @$arr_cur_section, {key=>$cur_head_key, values=>$hash_cur_head};
					$state = $STATE_HEADORCBRACE
				}
			} elsif ($state == $STATE_HEADORCBRACE) {
				if ($l =~ /\}(.*)/) {
					$col ++;
					$l = $1;
					$state = $STATE_SECTION;
					
					(exists $hash_sections->{$cur_section_key}) and die "Duplicate $cur_section_key section $.:$col";

					$hash_sections->{$cur_section_key} = $arr_cur_section;

				} else {
					$state = $STATE_HEAD;
				}
			} else {
				die "Bad state $state $.:$col";
			}
		}
	}

}
$state == $STATE_SECTION or die "Not correctly terminated at $.:0";

#print Dumper($hash_sections);

close $fh_cfg;


my $STATE_M_WAIT_T1 = 0;
my $STATE_M_WAIT_T2 = 1;
my $STATE_M_PROC = 2;
my $STATE_M_DONE = 3;

my $hash_map_segments = {};

open (my $fh_map, "<", $fn_map) or die "Cannot open map file \"$fn_map\" for input : $!";

$state = $STATE_M_WAIT_T1;

while (<$fh_map>) {
	my $l = $_;
	$l =~ s/[\r\n]$//;
	
	if ($state == $STATE_M_WAIT_T1 && $l =~ /^Segment list:/) {
		$state = $STATE_M_WAIT_T2;
	} elsif ($state == $STATE_M_WAIT_T2 && $l =~ /^Name/) {
		$state = $STATE_M_PROC;
	} elsif ($state == $STATE_M_PROC && $l =~ /^Exports/) {
		$state = $STATE_M_DONE;
	} elsif ($state == $STATE_M_PROC && $l =~ /^(\w+)\s+([0-9A-F]+)\s+([0-9A-F]+)\s+\s+([0-9A-F]+)\s+\s+([0-9A-F]+)/i) {
		$hash_map_segments->{$1} = { 
			name => $1, 
			start => hex($2), 
			end => hex($3), 
			size => hex($4), 
			align => hex($5) 
		};
	}
}

($state == $STATE_M_DONE) or die "Error reading map file";
close ($fh_map);

#print Dumper($hash_map_segments);

my $hash_files = {};
my $hash_memory_areas = {};
# rearrange parsed memory sections
exists $hash_sections->{MEMORY} or die "no MEMORY section defined";
my $arr_mem = $hash_sections->{MEMORY};
foreach my $m (@$arr_mem) {
	exists $m->{key} or die "MEMORY area missing key";
	my $mk = $m->{key};
	exists $m->{values} or die "MEMORY area $mk missing values";
	my $vals = $m->{values};
	my $filename = (exists $vals->{file})?$vals->{file}:"-";
	my $size = num($vals->{size});
	$size or die "0 length or bad size in MEMORY area $mk";

	my $o = 0;
	if (exists $hash_files->{$filename}) {
		$o = sum(map {$hash_memory_areas->{$_}->{size}} @{$hash_files->{$filename}});
		push @{$hash_files->{$filename}}, $mk;
	} else {
		$hash_files->{$filename} = [$mk];
	}

	$hash_memory_areas->{$mk} = {
			memory=>$mk,
			offset=>$o,
			size=>$size,
			used=>0
		};

}

exists $hash_sections->{SEGMENTS} or die "no SEGMENTS section defined";
my $arr_seg = $hash_sections->{SEGMENTS};
foreach my $s (@$arr_seg) {
	exists $s->{key} or die "SEGMENT missing key";
	my $sk = $s->{key};
	exists $s->{values} or die "SEGMENT $sk missing values";
	my $vals = $s->{values};

	exists $vals->{load} or die "SEGMENT $sk missing load attribute";
	my $load_mem = $vals->{load};

	exists $hash_memory_areas->{$load_mem} or die "MEMORY area $load_mem references by SEGMENT $sk missing";
	my $lm = $hash_memory_areas->{$load_mem};

	if (!exists $hash_map_segments->{$sk}) {
		print STDERR "WARNING: no entry in map file for SEGMENT $sk\n";
	} else {
		my $ms = $hash_map_segments->{$sk};
		$lm->{used} += $ms->{size};
	}
}


#print Dumper($hash_files);
#print Dumper($hash_memory_areas);

printf "File            Area                          Size                  Used                  Free\n";
printf "==============  ===============  =================  ====================  ====================\n";



foreach my $f (sort(keys(%$hash_files))) {
	my $tot_size = 0;
	my $tot_used = 0;
	my $tot_free = 0;
	my $ct = 0;
	foreach my $m (@{$hash_files->{$f}}) {

		my $ma = $hash_memory_areas->{$m};

		my ($sz, $us) = ($ma->{size}, $ma->{used});
		my $fr = $sz - $us;

		printf	"%-15s %-15s %8d (\$%06x)    %8d (\$%06x)    %8d (\$%06x)\n", $f, $m, $sz, $sz, $us, $us, $fr, $fr;

		$tot_free += $fr;
		$tot_size += $sz;
		$tot_used += $us;
		$ct++;
	}

	printf "%31s %8d (\$%06x)    %8d (\$%06x)    %8d (\$%06x)\n\n", "Totals " . $f,  $tot_size, $tot_size, $tot_used, $tot_used, $tot_free, $tot_free;
}