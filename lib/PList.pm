package PList;
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

# Class for some basic list handling
# list contains a set of ( static (key + attribuites ) and dynamic value )
#
# Internal structure: [ \%Index, [ [ \%attr, value ] ... [   ] ] ]; 
use warnings;
use strict;

sub new {
	my $class = shift;
	my $self = {
		ix => {},
		ar => []
		};
	bless ($self, $class);
	return $self;
}

sub add
{
  my ($self, $desc, $val) = @_;
  my $key = $desc->{key};
  my $kv = [ $desc, $val ];
  my $ar = $self->{ar};
  push @$ar, $kv;
  $self->{ix}->{$key} = $kv;
}

sub set
{
  my ($self, $key, $val, $att) = @_;
  my $kv = $self->{ix}->{$key};
  unless ($kv) {
  	$self->add({ key => $key }, $val);
	return;
  }

  if (defined $att) {
  	$kv->[0]->{$att} = $val;
  } else {
  	$kv->[1] = $val;
  }
}

sub get
{
  my ($self, $key, $att) = @_;
  my $kv = $self->{ix}->{$key};
  return $kv->[0]->{$att} if defined $att;
  return $kv->[1];
}

sub select
{
  my ($self, $keys, $att) = @_;
#  print "keys:",join('|', @$keys), "\n";
  my $kvs;
  if ($keys) {
	$kvs = [ (map { $self->{ix}->{$_} } @$keys) ];
  } else {
  	$kvs = $self->{ar};
  }
#  print "kvs:", join('|', @$kvs), "\n";
  my @ret;
  if ($att) {
	@ret = map { ${$_->[0]}{$att} } @$kvs;
  } else {
	@ret = map { $_->[1] } @$kvs;
  }
#  print "ret:", join('|', @ret), "\n";
  return @ret;
}
1;

