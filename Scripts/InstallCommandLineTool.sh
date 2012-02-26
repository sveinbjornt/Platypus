#!/bin/sh

# InstallCommandLineTool.sh
# Platypus
#
# Created by Sveinbjorn Thordarson on 6/17/08.
# Copyright (C) . All rights reserved.

echo "Installing command line tool" > /dev/stderr

# Create directories if they don't exist
echo "Creating directory structures" > /dev/stderr
mkdir -p "/usr/local/bin"
mkdir -p "/usr/local/share/platypus"
mkdir -p "/usr/local/share/man/man1"

# Change to Resources directory of Platypus application, which is first argument
echo "Changing to directory $1" > /dev/stderr
cd "$1"

# Copy resources over
echo "Copying resources" > /dev/stderr
cp "platypus_clt" "/usr/local/bin/platypus"
cp "ScriptExec" "/usr/local/share/platypus/ScriptExec"
cp "platypus.1" "/usr/local/share/man/man1/platypus.1"
cp "PlatypusDefault.icns" "/usr/local/share/platypus/PlatypusDefault.icns"
cp -r "MainMenu.nib" "/usr/local/share/platypus/"

echo "Setting permissions" > /dev/stderr
chmod -R 755 "/usr/local/share/platypus/"

# Create text file with version
echo "Creating CLT versioning file" > /dev/stderr
echo "4.7" > "/usr/local/share/platypus/Version"

exit 0