#!/bin/sh
#
# Generate Platypus-VERSION.src.zip on Desktop
#

# Get version
VERSION=`perl -e 'use Shell;@lines=cat("CommonDefs.h");foreach(@lines){if($_=~m/Platypus-(\d\.\d)/){print $1;}}'`

# Folder name
FOLDER=Platypus-$VERSION-Source

# Create the folder
mkdir /tmp/$FOLDER

# Copy files over
cp -r * /tmp/$FOLDER/

# Remove any build directories
/usr/bin/find /tmp/$FOLDER -type d -name build -exec rm -rf '{}' +

# Remove any svn files
/usr/bin/find /tmp/$FOLDER -type d -name .svn -exec rm -rf '{}' +

# Remove DS_Store files
/usr/bin/find /tmp/$FOLDER -type f -name .DS_Store -exec rm '{}' +

cd /tmp/

/usr/bin/zip -r platypus$VERSION.src.zip $FOLDER

mv /tmp/platypus$VERSION.src.zip ~/Desktop/

rm -R /tmp/$FOLDER
