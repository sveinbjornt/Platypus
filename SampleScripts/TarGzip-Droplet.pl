#!/usr/bin/perl

use strict;
use File::Basename;

my $cmd = "/usr/bin/tar cvfz ";

# Get enclosing folder of first file
my($fn, $directory) = fileparse($ARGV[0]);

# Change to that directory
chdir($directory);

# Archive is created there
my $dest_path = "Archive.tgz";

my $files;
foreach(@ARGV)
{
    my($filename, $directory) = fileparse($_);
    $files .= "'$filename' ";
}

print $cmd . "\n";
system("$cmd $dest_path $files");