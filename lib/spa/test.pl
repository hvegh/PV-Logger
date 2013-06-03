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
# (c) 2013 Henk vergonet
# Source can be found on https://github.com/hvegh/PV-Logger.git

use strict;
use POSIX qw(strftime);
use spa;

my $x = new spa::spa_data();


( $x->{second},	$x->{minute},	$x->{hour},
  $x->{day},	$x->{month},	$x->{year},
  $x->{timezone} ) = split / /, strftime('%S %M %H %d %m %Y %z', localtime);
  $x->{timezone} /= 100;
$x->{delta_t}		= 67;
$x->{longitude}		= 4;
$x->{latitude}		= 51;
$x->{elevation}		= 0;
$x->{pressure}		= 1020;
$x->{temperature}	= 1;
$x->{slope}		= 40;
$x->{azm_rotation}	= -10;
$x->{atmos_refract}	= 0.5667;
$x->{function}		= 3;
sub spa_print {
printf "Julian Day:    %.6f\n", $x->{jd};
printf "L:             %.6e degrees\n", $x->{l};
printf "B:             %.6e degrees\n", $x->{b};
printf "R:             %.6f AU\n", $x->{r};
printf "H:             %.6f degrees\n", $x->{h};
printf "Delta Psi:     %.6e degrees\n", $x->{del_psi};
printf "Delta Epsilon: %.6e degrees\n", $x->{del_epsilon};
printf "Epsilon:       %.6f degrees\n", $x->{epsilon};
printf "Zenith:        %.6f degrees\n", $x->{zenith};
printf "Azimuth:       %.6f degrees\n", $x->{azimuth};
printf "Azimuth180:    %.6f degrees\n", $x->{azimuth180};
printf "Incidence:     %.6f degrees\n", $x->{incidence};
my $min = 60.0*($x->{sunrise} - int $x->{sunrise});
my $sec = 60.0*($min - int $min);
printf "Sunrise:       %02d:%02d:%02d Local Time\n", int $x->{sunrise},
						     int $min, int $sec;
$min = 60.0*($x->{sunset} - int $x->{sunset});
$sec = 60.0*($min - int $min);
printf "Sunset:        %02d:%02d:%02d Local Time\n", int $x->{sunset},
						     int $min, int $sec;
$min = 60.0*($x->{suntransit} - int $x->{suntransit});
$sec = 60.0*($min - int $min);
printf "Suntransit:    %02d:%02d:%02d Local Time\n", int $x->{suntransit},
						     int $min, int $sec;
}



my $result = spa::spa_calculate($x);
die "SPA Error code: ", $result, "\n" if $result;
spa_print;

my $min = 60.0*($x->{suntransit} - int $x->{suntransit});
my $sec = 60.0*($min - int $min);
$x->{minute}	= int $min;
$x->{second}	= int $sec;
$x->{hour}	= int $x->{suntransit};

my $result = spa::spa_calculate($x);
die "SPA Error code: ", $result, "\n" if $result;
spa_print;
