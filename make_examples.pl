#!/usr/bin/perl
#
# Creates apps from all the Platypus examples
#
# Usage: ./make_examples
#        ./make_examples SOURCE_DIR OUTPUT_DIR
#

use strict;

my $platypus = "/usr/local/bin/platypus";
my $dirpath = "Examples";
my $outdir = "ExampleApps";

if (! -e $platypus) {
    die("Command line tool $platypus is not installed");
}

if ($ARGV[0]) {
    $dirpath = $ARGV[0];
}

if ($ARGV[1]) {
    $outdir = $ARGV[1];
}

opendir(DIR, $dirpath) or die("Could not open directory $dirpath. $!");
my @files = readdir(DIR);
closedir(DIR);

# Get list of profiles in directory
my @example_files;
foreach my $file(@files) {
    if ($file =~ m/\.platypus$/) {
        push(@example_files, $file);
    }
}

if (!scalar(@example_files)) {
    die("No profiles found in directory $dirpath");
}

# Create output dir
if (! -e $outdir) {
    if (!mkdir($outdir)) {
        die("Could not create output directory $dirpath: $!");
    }
}

# Create app from each example in directory
foreach my $file(@example_files) {
    my $name = $file;
    $name =~ s/\.platypus$//;
    print "------------------------------\n";
    print "Creating $name.app\n";
    print "------------------------------\n";
    `$platypus --load-profile "$dirpath/$file" -y "$outdir/$name.app"`    
}
