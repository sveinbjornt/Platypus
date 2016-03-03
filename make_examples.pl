#!/usr/bin/perl -w
#
# Creates apps from all the Platypus examples
#
# Usage: ./make_examples
#        ./make_examples [src_dir] [out_dir] [platypus_bin_path]
#

use strict;

my $dirpath = $ARGV[0] ? $ARGV[0] : "Examples";
my $outdir = $ARGV[1] ? $ARGV[1] : "ExampleApps";
my $platypus = $ARGV[2] ? $ARGV[2] : "/usr/local/bin/platypus";

if (! -e $platypus) {
    die("error: Platypus command line tool not found at path $platypus");
}

opendir(DIR, $dirpath) or die("error: Could not open directory $dirpath. $!");
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
    die("error: No profiles found in directory $dirpath");
}

# Create output dir
if (! -e $outdir) {
    if (!mkdir($outdir)) {
        die("error: Could not create output directory $outdir: $!");
    }
}

# Create app from each example in directory
foreach my $file(@example_files) {
    my $name = $file;
    $name =~ s/\.platypus$//;
    print "------------------------------\n";
    print "Creating $name.app\n";
    print "------------------------------\n";
    `$platypus --load-profile "$dirpath/$file" --overwrite "$outdir/$name.app"`    
}
