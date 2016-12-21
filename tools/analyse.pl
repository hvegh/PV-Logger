#!/usr/bin/perl -w

# This file is part of PV-Logger.
#
# PV-Logger is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# (c) 2013, 2014 Henk Vergonet
# Source can be found on https://github.com/hvegh/PV-Logger.git

use strict;
use Getopt::Std;

my %arg = ( );
getopts("j:nsvh", \%arg);

die "$0 [-jnsvh] <solarlog files> | STDIN

--- Analysis tools ---

Line impedance estimator:
  Determines the effective resistance between the inverter and the mains power
  source using statistical analysis of the voltage and current fluctuations
  meaured at the inverter.

Generate JSON datafile
  Generates a datafile for use with index.html script.

Options:
  -j <file>	: generate JSON datafile.
  -n		: conversion efficiency.
  -s		: Perform the operation on the input files individually 
  -v	 	: Be more verbose.
  -h		: This help.
" if $arg{h};

################################################################################
#
# Parse PV-logger data files
#
sub parse
{
	my ($f, $vh, $keyname) = @_[0..2];

	open(my $fh, $f) or die $!, " ", $f;
	my $hdr = <$fh> || warn $!;
	chomp $hdr;
	my $kcnt = my @k = split /\|/, $hdr;
	my $line = 1;
	while (<$fh>) {
		$line++;
		chomp;
		my $ecnt = my @e = split /\|/;
		if ($kcnt != $ecnt) {
			warn "$f: Invalid number of data elements, expected ",
				"$kcnt, got $ecnt\n";
			last;
		}
		my $eh = { _file => $f };
		map { $eh->{$_} = shift @e } @k;

		my $key = $eh->{$keyname};
		unless (defined $key) {
			die "$f: Key '$keyname' not found in header\n";
			last;
		}
		if (defined $vh->{$key}) {
			warn "$f: '$keyname=$key' already defined in '",
						$vh->{$key}->{_file}, "'\n";
			last;
		}
		$vh->{$key} = $eh;
	}
	close $fh;
	die "$f: No data found in file\n" unless $line > 1;
}

################################################################################
#
# Calculate line impedance
#
sub Impedance
{
   my $val = $_[0];

   my $sp = 0.0;
   my ($v0, $i0, $v1, $i1, %m);
   foreach my $k (sort {$a <=> $b} keys %$val) {
	$v0 = $v1;
	$i0 = $i1;
	($v1, $i1) = ($val->{$k}->{VAC}, $val->{$k}->{IAC});
	next unless defined $v0;

	my ($dv, $di) = ($v1-$v0, $i1-$i0);
	my $p  = abs($dv*$di);
	next unless $p;

	if($di < 0) {
		$di = -$di;
		$dv = -$dv;
	}
	my $a =  $dv/$di;
	$sp += $p;
	$m{$a} += $p;
#	print "$a,$dv,$di,$p\n" if $arg{v};
   }

   my ($ss, $i) = (0.0, 0);
   my @p_s = ( 0.15865, 0.50000, 0.84135 );
   my @p_v;
   my ($ko, $so);
EXIT: {
     foreach my $k ( sort {$a <=> $b} keys %m ) {

   	$ss += $m{$k};
	my $s = $ss/$sp;
#   	print "$k,$m{$k},$s\n" if $arg{v};

	while ($s >= $p_s[$i]) {
		push @p_v, ( $s >= $p_s[$i] ? $k :
				$ko+($k-$ko)*($p_s[$i]-$so)/($s-$so) );
		last EXIT unless defined $p_s[++$i];
	}
	$ko = $k;
	$so = $s;
     }
   }
   printf "Impedance %.2e Ohm %.2f%% interval @ [%.1e, %.1e]\n", $p_v[1],
   	($p_s[2]-$p_s[0])*100,
   	$p_v[0]-$p_v[1], $p_v[2]-$p_v[1] if $arg{v};
   return $p_v[1], ($p_v[2]-$p_v[0])/2;
}

################################################################################
#
# Calculate efficiency (  Vac.Iac / Vdc.Idc
#
sub Efficiency
{
   my $val = $_[0];
   foreach my $k (sort {$a <=> $b} keys %$val) {
	my $p = $val->{$k}->{VPV1} * $val->{$k}->{IPV1};
	my $n = 0;
	$n = ($val->{$k}->{VAC} * $val->{$k}->{IAC}) / $p if $p > 30;
	print "$p, $n\n";
   }
}

################################################################################
#
# Generate JSON
#
sub data_js
{
  my $v = $_[0];
  my @k = ( sort {$a <=> $b} keys %$v );
  return unless @k > 3;

  my $interval = $k[2]-$k[1];

  open my $fo, '>'.($_[1] || '-') or die $!;
  print $fo "{\"tInt\":$interval,";
  print $fo "\"tStart\":",	$k[1]-$interval,",";
  print $fo "\"sEnergy\":[",
		join(',', map { $v->{$_}->{ETODAY} } @k),	"],";
  print $fo "\"sPower\":[",
		join(',', map { $v->{$_}->{PAC} } @k),	"],";
  print $fo "\"sVoltage\":[",
		join(',', map { $v->{$_}->{VPV1} } @k),	"],";
  print $fo "\"sTemp\":[", ( defined $v->{$k[1]}->{temp} ?
		join(',', map { $v->{$_}->{temp} } @k):''),	"],";
  print $fo "\"sInverterTemp\":[",
		join(',', map { $v->{$_}->{TEMP} } @k),	"]}";
  close $fo;
}

################################################################################
# MAIN
################################################################################

sub Tools {
	if ($arg{j}) {
		data_js $_[0], $arg{j};
	} elsif ($arg{n}) {
		Efficiency $_[0];
	} else {
		printf "\tImpedance: %f Ohm, sigma %f\n", (Impedance $_[0]);
	}
}

my %val;
foreach my $f ( (scalar @ARGV > 0 ? @ARGV : '-') ) {
	print "$f:\n" if $arg{v} || $arg{s};
	%val = () if $arg{s};
	parse $f, \%val, "time";
	Tools \%val if $arg{s};
}
Tools \%val unless $arg{s};

