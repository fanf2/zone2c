#!/usr/bin/perl
# SPDX-License-Identifier: CC0-1.0

use warnings;
use strict;

use File::Slurp;
use Net::DNS;
use Net::DNS::ZoneFile;

unless (1 <= @ARGV and @ARGV <= 2) {
	die "usage: zone2re file [origin]\n";
}

my $zonefile = Net::DNS::ZoneFile->new(@ARGV);
my $zonename;

sub labels {
	my $name = shift;
	$name =~ s/\.*$//;
	return '', reverse split /\./, $name;
}

my $tree = {};

# XXX we need to prune occluded names
# XXX these causes of death need fixing

while (my $rr = $zonefile->read) {
	my $name = lc $rr->owner;
	die "cannot handle escaped characters in $name\n"
	    if $name =~ /\\/;
	die "cannot handle wildcards in $name\n"
	    if $name =~ /^\*\./;
	$zonename = $name if $rr->type eq 'SOA';
	my $t = $tree;
	for my $label (labels $name) {
		$t = $t->{$label} //= {};
	}
}

print "// zone $zonename\n";

sub wire {
	my ($label,$tail) = @_;
	return sprintf "\\x%02x%s%s",
	    length $label, $label, $tail;
}

sub safechr {
	my $ord = shift;
	my $chr = chr $ord;
	$chr = sprintf "\\x%02x", $ord
	    if $chr !~ m{0-9A-Za-z};
	return $chr;
}

sub casechr {
	my $ch = shift;
	my $uc = uc $ch;
	my $lc = lc $ch;
	my $esc = safechr ord $ch;
	return ($uc ne $lc) ? ($ch,$uc,$lc) : ($ch,undef,$esc);
}

sub range {
	my ($lo,$LO,$xlo) = casechr $_[0];
	my ($hi,$HI,$xhi) = casechr $_[1];
	die "bad range $lo..$hi\n" if $lo gt $hi;
	die "uppercase not allowed $lo..$hi\n" if "$lo$hi" =~ m{[A-Z]};
	my $ltA = safechr -1 + ord 'A';
	my $gtZ = safechr +1 + ord 'Z';
	return $LO ? "[$LO$hi]" : $xhi	if $lo eq $hi;
	return "[$xlo-$xhi]"		if $lo lt 'A' and $hi lt 'A';
	return "[$xlo-$ltA$gtZ-$xhi]"	if $lo lt 'A' and $hi lt 'a';
	return "[$xlo-$HI$gtZ-$hi]"	if $lo lt 'A' and $hi le 'z';
	return "[$xlo-$xhi]"		if $lo lt 'A' and $hi gt 'z';
	return "[$xlo-$xhi]"		if $lo lt 'a' and $hi lt 'a';
	return "[A-$HI$xlo-$hi]"	if $lo lt 'a' and $hi le 'z';
	return "[A-Z$xlo-$xhi]"		if $lo lt 'a' and $hi gt 'z';
	return "[$LO-$HI$lo-$hi]"	if $lo le 'z' and $hi le 'z';
	return "[$LO-Z$lo-$xhi]"	if $lo le 'z' and $hi gt 'z';
	return "[$xlo-$xhi]"		if $lo gt 'z' and $hi gt 'z';
}

sub lesser {
	my $lo = chr 0;
	my ($hi) = @_;
	$hi = chr(ord($hi)-1);
	return range $lo, $hi;
}

sub between {
	my ($lo,$hi) = @_;
	return unless $lo ne '' and $hi ne '';
	die "nothing between $lo..$hi\n" if $lo ge $hi;
	$lo = chr(ord($lo)+1);
	$hi = chr(ord($hi)-1);
	return $lo le $hi ? range $lo, $hi : undef;
}

sub greater {
	my ($lo) = @_;
	my $hi = chr 255;
	$lo = chr(ord($lo)+1);
	return range $lo, $hi;
}

sub extensions {
	my ($prefix,$range,$tail) = @_;
	my $pre = length($prefix);
	++$pre if $range;
	my ($min,$max) = (!$range, 63-$pre);
	my @ret;
#	push @ret, "wild '\\xNN$prefix' $range any{$min..$max} '$tail'";
#	return @ret;
	for my $suf ($min .. $max) {
		my $len = sprintf "\\x%02x", $pre + $suf;
		my $suffix = sprintf "any{%d}", $suf;
		push @ret, "wild '$len$prefix' $range $suffix '$tail'";
	}
	return @ret;
}

sub zone2re;
sub zone2re {
	my ($t,$tail) = @_;
	print <<RE2C;
'$tail' { return "Y $tail" }
RE2C
	my $NX = "N $tail";
	my @label = sort keys %$t;
	if (@label == 0) {
		print "wild '$tail' |\n";
		return $NX;
	}
	my $prev = '';
	for my $next (@label, '') {
		my @nx;
		my $diff = 0;
		++$diff while
		    substr($prev, 0, $diff) eq
		    substr($next, 0, $diff);
		--$diff; # index of differing byte
		my $plen = length $prev;
		if ($diff <= $plen and $plen > 0) {
			push @nx, extensions $prev, '', $tail;
		}
		for my $i (reverse($diff+1 .. $plen-1)) {
			my $prefix = substr $prev, 0, $i;
			my $range = greater substr $prev, $i, 1;
			push @nx, extensions $prefix, $range, $tail;
		}
		if ($next eq '') {
			my $range = greater substr $prev, 0, 1;
			push @nx, extensions '', $range, $tail;
		}
		my $p = substr($prev, $diff, 1);
		my $n = substr($next, $diff, 1);
		if (my $range = between $p, $n) {
			my $prefix = substr $prev, 0, $diff;
			push @nx, extensions $prefix, $range, $tail;
		}
		if ($prev eq '') {
			my $range = lesser substr $next, 0, 1;
			push @nx, extensions '', $range, $tail;
		}
		for my $i ($diff+1 .. length($next)-1) {
			my $prefix = substr $next, 0, $i;
			my $range = lesser substr $next, $i, 1;
			push @nx, extensions $prefix, $range, $tail;
		}
		print join " |\n", @nx;
		print "\t{ return \"$NX\" }\n";
		return $NX if $next eq '';
		$NX = zone2re $t->{$next}, wire $next, $tail;
		$prev = $next;
	}
}

# unknown zones need to get REFUSED so skip parent domains

my $tail = "";

for my $label (labels $zonename) {
	$tree = $tree->{$label};
	$tail = wire $label, $tail;
}

print read_file "zone2c.re";

zone2re $tree, $tail;

print "\n%}\n}\n";
