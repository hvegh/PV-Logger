package DeviceCMS2000;
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
# (c) 2013,2014 Henk vergonet
# Source can be found on https://github.com/hvegh/PV-Logger.git

# Class for managing parameters
use PList;
use warnings;
use strict;

my %conf = (
	default_hostaddr => 0x100,
);
my $_debug = 0;
my %_devicelist;

#my %unit = (
#	'V'	=> 'Volt',
#	'A'	=> 'Ampere',
#	'C'	=> 'Centigrade',
#	'kWh'	=> 'Kilo Watt per Hour',
#	'Hz'	=> 'Herz',
#	'W'	=> 'Watt',
#	's'	=> 'Second',
#);

my %parm_status = (
	0x00 => {
		name	=> 'Internal Temperature',
		key	=> 'TEMP',
		unit	=> 'C',
		mult	=> 0.1,
		},
	0x01 =>	{
		name	=> 'Panel 1 Voltage',
		key	=> 'VPV1',
		unit	=> 'V',
		mult	=> 0.1,
		},
	0x02 =>	{
		name	=> 'Panel 2 Voltage',
		key	=> 'VPV2',
		unit	=> 'V',
		mult	=> 0.1,
		},
	0x03 =>	{
		name	=> 'Panel 3 Voltage',
		key	=> 'VPV3',
		unit	=> 'V',
		mult	=> 0.1,
		},
	0x04 =>	{
		name	=> 'Panel 1 DC Current',
		key	=> 'IPV1',
		unit	=> 'A',
		mult	=> 0.1,
		},
	0x05 =>	{
		name	=> 'Panel 2 DC Current',
		key	=> 'IPV2',
		unit	=> 'A',
		mult	=> 0.1,
		},
	0x06 =>	{
		name	=> 'Panel 3 DC Current',
		key	=> 'IPV3',
		unit	=> 'A',
		mult	=> 0.1,
		},
	0x0d =>	{
		name	=> 'Accumulated Energy Today',
		key	=> 'ETODAY',
		unit	=> 'kWh',
		mult	=> 0.01,
		},
	0x41 =>	{
		name	=> 'Grid Current',
		key	=> 'IAC',
		unit	=> 'A',
		mult	=> 0.1,
		},
	0x42 =>	{
		name	=> 'Grid Voltage',
		key	=> 'VAC',
		unit	=> 'V',
		mult	=> 0.1,
		},
	0x43 =>	{
		name	=> 'Grid Frequency',
		key	=> 'FAC',
		unit	=> 'Hz',
		mult	=> 0.01,
		},
	0x44 =>	{
		name	=> 'Output Power',
		key	=> 'PAC',
		unit	=> 'W',
		},
	0x45 =>	{
		name	=> 'Grid Impedance',
		key	=> 'ZAC',
		unit	=> 'Ohm',
		mult	=> 0.001,
		},
	0x47 =>	{
		name	=> 'Accumulated Energy',
		key	=> 'ETOTAL',
		unit	=> 'kWh',
		mult	=> 0.1,
		extend	=> 0x48,
		},
	0x49 =>	{
		name	=> 'Working Hours',
		key	=> 'HTOTAL',
		unit	=> 'H',
		extend	=> 0x4a,
		},
	0x4c =>	{
		name	=> 'Operating Mode',
		key	=> 'MODE',
		},
	0x78 =>	{
		name	=> 'Error message: GV fault value',
		key	=> 'ERR_GV',
		},
	0x79 =>	{
		name	=> 'Error message: GF fault value',
		key	=> 'ERR_GF',
		},
	0x7a =>	{
		name	=> 'Error message: GZ fault value',
		key	=> 'ERR_GZ',
		},
	0x7b =>	{
		name	=> 'Error message: Tmp fault value',
		key	=> 'ERR_TEMP',
		},
	0x7c =>	{
		name	=> 'Error message: PV1 fault value',
		key	=> 'ERR_PV1',
		},
	0x7d =>	{
		name	=> 'Error message: GFC1 fault value',
		key	=> 'ERR_GFC1',
		},
	0x7e =>	{
		name	=> 'Error mode',
		key	=> 'ERR_MODE',
		},
);

my %parm_settings= (
	0x40 =>	{
		name	=> 'PV Start-up voltage',
		key	=> 'VPV-START',
		unit	=> 'V',
		mult	=> 0.1,
		},
	0x41 =>	{
		name	=> 'Time to connect grid',
		key	=> 'T-START',
		unit	=> 's',
		},
	0x44 =>	{
		name	=> 'Minimum operational grid voltage',
		key	=> 'VAC-MIN',
		unit	=> 'V',
		mult	=> 0.1,
		},
	0x45 =>	{
		name	=> 'Maximum operational grid voltage',
		key	=> 'VAC-MAX',
		unit	=> 'V',
		mult	=> 0.1,
		},
	0x46 =>	{
		name	=> 'Minimum operational frequency',
		key	=> 'FAC-MIN',
		unit	=> 'Hz',
		mult	=> 0.01,
		},
	0x47 =>	{
		name	=> 'Maximum operational frequency',
		key	=> 'FAC-MAX',
		unit	=> 'Hz',
		mult	=> 0.01,
		},
	0x48 =>	{
		name	=> 'Maximum operational grid impedance',
		key	=> 'ZAC-MAX',
		unit	=> 'Ohm',
		mult	=> 0.001,
		},
	0x49 =>	{
		name	=> 'Allowable delta ZAC of operation',
		key	=> 'DZAC-MAX',
		unit	=> 'Ohm',
		mult	=> 0.001,
		},
);

my %_opcode = (
	reset		=> {
		txaddr => 0,	# use broadcast
		txcode => 0x04,
	},
	getSerial	=> {
		txaddr => 0,	# use broadcast
		txcode => 0x00,
		rxaddr => 0,	# device uses broadcast
		rxcode => 0x80,
		rxform => 'a*',
		rxparm => [ 'serialnumber' ],		# use int variables
	},
	setDevaddr	=> {
		txaddr => 0,	# use broadcast
		txcode => 0x01,
		txform => 'a*C',
		txparm => [ 'serialnumber', 'devaddr' ],# use int variables
		rxcode => 0x81,
		rxform => 'C',
		rxparm => [ 'status' ],
	},
	getVersion	=> {
		txcode => 0x0103,
		rxcode => 0x0183,
		rxform => 'aa6a7a14a16a10H12a*',
		rxkeys => [ 'protocol', 'capacity', 'firmware', 'model', 
			    'manufacturer', 'serialnumber', 'version_unknown1',
			    'version_unknown2' ],
	},
	getSettingsFormat => {
		txcode => 0x0101,
		rxcode => 0x0181,
	},
	getSettings	=> {
		txcode => 0x0104,
		rxcode => 0x0184,
		getparm   => [ \%parm_settings, 'getSettingsFormat' ],
	},
	getStatusFormat => {
		txcode => 0x0100,
		rxcode => 0x0180,
	},
	getStatus	=> {
		txcode => 0x0102,
		rxcode => 0x0182,
		getparm   => [ \%parm_status, 'getStatusFormat' ],
	},
);

=item new

optional parameters:
	hostaddr (default 0x100 is asumed if not given; 
=cut
sub new {
	my $class = shift;
	my $self = {@_};
	bless ($self, $class);
	my $i;
	for ($i=1; $i<255; $i++) {
		last unless $_devicelist{$i};
	}
	$_devicelist{$i} = $self;
	$self->{devaddr} = $i;
	$self->{hostaddr} = $conf{default_hostaddr} unless $self->{hostaddr};
	$self->{status} = 0;

	# Setup parameter list
	foreach $i (keys %_opcode) {
		my $h = $_opcode{$i};
		next unless $h->{rxkeys};
		$self->{$i} = new PList;
	}
	return $self;
}

# parameters: hostaddr, deviceaddr, opcode, parameter
sub _txpkt
{
	my $self = shift;
	my $pkt = pack('nnnnC/a*', 0xaaaa, @_);
	my $c = $self->{link}->write($pkt.pack('n', unpack('%C*', $pkt)));
	return $c;
}

# parameters: hostaddr, deviceaddr, opcode
# returns:    parameter
sub _rxpkt
{
	my $self = shift;
	my ($c, $buf) = $self->{link}->read(255);

	my $hdr = pack 'nnnn', 0xaaaa, @_;
	my $i = index $buf, $hdr;
	if ($i<0) {
		warn "no header found";
		return undef;
	}
	$buf = substr $buf, $i;
	my ($cnt, $dat, $chk) = unpack('x8CXC/a*n', $buf); 

	if ($c - $i < 11 + $cnt) {
		warn "short read";
		return undef;
	}
	if ($chk != unpack('%C*', substr($buf, 0, 9 + $cnt))) {
		warn "checksum mismatch";
		return undef;
	}
	return $dat;
}

sub _getparm
{
	my ($self, $op, $pl )  = @_;
	my $ar = $op->{getparm} || return;
	my ($dlst, $cmd) = @$ar; 

	# Query device for parameter format
	my $dat = $self->call($cmd) || return;

	my ($rxform, $rxkeys) = ('', []);
	my $e; 
	foreach my $c (unpack('C*', $dat)) {
		my $h = $dlst->{$c};
		unless ($h) {
			if (defined $e) {
				warn "Extention no found $e\n" if $c != $e;
				$e = undef;
				next;
			}
			$h = {
				name	=> 'Unknown parameter',
				key	=> sprintf('unknown%02x', $c),
			};
			$dlst->{$c} = $h;
		}
		$e = $h->{extend};
		$rxform .= ($e ? 'N' : 'n');
		push @$rxkeys, $h->{key};
		$pl->add($h);
	}
	$op->{rxform} = $rxform;
	$op->{rxkeys} = $rxkeys;
	return $rxform;
}

sub call
{
	my ($self, $cmd) = @_;
	my $op = $_opcode{$cmd};

	unless ($op) { warn "no such command:$cmd"; return };

	print "$cmd\n" if $_debug;

	# fetch parameters
	my ($ha, $da) = map { $self->{$_} } ( 'hostaddr', 'devaddr' );
	my ($ta, $to, $tf, $tp, $ra, $ro, $rf, $rp) = map { $op->{$_} }
		( 'txaddr', 'txcode', 'txform', 'txparm',
		  'rxaddr', 'rxcode', 'rxform', 'rxparm' );

	# set parameters
	my $dat = '';
	$dat = pack($tf, (map { $self->{$_} } @$tp)) if $tf;

	# set device source and destination address
	$ta = $da unless defined $ta;
	$ra = $da unless defined $ra;

## retry mechanism...
	$self->_txpkt($ha, $ta, $to, $dat);
	return 0 unless $ro;	# nothing to return
	my $t = time;
	$dat = $self->_rxpkt($ra, $ha, $ro);
	return undef unless $dat;
## retry mechanism...

	my $pl = $self->{$cmd};
	unless ($rf) {
		return $dat unless $op->{getparm};
		# No format defined so we must query the device
		# for these types we generate a parameter list
		$pl = new PList;
		$pl->add({ key => 'time', unit => 's' }, $t);

		$rf = $self->_getparm($op, $pl) || return undef;
		$self->{$cmd} = $pl;
	}

	my @val = unpack($rf, $dat);
	print join('|', @val), "\n" if $_debug;

	map $self->{$_} = shift @val, @$rp if $rp;
	return $dat unless $pl;

	# Update values in PList;
	$pl->set('time', $t);
	@val = unpack($rf, $dat);
	my $keys = $op->{rxkeys};
	foreach my $k (@$keys) {
		my $m = $pl->get($k, 'mult');
		if ($m) {
			$pl->set($k, $m * shift(@val));
		} else {
			$pl->set($k, shift @val);
		}
	}
	print join('|', $pl->select), "\n" if $_debug;

	return $pl;
}

sub Status
{
	my $self = shift;
	my $ret;

	if ($self->{status} == 0) {
		$self->call('reset');
		$ret = $self->call('getSerial');
		$self->{status} = 1 if $ret;
	}
	if ($self->{status} == 1) {
		$ret = $self->call('setDevaddr');
		$self->{status} = 2 if $ret;
	}
	if ($self->{status} == 2) {
		$ret = $self->call('getStatus');
		return $ret if $ret;
	}
	$self->{status} = 0;
	return undef;
}

sub DESTROY {
	my $self = shift;
	my $id = $self->{devaddr};
	$_devicelist{$id} = undef;
}
1;

