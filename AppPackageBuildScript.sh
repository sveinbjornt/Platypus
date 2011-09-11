#!/bin/sh
#
# Generate Platypus-VERSION.zip on Desktop

# Get version
VERSION=`perl -e 'use Shell;@lines=cat("CommonDefs.h");foreach(@lines){if($_=~m/Platypus-(\d\.\d)/){print $1;}}'`

# Folder name
FOLDER=Platypus-$VERSION

# Create the folder
mkdir -p /tmp/$FOLDER
cp -r build/Platypus/Build/Products/Deployment/Platypus.app /tmp/$FOLDER/
cp 'Documentation/Readme.html' /tmp/$FOLDER/
cp -r 'SampleScripts' /tmp/$FOLDER/

# Remove any svn files
/usr/bin/find /tmp/$FOLDER -type d -name .svn -exec rm -rf '{}' +

# Trim binaries, compress tiffs, remove .DS_Store, resource forks, etc.
/bin/sh trim.sh -d -s -t -r -p -- /tmp/$FOLDER/

# Compile Platypus.nib file
#/Developer/usr/bin/ibtool --strip /tmp/$FOLDER/Platypus.app/Contents/Resources/Platypus.nib /tmp/$FOLDER/Platypus.app/Contents/Resources/Platypus.nib
#/Developer/usr/bin/ibtool --strip /tmp/$FOLDER/Platypus.app/Contents/Resources/Preferences.nib /tmp/$FOLDER/Platypus.app/Contents/Resources/Preferences.nib


cd /tmp/

/usr/bin/zip -r platypus$VERSION.zip $FOLDER

mv /tmp/platypus$VERSION.zip ~/Desktop/

rm -R /tmp/$FOLDER
