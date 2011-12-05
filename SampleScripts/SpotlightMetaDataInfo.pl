#!/usr/bin/perl
# Uses the mdls command to list meta data info on dropped files
use Shell;

foreach(@ARGV)
{
    print "META-DATA INFO FOR '$_':\n";
	system("/usr/bin/mdls '$_'");
	print "------------||------------\n\n";
}