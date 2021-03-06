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

use POSIX qw(strftime mktime);
use Time::HiRes qw(time sleep);
use LWP::UserAgent;
use HTTP::Request::Common;
use Device::SerialPort qw (:STAT);

use lib qw(lib lib/spa);

use spa;
use DeviceCMS2000;
use CMS2000emul;
use strict;

my $_debug = 0;
my %conf = (
	emulator => 0,

	port => '/dev/ttyS1',
	baud => 9600,
	parity => 'none',

	# inverter settings
	#serialnumber	=> '1234FF0126',# Will be queried from device 
	interval	=> 60,		# query interval [s]
	logpath		=> '/tmp',

	# panel location and orientation, in order to derermine sunset and sunrise.
	longitude	=> 4.0,
	latitude	=> 51.0,
	elevation	=> 0,
	slope		=> 40,
	azm_rotation	=> -15,	# SSE

	# Inverter Active Cooling (optional)
#	fan_temp_low    => 35.0,	# Fan switch off temperature
#	fan_temp_high   => 40.0,	# Fan switch on temperature
#	fan_cmd_off     => 'irsend SEND_ONCE klik M11OFF',
#	fan_cmd_on      => 'irsend SEND_ONCE klik M11ON',

	# PVout settings (optional)
#	pvo_url		=> 'http://pvoutput.org/service/r2/addstatus.jsp',
#	pvo_apikey	=> '0000000000000011111111111111111112222222',
#	pvo_sid		=> 43210,
#	pvo_interval	=> 300,		# update interval [s]

	# meteo data (optional)
#	meteo_url	=> 'http://www.weerindelft.nl/clientraw.txt',

	# WWW server output (optional)
	#
	# Uncomment this if you like to generate data files that can be used
	# with tools/index.html in order to generate charts. Place both
	# data.js and index.html in the same directory. Of course you will need
	# to have some sort of http(s) server running.
#	data_js		=> '/tmp/data.json',
);

$| = 1;	# don't let Perl buffer I/O

################################################################################
#
# Timer functions
#
my @t000 = (0,0,0,(localtime)[3 .. 8]);
my $ts000 = mktime @t000;

sub time_next
{
   my $i = $_[0] || 1;
   my $t = $_[1] || Time::HiRes::time;
   return $ts000 + int (($t - $ts000)/$i + 1.5) * $i;
}

sub sleep_until
{
   my $t = $_[0] - Time::HiRes::time;
   return if $t<0;
   Time::HiRes::sleep $t;
}

################################################################################
#
# Solar Position Algorithm
#
sub fh2hms
{ my $h = $_[0];
  my $m = 60.0*($h - int $h);
  my $s = 60.0*($m - int $m);
  return (int $s, int $m, int $h);
}

my $spa = new spa::spa_data();
( $spa->{second}, $spa->{minute},	$spa->{hour},
  $spa->{day},	  $spa->{month},	$spa->{year}, $spa->{timezone} ) =
 		split / /, strftime('%S %M %H %d %m %Y %z', @t000);
  $spa->{timezone} /= 100;
( $spa->{delta_t}, $spa->{pressure}, $spa->{temperature},
  $spa->{atmos_refract}, $spa->{function} ) = (67, 1013, 10.1, 0.5667, 2);
  map { $spa->{$_} = $conf{$_} }
  		qw(longitude latitude elevation slope azm_rotation);

  my $rs = spa::spa_calculate($spa);
  die "SPA Error code: $rs" if $rs;

  my $sunrise = mktime fh2hms($spa->{sunrise}), @t000[3 .. 8];
  my $sunset  = mktime fh2hms($spa->{sunset}), @t000[3 .. 8];
  $spa->{function} = 1;

################################################################################
#
# Interface to meteo data
#
sub meteo
{
	return unless $conf{meteo_url};

	my $ua = new LWP::UserAgent(timeout => 10);
	my $rs = $ua->get($conf{meteo_url});
	if ($rs->is_error) {
		warn 'meteo:', $rs->content;
		return;
	}
	my ($tmp, $pre) = ( split(/ /, $rs->content) )[6,4];
	unless (defined $tmp && defined $pre) {
		warn 'meteo: undefined response';
		return;
	}
	$spa->{pressure}	= $tmp;
	$spa->{temperature}	= $pre;
}

################################################################################
#
# Fan control
#
my $fan_state = 0;
sub setFan
{
	return unless	defined($conf{fan_temp_low})	&&
			defined($conf{fan_temp_high})	&&
			defined($conf{fan_cmd_off})	&&
			defined($conf{fan_cmd_on});

	my $temp = $_[0]->get('TEMP');
	if ($temp >= $conf{fan_temp_high}) {
		$fan_state = 1;
	} elsif($temp <= $conf{fan_temp_low}) {
		$fan_state = 0;
	}
	system( $fan_state ? $conf{fan_cmd_on} : $conf{fan_cmd_off} );
}

################################################################################
#
# Interface to pvoutput.org
#
my $pvo_ts = time_next($conf{pvo_interval}) - $conf{interval}/2;
my $ua = new LWP::UserAgent(timeout => 10);
$ua->default_header(
	'X-Pvoutput-Apikey'	=> $conf{pvo_apikey},
	'X-Pvoutput-SystemId'	=> $conf{pvo_sid},
);

sub pvoutput
{
	return unless $conf{pvo_url};

	my ($stat, $ts) = (shift, time);
	return 0 if $ts <$pvo_ts;
	print "pvoutput update\n" if $_debug; 

	meteo;
# Solar incidence
#	( $spa->{second}, $spa->{minute}, $spa->{hour} ) =
#			( localtime($stat->get('time')) )[0 .. 2];
#	spa::spa_calculate($spa);
#	my $p = int(3200*cos($spa->{incidence} * 3.14159265358979/180));
#	$p = 0 if $p < 0;

	my ($d, $t) = split / /,
		strftime('%Y%m%d %H:%M', localtime($stat->get('time')));
	my $rs = $ua->post($conf{pvo_url},	{
		d  => $d,
		t  => $t,
		v1 => $stat->get('ETODAY') * 1000, 
		v2 => $stat->get('PAC'),
		v4 => $stat->get('TEMP'),
		v5 => $spa->{temperature},
		v6 => $stat->get('VPV1')	});
	$pvo_ts = time_next($conf{pvo_interval}, $ts) - $conf{interval}/2;
	return $rs->is_error && warn 'pvoutput:', $rs->content;
}

################################################################################
#
# Interface to javascript in tools/index.html
#
my @_js = ();
sub data_js
{
  return unless $conf{data_js};
  my $stat = shift;
  push @_js, {
  		time	=> $stat->get('time'),
  		ETODAY	=> $stat->get('ETODAY'),
  		PAC	=> $stat->get('PAC'),
		VPV1	=> $stat->get('VPV1'),
		TEMP	=> $stat->get('TEMP'),
		temp	=> $spa->{temperature},
  };
  return unless @_js > 3;
  open my $fo, '>', $conf{data_js}.'~' or die $!;
  print $fo "{\"tInt\":$conf{interval},";
  print $fo "\"tStart\":",	$_js[1]->{time}-$conf{interval},",";
  print $fo "\"sEnergy\":[",
		join(',', map { $_->{ETODAY} } @_js),	"],";
  print $fo "\"sPower\":[",
		join(',', map { $_->{PAC} } @_js),	"],";
  print $fo "\"sVoltage\":[",
		join(',', map { $_->{VPV1} } @_js),	"],";
  print $fo "\"sTemp\":[", ( defined $_js[1]->{temp} ?
		join(',', map { $_->{temp} } @_js):''),	"],";
  print $fo "\"sInverterTemp\":[",
		join(',', map { $_->{TEMP} } @_js),	"]}";
  close $fo;
  rename $conf{data_js}.'~', $conf{data_js};
}

################################################################################
#
# Serial Interface Setup
#
my $link;
if ($conf{emulator}) {
  $link = new CMS2000emul;
  $sunrise = time + 5;
  $sunset = $sunrise + 3000;
} else {
  $link = new Device::SerialPort($conf{port}) || die "new: $!\n";
  $link->error_msg(1);		# use built-in hardware error messages
  $link->user_msg(1);		# use built-in function messages
  $link->can_ioctl()		|| die "Has no ioctl\n";
  $link->baudrate($conf{baud})	|| die 'fail setting baudrate, try -b option';
  $link->parity($conf{parity})	|| die 'fail setting parity';
  $link->databits(8)		|| die 'fail setting databits';
  $link->stopbits(1)		|| die 'fail setting stopbits';
  $link->handshake('none')	|| die 'fail setting handshake';
  $link->datatype('raw')	|| die 'fail setting datatype';
  $link->write_settings		|| die 'could not write settings';
  $link->read_char_time(0);	# don't wait for each character
  $link->read_const_time(480);	# 512*9/9600 second per unfulfilled "read" call
  $link->dtr_active(0);		# set power to +++
  $link->rts_active(1);		# set power to ---
}

################################################################################
# Main
################################################################################

print strftime("Sunrise: %a, %d %b %Y %T %z", localtime($sunrise)), "\n",
      strftime("Sunset:  %a, %d %b %Y %T %z", localtime($sunset)), "\n" if $_debug;

my $i = new DeviceCMS2000( link => $link, serialnumber => $conf{serialnumber} );

sleep_until $sunrise;

my ($ret, $fh, $t);
while ( ($t =  time_next($conf{interval}) - 2) < $sunset) {
	sleep_until $t;

	$ret = $i->Status || next;
	data_js $ret;
	pvoutput $ret;
	setFan $ret;

	# Handle logging
	unless ($fh) {
		my $f  = "$conf{logpath}/inverter_";
		$f .= $i->{serialnumber};
		$f .= strftime('_%Y%m%d.csv', @t000);

		print "log: $f\n" if $_debug;
		open $fh, '>>', $f or die $!;
		select((select($fh), $|=1)[0]);
		print $fh join('|', $ret->select(undef, 'key')), "\n"
						if -z $f;
	}
	print $fh join('|', $ret->select), "\n";
	print $ret->get('ETODAY') , "kWh ", $ret->get('PAC'), "W\n" if $_debug;
}
close $fh if $fh;
$link->close;

