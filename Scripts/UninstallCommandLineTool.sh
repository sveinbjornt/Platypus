#!/bin/sh

# UninstallCommandLineTool.sh
# Platypus
#
# Created by Sveinbjorn Thordarson on 6/17/08.
# Copyright (C) . All rights reserved.

echo "Uninstalling command line tool" > /dev/stderr

# Delete resources
if [ -e "/usr/local/share/platypus/" ]
then
    echo "Deleting /usr/local/share/platypus/ directory" > /dev/stderr
    rm -R "/usr/local/share/platypus/"
fi

if [ -e "/usr/local/bin/platypus" ]
then
    echo "Deleting platypus command line tool in /usr/local/bin/platypus" > /dev/stderr
    rm "/usr/local/bin/platypus"
fi

if [ -e "/usr/local/share/man/man1/platypus.1" ]
then
    echo "Deleting platypus man page" > /dev/stderr
    rm "/usr/local/share/man/man1/platypus.1"
fi