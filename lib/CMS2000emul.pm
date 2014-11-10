package CMS2000emul;
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
# (c) 2013, 2014 Henk vergonet
# Source can be found on https://github.com/hvegh/PV-Logger.git

# Class for emulation

use warnings;
use strict;
use v5.10.1;

sub new {
	my $class = shift;
	my $self = {@_};
	bless ($self, $class);
	$self->{rx} = '';
	return $self;
}

sub write
{
  my ($self, $pkt) = @_;
  print '>>>', unpack('H*', $pkt), "\n";

  my $rx = '';
  for(unpack('H*', $pkt)) { 
    if (/^aaaa010000000004000159/) {
      # Reset
      $rx = '';
    } elsif (/^aaaa010000000000000155/) {
      # Get Serial
      $rx = 'aaaa0000010000800a31323334464630313236';
    } elsif (/^aaaa0100000000010b3132333446463031323601/) {
      # Set inverter adres
      $rx = 'aaaa0001010000810106';
    } elsif (/^aaaa01000001010300015a/) {
      # Get version
      $rx = 'aaaa000101000183403120203330303030302e3031202043505320534345334b544c2d4f204541544f4e2050484f454e49585445433132333446463031323600000000000033363030';
    } elsif (/^aaaa010000010101000158/) {
      # Get settings format
      $rx = 'aaaa000101000181394041444546474a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6d6e6f707172737475767778797a7b7c7d7e';
    } elsif (/^aaaa01000001010400015b/) {
      # Get settings
      $rx = 'aaaa0001010001847205dc001e074e0a3c12931397006403e800000000001e00000708006400000064047e2706000027060010001000100010000403e703e703e70001001809c4001400280032005a005a005c006c006e129d138d0000270603e803e803e8fc7c01b400000000fe4c00000000096f08fc00140005';
    } elsif (/^aaaa010000010100000157/) {
      # Get status format
      $rx = 'aaaa000101000180160001040d414243444748494a4c767778797b7c7d7e7f';
    } elsif (/^aaaa010000010102000159/) {
      # Get Status
      $rx = 'aaaa0001010001822c00f10b900006000500090919138400c000000c930000018a0001000000000000000000000000000000000000';
    }
  }
  $rx = pack('H*', $rx);
  # add checksum
  $rx .= pack('n', unpack('%C*', $rx)) if length($rx) > 0;

  $self->{rx} = $rx;
  return length($pkt);
}

sub close
{
}

sub read
{
	my ($self, $len) = @_;
	my $lenrx = length $self->{rx};
	$len = $lenrx if $len > $lenrx;
	my $rx = substr $self->{rx}, 0, $len;
	$self->{rx} = substr $self->{rx}, $len;
	print '<<<', unpack('H*', $rx), "\n";
	return ($len, $rx);
}
1;

