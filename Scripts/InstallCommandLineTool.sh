#!/bin/sh

# InstallCommandLineTool.sh
# Platypus
#
# Created by Sveinbjorn Thordarson on 6/17/08.
# Copyright (C) 2003-2010. All rights reserved.

# Create directories if they don't exist
mkdir -p "/usr/local/bin"
mkdir -p "/usr/local/share/platypus"
mkdir -p "/usr/local/share/man/man1"

# Change to Resources directory of Platypus application, which is first argument
cd "$1"

# Copy resources over
cp "platypus" "/usr/local/bin/platypus"
cp "ScriptExec" "/usr/local/share/platypus/ScriptExec"
cp "platypus.1" "/usr/local/share/man/man1/platypus.1"
cp "PlatypusDefault.icns" "/usr/local/share/platypus/PlatypusDefault.icns"
cp -r "MainMenu.nib" "/usr/local/share/platypus/"

chmod -R 755 "/usr/local/share/platypus/"

# Create text file with version
echo -n "$2" > "/usr/local/share/platypus/Version"

# Let's be good citizens and strip away other architectures from the installed CLT binary
ARCH=`arch`
/usr/bin/lipo -thin "$ARCH" -output "/usr/local/bin/platypus" "/usr/local/bin/platypus"

exit 0