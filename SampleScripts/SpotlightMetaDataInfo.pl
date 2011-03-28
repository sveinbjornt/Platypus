#!/usr/bin/perl
#
# Uses the mdls command to list meta data info on dropped files
#
# Load this script into Platypus, select "Droppable" and 
# "Remain running after completion" and set Ouput to Text Window
#  Then press create.  You'll have an app that lists Spotlight
# info on the files dropped on to it
#
#

use Shell;

foreach(@ARGV)
{
    print "META-DATA INFO FOR '$_':\n";
	system("/usr/bin/mdls '$_'");
	print "------------||------------\n\n";
}