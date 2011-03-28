#!/usr/bin/perl
#
# A script which bids you hello verbally and opens the Platypus website
#
# Open this script with Platypus and select Output Type: Text Window, check
# the Remain running option, then press Create
#

use Shell;

@lines = finger("-lg", "$ENV{'USER'}");

($ble, $longname) = split(/Name\:/, $lines[0]);
$longname =~ s/\n//g;
$hellostr = "Hello, $longname.\n\nThis app was created with Platypus.";
print $hellostr;
say($hellostr);
system('open http://sveinbjorn.org/platypus');