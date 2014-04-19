PV-Logger
---------
A set of perl scripts for communicating with EATON PHOENIXTEC type solar
Tested and running with the Chint 3KW CPS SCE3KTL-O solar inverter.

Before you start please note:

NO WARRANTY

PV-LOGGER IS DISTRIBUTED IN THE HOPE THAT IT WILL BE USEFUL, BUT WITHOUT ANY WARRANTY. IT IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

also

This stuf is maybe here and there a little rough around the edges. I do not
intend to give allot of user support. So you're basically on your own with this.

Interface:
----------
For an isolated rs232 interface used with this logger see:
https://github.com/hvegh/Optical-Isolated-RS422-RS485-interace.git

Dependencies:
-------------

General utillities:
  - Perl v5
  - GNU Compiler
  - GNU Make
  - swig

Perl modules:
  - Time::HiRes
	provide by Time-HiRes
  - LWP::UserAgent
  - HTTP::Request
	provided by libwww-perl
  - Device-SerialPort
	provided Device-SerialPort

Installation:
-------------

1. Compile the Solar Position Algorithm
   look at the README in lib/spa

2. Set the configuration parameters in sunmon.pl

3. run sunmon.pl

Tools & Documentation
---------------------

tools/analyse.pl:

Calculates line impedance using PV-Logger data files, use the -h option for a description. The tools directory also contains an example data file.


(c) 2013, 2014 Henk Vergonet
