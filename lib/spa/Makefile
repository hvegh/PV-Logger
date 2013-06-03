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

CORE_PERL := $(shell perl -V | grep -e '/usr/lib/perl5/[^/]*/i686-linux'$ )
CORE_PERL := /usr/lib/perl5/5.12.4/i686-linux/CORE

main: _spa.so

spa_wrap.c: spa.i spa.h
	swig -perl5 spa.i

spa.o: spa.c spa_wrap.c
	gcc -c -fpic -O3 -lm spa.c spa_wrap.c -I${CORE_PERL}

_spa.so: spa.o
	gcc -shared spa.o spa_wrap.o -o spa.so

clean:
	rm -f *.o spa.so spa.pm spa.py spa_wrap.c

spa_tester: gcc -o spa_tester -fpic -O3 -lm spa.c spa_tester.c
