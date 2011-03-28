#!/usr/bin/perl

# This script will convert any image file into a PDF file stored
# in /tmp/ and open it with Preview
#
# Open with Platypus, set Droppable and Remain running options,
# with output mode Progress Bar and then create app
#
# The command line tool used to do this may not exist on
# all versions of Mac OS X

use strict;
use File::Basename;

my $tmp_dir = "/tmp/";

foreach(@ARGV)
{
    my($fn, $directory) = fileparse($ARGV[0]);
    my $dest = $tmp_dir . $fn . '.pdf';
    system("/usr/libexec/fax/imagestopdf '$_' '$dest' > /dev/null");
    system("/usr/bin/open -a Preview '$dest' > /dev/null");
}